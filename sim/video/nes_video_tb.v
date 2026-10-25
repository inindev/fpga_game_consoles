// Testbench for platform/video/nes_video.sv: frame lock with HDMI.
//
// A timing model of the PPU (341 dots x 262 lines, 4 clocks per dot, 21.6 MHz) stops while
// pause is high, as nes.v does. Every pixel's palette index depends on its frame number,
// line and column. Once locked, each HDMI frame must show exactly one NES frame (the one
// that started when HDMI reached the picture), with every line and column in place, and
// consecutive HDMI frames must show consecutive NES frames: no tearing, none dropped or
// repeated. Square pixels, so every output pixel is one source pixel.

`timescale 1ns / 1ps

module nes_video_tb;

reg clk = 0, hclk = 0;
always #23.148 clk = ~clk;              // 21.6 MHz
always #6.734 hclk = ~hclk;             // 74.25 MHz

reg resetn = 0;
wire pause;

// PPU timing model
reg [1:0] div = 0;
reg [8:0] cycle = 0, scanline = 0;
integer   frame = 0;
reg       pause_d = 0;
integer   paused_cycles = 0, pause_len = 0;
always @(posedge clk) begin
    pause_d <= pause;
    if (pause_d) begin
        paused_cycles = paused_cycles + 1;
    end else if (resetn) begin
        if (paused_cycles) pause_len = paused_cycles;
        paused_cycles = 0;
        div <= div + 2'd1;
        if (div == 2'd3) begin
            cycle <= cycle == 9'd340 ? 9'd0 : cycle + 9'd1;
            if (cycle == 9'd340) begin
                scanline <= scanline == 9'd261 ? 9'd0 : scanline + 9'd1;
                if (scanline == 9'd261) frame = frame + 1;
            end
        end
    end
end

function [5:0] color_of(input integer f, input integer y, input integer x);
    color_of = (x + 3 * y + 5 * f) & 63;
endfunction
wire [5:0] color = color_of(frame, scanline, cycle);

nes_video dut (
    .clk(clk), .resetn(resetn), .running(1'b1),
    .color(color), .cycle(cycle), .scanline(scanline), .sample(16'd0),
    .pause(pause),
    .shape(2'd1), .overlay(1'b0), .osd_we(1'b0), .osd_wdata(32'd0),
    .hclk(hclk), .hclk5(1'b0),
    .tmds_clk_n(), .tmds_clk_p(), .tmds_d_n(), .tmds_d_p()
);

wire [10:0] cx = dut.video.cx;
wire [9:0]  cy = dut.video.cy;

// The frame on screen is the NES frame in progress when HDMI starts the picture (line 0,
// 240 lines so no border).
integer shown = -1, prev_shown = -1, hdmi_frames = 0, errors = 0, frame_errors = 0;
reg     checking = 0;
always @(posedge hclk) begin
    if (cx == 0 && cy == 0 && resetn) begin     // in reset, cx and cy stay at 0
        if (checking) begin
            if (frame_errors) $display("FAIL HDMI frame %0d (NES frame %0d): %0d wrong pixels", hdmi_frames, shown, frame_errors);
            else              $display("ok   HDMI frame %0d shows NES frame %0d, NES paused %0d cycles", hdmi_frames, shown, pause_len);
            if (prev_shown >= 0 && shown != prev_shown + 1) begin
                $display("FAIL NES frame %0d follows %0d", shown, prev_shown);
                errors = errors + 1;
            end
            errors = errors + frame_errors;
            prev_shown = shown;
        end
        hdmi_frames = hdmi_frames + 1;
        shown = frame;
        frame_errors = 0;
    end
    if (checking && cx >= 256 && cx < 1024 && cy < 720) begin : chk
        reg [23:0] e;
        e = dut.video.limited_rgb(dut.video.nes_palette(color_of(shown, cy / 3, (cx - 256) / 3)));
        if (dut.video.rgb !== e) begin
            frame_errors = frame_errors + 1;
            if (frame_errors <= 3)
                $display("  at (%0d,%0d): got %06x expected %06x", cx, cy, dut.video.rgb, e);
        end
    end
end

initial begin
    repeat (10) @(posedge clk);
    resetn <= 1;
    // lock takes at most two HDMI frames; then check four
    wait (hdmi_frames >= 3);
    @(posedge hclk) checking = 1;
    wait (hdmi_frames >= 8);
    if (errors == 0) $display("PASS");
    else             $display("FAILED: %0d errors", errors);
    $finish;
end

endmodule
