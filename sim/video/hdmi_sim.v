// Simulation stand-in for third_party/hdmi/hdmi.sv, which Icarus Verilog cannot compile
// (array slices and assignment patterns in the packet code). Same ports and parameters;
// only the pixel position counters are modelled, with the same timing as hdmi.sv for
// 1280x720 (VIDEO_ID_CODE 4): cx/cy name the pixel the user generates in this clock, and
// rgb is taken in the same clock. tmds outputs are tied low.

module hdmi #(
    parameter VIDEO_ID_CODE = 4,
    parameter IT_CONTENT = 1,
    parameter BIT_WIDTH = 11,
    parameter BIT_HEIGHT = 10,
    parameter DVI_OUTPUT = 0,
    parameter real VIDEO_REFRESH_RATE = 60.0,
    parameter AUDIO_RATE = 44100,
    parameter AUDIO_BIT_WIDTH = 16,
    parameter START_X = 0,
    parameter START_Y = 0
) (
    input                        clk_pixel_x5,
    input                        clk_pixel,
    input                        clk_audio,
    input                        reset,
    input  [23:0]                rgb,
    input  [AUDIO_BIT_WIDTH-1:0] audio_sample_word [1:0],
    output [2:0]                 tmds,
    output                       tmds_clock,
    output reg [BIT_WIDTH-1:0]   cx = START_X,
    output reg [BIT_HEIGHT-1:0]  cy = START_Y,
    output [BIT_WIDTH-1:0]       frame_width,
    output [BIT_HEIGHT-1:0]      frame_height,
    output [BIT_WIDTH-1:0]       screen_width,
    output [BIT_HEIGHT-1:0]      screen_height
);

assign frame_width = 1650;
assign frame_height = 750;
assign screen_width = 1280;
assign screen_height = 720;
assign tmds = 3'b000;
assign tmds_clock = 1'b0;

always @(posedge clk_pixel) begin
    if (reset) begin
        cx <= START_X;
        cy <= START_Y;
    end else begin
        cx <= cx == frame_width - 1'b1 ? 0 : cx + 1'b1;
        cy <= cx == frame_width - 1'b1 ? (cy == frame_height - 1'b1 ? 0 : cy + 1'b1) : cy;
    end
end

endmodule
