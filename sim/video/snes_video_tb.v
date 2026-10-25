// Testbench for platform/video/snes_video.v: frame lock with HDMI and the line count.
//
// A timing model of the PPU (341 dots x 262 lines, 4 mclk per dot, 21.6 MHz; LINES visible
// lines, numbered from 0 on PPU lines 1..LINES like the real PPU) stops while pause is
// high, as the SNES does through ENABLE. Each pixel's color encodes its frame parity, line
// and column. Once locked, each HDMI frame must show exactly one SNES frame with every
// line and column in place, and consecutive HDMI frames consecutive SNES frames. The
// adapter must also find the line count (src_lines) by itself. Square pixels.

`timescale 1ns / 1ps

module snes_video_tb;

parameter LINES = 239;                  // 224, or 239 in overscan mode

reg clk = 0, hclk = 0;
always #23.148 clk = ~clk;              // 21.6 MHz
always #6.734 hclk = ~hclk;             // 74.25 MHz

reg resetn = 0;
wire pause;

// PPU timing model
reg [10:0] h = 0;                       // mclk in the line, 0..1363
reg [8:0]  v = 0;                       // PPU line, 0..261
integer    frame = 0;
reg        enable = 0;
integer    paused_cycles = 0, pause_len = 0;
always @(posedge clk) begin
    enable <= resetn && ~pause;         // registered, as in the SNES top level
    if (~enable) begin
        if (resetn) paused_cycles = paused_cycles + 1;
    end else begin
        if (paused_cycles) pause_len = paused_cycles;
        paused_cycles = 0;
        h <= h == 11'd1363 ? 11'd0 : h + 11'd1;
        if (h == 11'd1363) begin
            v <= v == 9'd261 ? 9'd0 : v + 9'd1;
            if (v == 9'd261) frame = frame + 1;
        end
    end
end

wire [8:0] dot = h[10:2];
wire       hblank = dot < 22 || dot >= 278;
wire       vblank = v > LINES;
wire [7:0] out_x = dot - 22;
wire [7:0] out_y = v == 0 ? 8'd0 : v > LINES ? LINES : v - 1;
wire       refresh = h >= 538 && h < 578;

function [14:0] color_of(input integer f, input integer y, input integer x);
    color_of = {f[0], y[5:0], x[7:0]};
endfunction
// PPU line 0 is not displayed but still sets out_y = 0: write junk there, as the PPU does
wire [14:0] rgb5 = v == 0 ? 15'h7FFF : color_of(frame, out_y, out_x);

snes_video dut (
    .clk(clk), .resetn(resetn), .running(1'b1),
    .dotclk(h[1]), .hblank(hblank), .vblank(vblank), .rgb5(rgb5),
    .xs({out_x, h[1]}), .ys({1'b0, out_y}), .snes_refresh(refresh),
    .pause(pause),
    .audio_l(16'd0), .audio_r(16'd0), .audio_ready(1'b0),
    .shape(2'd1), .overlay(1'b0), .osd_we(1'b0), .osd_wdata(32'd0),
    .hclk(hclk), .hclk5(1'b0),
    .tmds_clk_n(), .tmds_clk_p(), .tmds_d_n(), .tmds_d_p()
);

wire [10:0] cx = dut.video.cx;
wire [9:0]  cy = dut.video.cy;
localparam Y0 = (720 - 3 * LINES) / 2;

function [23:0] to_rgb(input [14:0] q);
    to_rgb = {q[4:0], q[4:2], q[9:5], q[9:7], q[14:10], q[14:12]};
endfunction

// The frame on screen is the SNES frame in progress when HDMI starts the picture
integer shown = -1, prev_shown = -1, hdmi_frames = 0, errors = 0, frame_errors = 0;
reg     checking = 0;
always @(posedge hclk) begin
    if (cx == 0 && cy == Y0 && resetn) begin    // in reset, cx and cy stay at 0
        if (checking) begin
            if (frame_errors) $display("FAIL HDMI frame %0d (SNES frame %0d): %0d wrong pixels", hdmi_frames, shown, frame_errors);
            else              $display("ok   HDMI frame %0d shows SNES frame %0d, SNES paused %0d cycles", hdmi_frames, shown, pause_len);
            if (prev_shown >= 0 && shown != prev_shown + 1) begin
                $display("FAIL SNES frame %0d follows %0d", shown, prev_shown);
                errors = errors + 1;
            end
            errors = errors + frame_errors;
            prev_shown = shown;
        end
        hdmi_frames = hdmi_frames + 1;
        shown = frame;
        frame_errors = 0;
    end
    if (checking && cx < 1280 && cy < 720) begin : chk
        reg [23:0] e;
        if (cy >= Y0 && cy < Y0 + 3 * LINES && cx >= 256 && cx < 1024)
            e = dut.video.limited_rgb(to_rgb(color_of(shown, (cy - Y0) / 3, (cx - 256) / 3)));
        else
            e = dut.video.limited_rgb(24'h000000);
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
    wait (hdmi_frames >= 3);
    @(posedge hclk) checking = 1;
    wait (hdmi_frames >= 8);
    if (dut.src_lines != LINES) begin
        $display("FAIL src_lines = %0d, expected %0d", dut.src_lines, LINES);
        errors = errors + 1;
    end else
        $display("ok   src_lines = %0d", dut.src_lines);
    if (errors == 0) $display("PASS");
    else             $display("FAILED: %0d errors", errors);
    $finish;
end

endmodule
