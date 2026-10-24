// Menu overlay: 32x28 characters in an 8x8 font (256x224 pixels), drawn at 3x in a fixed
// 768x672 window at (256, 24) of the 1280x720 frame. Written for retro-fpga; replaces
// textdisp.v from NESTang/SNESTang and keeps its register interface.
//
// The window has its own counters, independent of how the game picture is scaled.
// A character cell is 8 pixels = 24 output columns. During each cell the next cell's
// character and font byte are fetched (one memory port, 2 reads per 24 columns), and the
// font byte is switched in at the cell boundary.
//
// Banner (command 3): text row y is drawn slanted to the right (italic), in red on a white
// box. The box spans cells x0..x1 plus a margin and is not slanted.

module osd (
    // Core clock domain: register writes from iosys (0x0200_0000)
    //   [25:24] command: 0 = write a character, 1/2 = menu on/off (handled in iosys),
    //                    3 = banner
    //   command 0: [20:16] x, [12:8] y, [6:0] character
    //   command 3: [20:16] x0, [12:8] y, [7] on, [4:0] x1
    input             clk,
    input             osd_we,
    input      [31:0] osd_wdata,

    // HDMI clock domain
    input             hclk,
    input      [10:0] hpos,             // output column being produced
    input      [9:0]  cy,               // output line
    input             line_evt,         // one cycle in horizontal blanking: set up the next line
    output reg        px_on,            // menu text pixel at the previous cycle's hpos
    output reg [23:0] px_color
);

localparam [10:0] X0 = 11'd256;         // window left edge
localparam [9:0]  Y0 = 10'd24;          // window top edge

localparam [23:0] COLOR_TEXT    = 24'hF8F880;   // yellow
localparam [23:0] COLOR_CURSOR  = 24'hF8C080;   // orange: the menu cursor '>'
localparam [23:0] COLOR_VERSION = 24'h505050;   // charcoal: row 26, the version line
localparam [4:0]  VERSION_ROW   = 5'd26;
localparam [23:0] COLOR_BANNER  = 24'hE60012;   // red: banner text
localparam [23:0] COLOR_BOX     = 24'hFFFFFF;   // white: behind the banner

wire [1:0] cmd       = osd_wdata[25:24];
wire [4:0] text_x    = osd_wdata[20:16];
wire [4:0] text_y    = osd_wdata[12:8];
wire [6:0] text_char = osd_wdata[6:0];

// Banner settings {on, row, x0, x1}, written in the core clock domain and taken into the
// HDMI domain through two registers. They change only while the menu is redrawn.
reg  [15:0] ban_c = 0;
always @(posedge clk)
    if (osd_we && cmd == 2'd3)
        ban_c <= {osd_wdata[7], text_y, text_x, osd_wdata[4:0]};

reg  [15:0] ban_s1 = 0, ban_s2 = 0;
always @(posedge hclk) {ban_s2, ban_s1} <= {ban_s1, ban_c};
wire       ban_on  = ban_s2[15];
wire [4:0] ban_row = ban_s2[14:10];
wire [4:0] ban_x0  = ban_s2[9:5];
wire [4:0] ban_x1  = ban_s2[4:0];

// Box edges in output columns: 12 columns of margin, plus 7 on the right for the slant
reg [10:0] box_x0, box_x1;
always @(posedge hclk) begin
    box_x0 <= X0 + {ban_x0, 4'd0} + {ban_x0, 3'd0} - 11'd12;
    box_x1 <= X0 + {ban_x1, 4'd0} + {ban_x1, 3'd0} + 11'd24 + 11'd19;
end

// Character buffer and font in one 2 KB block RAM:
// $000-$37F: characters (32*28), $380-$3FF: unused, $400-$7FF: font (8 bytes per character,
// bit 0 is the leftmost pixel)
reg  [10:0] mem_addr_b;
wire [7:0]  mem_do_b;
gowin_dpb_menu menu_mem (
    .clka(clk), .reseta(1'b0), .ocea(), .cea(1'b1),
    .ada({1'b0, text_y, text_x}), .wrea(osd_we && cmd == 2'd0),
    .dina({1'b0, text_char}), .douta(),

    .clkb(hclk), .resetb(1'b0), .oceb(), .ceb(1'b1),
    .adb(mem_addr_b), .wreb(1'b0),
    .dinb(), .doutb(mem_do_b)
);

// Vertical: menu line my (0..223), each shown on 3 output lines
wire [9:0] next_line = cy == 10'd749 ? 10'd0 : cy + 10'd1;
reg        v_on = 0;
reg [7:0]  my = 0;
reg [1:0]  my_ph = 0;
always @(posedge hclk) begin
    if (line_evt) begin
        if (next_line == Y0) begin
            v_on <= 1'b1;
            my <= 0;
            my_ph <= 0;
        end else if (v_on) begin
            if (my_ph == 2'd2) begin
                my_ph <= 0;
                my <= my + 8'd1;
                if (my == 8'd223) v_on <= 1'b0;
            end else
                my_ph <= my_ph + 2'd1;
        end
    end
end

// Banner row, and the box: the row plus 2 lines of margin above and below. Registered:
// my changes only in horizontal blanking. Each banner line starts one column further
// right than the line below it.
wire [8:0] ban_y = {1'b0, ban_row, 3'd0};
reg        ban_line = 0, box_v = 0;
reg [2:0]  shift = 0;
always @(posedge hclk) begin
    ban_line <= ban_on && v_on && my[7:3] == ban_row;
    box_v    <= ban_on && v_on && my + 9'd2 >= ban_y && my + 9'd2 < ban_y + 9'd12;
    shift    <= ~my[2:0];
end

// Horizontal: menu column mx counts from -8 so that cell 0 is fetched during cell -1.
// mx[8] = 1 means left of the window (cell -1); 256 is the right edge.
reg [8:0] mx = 0;
reg [1:0] mx_ph = 0;
reg       h_run = 0;
always @(posedge hclk) begin
    // one cell (24 columns) before the window
    if (hpos == X0 - 11'd25 + (ban_line ? shift : 3'd0)) begin
        h_run <= 1'b1;
        mx <= 9'h1F8;
        mx_ph <= 0;
    end else if (h_run) begin
        if (mx_ph == 2'd2) begin
            mx_ph <= 0;
            mx <= mx + 9'd1;
            if (mx == 9'd255) h_run <= 1'b0;
        end else
            mx_ph <= mx_ph + 2'd1;
    end
end

// Fetch the next cell: character at slot 0, font byte at slot 1, latch it at slot 2
wire       slot0 = h_run && mx[2:0] == 3'd0 && mx_ph == 2'd0;
reg        slot1, slot2;
reg [7:0]  next_font, cur_font;
reg [6:0]  next_char, cur_char;
wire [4:0] next_cell = mx[7:3] + 5'd1;

always @* begin
    if (slot1)
        mem_addr_b = {1'b1, mem_do_b[7] ? 7'h3F : mem_do_b[6:0], my[2:0]};  // '?' for non-ASCII
    else
        mem_addr_b = {1'b0, my[7:3], next_cell};
end

always @(posedge hclk) begin
    slot1 <= slot0;
    slot2 <= slot1;
    if (slot1) next_char <= mem_do_b[6:0];
    if (slot2) next_font <= mem_do_b;
    if (h_run && mx[2:0] == 3'd7 && mx_ph == 2'd2) begin
        cur_font <= next_font;
        cur_char <= next_char;
    end
end

// Output pixel
always @(posedge hclk) begin
    reg text, box;
    text = v_on && h_run && ~mx[8] && cur_font[mx[2:0]];
    box  = box_v && hpos >= box_x0 && hpos < box_x1;
    px_on <= text || box;
    px_color <= ban_line || box        ? (text ? COLOR_BANNER : COLOR_BOX) :
                my[7:3] == VERSION_ROW ? COLOR_VERSION :
                cur_char == 7'h3E      ? COLOR_CURSOR  : COLOR_TEXT;
end

endmodule
