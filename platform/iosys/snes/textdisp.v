// Modified for retro-fpga (2026-10-23): no logo; text on row 26 (the version line) is
// charcoal. See git history.
//
// 32x28 text display in 8x8 font, with a picorv32 register I/O interface
// to print characters to the display.

module textdisp(
	input             clk,              // main logic clock
    input             hclk,             // hdmi clock
	input             resetn,

    input      [7:0]  x,                // 0 - 255
    input      [7:0]  y,                // 0 - 223
    output reg [14:0] color,            // pixel color, NOTE: 2-cycle latency
                                        // we need 1 cycle to fetch character and 1 cycle to fetch font byte

    // PicoRV32 I/O interface. Every write updates one character
    // [23:16]: x, [15:8]: y, [7-0]: character to print
	input      [3:0]  reg_char_we,
	input      [31:0] reg_char_di
);

// BGR
localparam [14:0] COLOR_BACK    = 15'b00000_00000_00000;
localparam [14:0] COLOR_TEXT    = 15'b10000_11111_11111;    // yellow
//localparam [14:0] COLOR_TEXT    = 15'b11000_11000_11000;    // white
localparam [14:0] COLOR_CURSOR  = 15'b10000_11000_11111;    // orange
localparam [14:0] COLOR_VERSION = 15'b01010_01010_01010;    // charcoal
localparam [4:0]  VERSION_ROW   = 5'd26;

//
// Pixel output logic for characters:
// 1. To improve timing, output logic is broken into 3 cycles.
// 2. Char buffer and font rom are stored in the same bram block to save LUTs.
//
reg [10:0] mem_addr_b;
reg [7:0] mem_do_b;
reg is_cursor, is_version;
reg [14:0] overlay_color_buf;

wire [1:0] cmd = reg_char_di[31:24];
wire [4:0] text_x = reg_char_di[20:16];
wire [4:0] text_y = reg_char_di[12:8];
wire [6:0] text_char = reg_char_di[6:0];

// Char buffer and font rom backed by Dual-port BRAM (total 2KB)
// this is initialized with font.mi (font.vh + logo.vh)
// $000-$37F: Character buffer RAM (32*28)
// $380-$3FF: Logo bitmap (14*9 bytes, not drawn)
// $400-$800: Font ROM
gowin_dpb_menu menu_mem (
    .clka(clk), .reseta(1'b0), .ocea(), .cea(1'b1), 
    .ada({1'b0, text_y, text_x}), .wrea(reg_char_we[0] && cmd == 2'd0),
    .dina({1'b0, text_char}), .douta(), 

    .clkb(hclk), .resetb(1'b0), .oceb(), .ceb(1'b1), 
    .adb(mem_addr_b), .wreb(1'b0), 
    .dinb(), .doutb(mem_do_b)
);

reg [14:0] color_buf;
reg [7:0] x_r;

// Rendering state machine
reg [2:0] state;
localparam MAIN = 0;        // default state and fetching character
localparam FETCH_FONT = 1;  // fetch font byte
localparam OUTPUT = 3;      // output new pixel and fetch character

always @* begin             // address and output logic
    color = color_buf;
    case (state)
    MAIN:           mem_addr_b = {1'b0, y[7:3], x[7:3]};   
    FETCH_FONT:     mem_addr_b = {1'b1, mem_do_b[7] ? 7'h3F : mem_do_b[6:0], y[2:0]};  
    OUTPUT: begin
        mem_addr_b = {1'b0, y[7:3], x[7:3]};
        color = mem_do_b[x[2:0]] ? (is_version ? COLOR_VERSION :
                                    is_cursor  ? COLOR_CURSOR  : COLOR_TEXT) : COLOR_BACK;
    end
    default: mem_addr_b = 0;
    endcase
end

always @(posedge hclk) begin    // actual state machine
    x_r <= x;
    
    case (state)
    MAIN, OUTPUT: begin
        state <= MAIN;
        if (state == OUTPUT) color_buf <= color;
        if (x[0] != x_r[0])         // moved to new pixel
            state <= FETCH_FONT;
        is_cursor <= x[7:3] == 0;
        is_version <= y[7:3] == VERSION_ROW;
    end

    FETCH_FONT: state <= OUTPUT;

    default: ;
    endcase
end

endmodule