// Menu overlay: 32x28 characters in an 8x8 font (256x224 pixels), drawn at 3x in a fixed
// 768x672 window at (256, 24) of the 1280x720 frame. Written for retro-fpga; replaces
// textdisp.v from NESTang/SNESTang and keeps its register interface.
//
// The window has its own counters, independent of how the game picture is scaled.
// A character cell is 8 pixels = 24 output columns. During each cell the next cell's
// character and font byte are fetched (one memory port, 2 reads per 24 columns), and the
// font byte is switched in at the cell boundary.

module osd (
    // Core clock domain: register writes from iosys (0x0200_0000)
    //   [25:24] command: 0 = write a character, 1/2 = menu on/off (handled in iosys)
    //   [20:16] x, [12:8] y, [6:0] character
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
localparam [23:0] COLOR_CURSOR  = 24'hF8C080;   // orange: column 0, where the menu cursor is
localparam [23:0] COLOR_VERSION = 24'h505050;   // charcoal: row 26, the version line
localparam [4:0]  VERSION_ROW   = 5'd26;

wire [1:0] cmd       = osd_wdata[25:24];
wire [4:0] text_x    = osd_wdata[20:16];
wire [4:0] text_y    = osd_wdata[12:8];
wire [6:0] text_char = osd_wdata[6:0];

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

// Horizontal: menu column mx counts from -8 so that cell 0 is fetched during cell -1.
// mx[8] = 1 means left of the window (cell -1); 256 is the right edge.
reg [8:0] mx = 0;
reg [1:0] mx_ph = 0;
reg       h_run = 0;
always @(posedge hclk) begin
    if (hpos == X0 - 11'd25) begin      // one cell (24 columns) before the window
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
    if (slot2) next_font <= mem_do_b;
    if (h_run && mx[2:0] == 3'd7 && mx_ph == 2'd2)
        cur_font <= next_font;
end

// Output pixel
always @(posedge hclk) begin
    px_on <= v_on && h_run && ~mx[8] && cur_font[mx[2:0]];
    px_color <= my[7:3] == VERSION_ROW ? COLOR_VERSION :
                mx[7:3] == 5'd0        ? COLOR_CURSOR  : COLOR_TEXT;
end

endmodule
