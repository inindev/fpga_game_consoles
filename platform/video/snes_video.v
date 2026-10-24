// SNES video and sound to HDMI. Written for retro-fpga; replaces snes2hdmi.v from SNESTang
// (frame lock and audio FIFO carried over from it).
//
// Feeds the PPU's 256-pixel lines (224 or 239 of them, see src_lines) into video_out.v
// (line ring buffer, scaler, menu, HDMI) and keeps the SNES locked to the HDMI frame rate.
// The SNES runs about 0.7% fast; once per frame it is paused during the DRAM refresh of
// line 1 until HDMI is about to show line 0 (frame_go). The DSP also runs a bit fast, and
// the audio FIFO covers the pause.

module snes_video (
    input             clk,              // SNES mclk, 21.6 MHz
    input             resetn,
    input             running,          // a game is loaded

    // PPU
    input             dotclk,
    input             hblank,
    input             vblank,
    input      [14:0] rgb5,             // BGR555
    input      [8:0]  xs,               // {x, dotclk}
    input      [8:0]  ys,               // {field, y}
    input             snes_refresh,     // DRAM refresh: the pause starts here
    output reg        pause = 0,        // hold the SNES (frame lock)

    // DSP
    input      [15:0] audio_l,
    input      [15:0] audio_r,
    input             audio_ready,

    // Settings and menu (iosys)
    input      [1:0]  shape,
    input             overlay,
    input             osd_we,
    input      [31:0] osd_wdata,

    // HDMI
    input             hclk,
    input             hclk5,
    output            tmds_clk_n,
    output            tmds_clk_p,
    output     [2:0]  tmds_d_n,
    output     [2:0]  tmds_d_p
);

localparam AUDIO_RATE = 32000;
localparam [7:0] PAUSE_LINE = 8'd1;     // pause here: line 0 is complete
localparam [7:0] REARM_LINE = 8'd200;

// Pixels: one per dot on visible lines. Lines are counted to tell 224 from 239 (overscan).
reg        r_dotclk, r_vblank;
reg        pix_we;
reg [7:0]  pix_y, pix_x;
reg [14:0] pix_data;
reg [7:0]  last_y;
reg [8:0]  src_lines = 9'd224;
always @(posedge clk) begin
    r_dotclk <= dotclk;
    r_vblank <= vblank;
    pix_we <= 1'b0;
    if (dotclk && ~r_dotclk && ~hblank && ~vblank && ys[7:0] < 8'd240) begin
        pix_we <= 1'b1;
        pix_y <= ys[7:0];
        pix_x <= xs[8:1];
        pix_data <= rgb5;
        last_y <= ys[7:0];
    end
    if (vblank && ~r_vblank && last_y >= 8'd200)
        src_lines <= {1'b0, last_y} + 9'd1;
end

// Frame lock. The pause lasts an even number of cycles (pause_sync) so that the PPU's
// SDRAM accesses stay in step.
wire frame_go;
reg  locked = 0;                        // paused once this frame
reg  go;                                // frame_go seen during this pause
reg  pause_sync;
always @(posedge clk) begin
    if (pause) pause_sync <= ~pause_sync;
    if (~resetn) begin
        pause <= 1'b0;
        locked <= 1'b0;
    end else begin
        if (~locked) begin
            if (~pause) begin
                if (ys[7:0] == PAUSE_LINE && snes_refresh) begin
                    pause <= 1'b1;
                    pause_sync <= 1'b0;
                    go <= 1'b0;
                end
            end else if (go && pause_sync) begin
                pause <= 1'b0;
                locked <= 1'b1;
            end
        end
        if (frame_go) go <= 1'b1;
        if (ys[7:0] == REARM_LINE) locked <= 1'b0;
    end
end

// Audio: 32 kHz sample clock. The SNES pause is about 8 samples per frame, so the DSP runs
// a bit fast and a 16-sample FIFO buffers the difference.
// Hoarse sound issue: https://github.com/nand2mario/snestang/issues/16
localparam AUDIO_DELAY = 74250 * 1000 / AUDIO_RATE / 2;
reg [$clog2(AUDIO_DELAY)-1:0] audio_divider = 0;
reg        clk_audio = 0;
reg        audio_rinc;
reg [15:0] audio_out_l, audio_out_r;
wire       audio_full, audio_empty;
wire [31:0] audio_sample;

reg [1:0] hrst_s;
always @(posedge hclk) hrst_s <= {hrst_s[0], resetn};

always @(posedge hclk) begin
    audio_rinc <= 1'b0;
    if (hrst_s[1]) begin
        if (audio_divider != AUDIO_DELAY - 1)
            audio_divider <= audio_divider + 1'b1;
        else begin
            audio_divider <= 0;
            clk_audio <= ~clk_audio;
            // change the sample on the falling edge of clk_audio; the HDMI encoder
            // samples it on the rising edge
            if (clk_audio && !audio_empty) begin
                {audio_out_l, audio_out_r} <= audio_sample;
                audio_rinc <= 1'b1;
            end
        end
    end
end

dual_clk_fifo #(.DATESIZE(32), .ADDRSIZE(4)) audio_fifo (
    .clk(clk), .wrst_n(1'b1),
    .winc(audio_ready), .wdata({audio_l, audio_r}), .wfull(audio_full),
    .rclk(hclk), .rrst_n(1'b1),
    .rinc(audio_rinc), .rdata(audio_sample), .rempty(audio_empty),
    .almost_full(), .almost_empty()
);

video_out #(.PIX_FMT(0), .DW(15), .AUDIO_RATE(AUDIO_RATE)) video (
    .clk(clk), .resetn(resetn),
    .pix_we(pix_we), .pix_y(pix_y), .pix_x(pix_x), .pix_data(pix_data),
    .src_lines(src_lines), .src_active(running), .shape(shape), .frame_go(frame_go),
    .overlay(overlay), .osd_we(osd_we), .osd_wdata(osd_wdata),
    .hclk(hclk), .hclk5(hclk5),
    .clk_audio(clk_audio), .audio_l(audio_out_l), .audio_r(audio_out_r),
    .tmds_clk_n(tmds_clk_n), .tmds_clk_p(tmds_clk_p), .tmds_d_n(tmds_d_n), .tmds_d_p(tmds_d_p)
);

endmodule
