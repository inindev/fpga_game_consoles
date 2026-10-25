// Testbench for platform/video/nes_audio_hdmi.sv: NES audio to HDMI.
//
// Clocks as on the board: NES clk 21.6 MHz, pixel clock 74.25 MHz (unrelated phases), and
// clk_audio made from the pixel clock as nes_video.sv does (48 kHz).
//   1. Silence from the APU alone (0xFFFF) gives exactly 0 from power-up.
//   2. Silence at the expansion-sound level (0x7FFF) settles to 0 (|out| <= 1).
//   3. A 1 kHz square wave between the two comes out centred on 0 with its full swing,
//      less the droop of a 30 Hz high-pass over each half period.
//   4. Crossing: with the sample changing on every NES clock, every value the pixel side
//      takes is one the NES side held (never a mix of bits from two samples).
//
// Run: make -C sim nes_audio_hdmi
`timescale 1ps/1ps

module nes_audio_hdmi_tb;

reg clk = 0, clk_pixel = 0;
always #23148 clk = ~clk;               // 21.6 MHz
always #6734  clk_pixel = ~clk_pixel;   // 74.25 MHz

// clk_audio as in nes_video.sv: toggles every 773 pixel clocks
localparam AUDIO_CLK_DELAY = 74250 * 1000 / 48000 / 2;
reg [9:0] audio_divider = 0;
reg       clk_audio = 0;
always @(posedge clk_pixel)
    if (audio_divider != AUDIO_CLK_DELAY - 1) audio_divider <= audio_divider + 1'b1;
    else begin clk_audio <= ~clk_audio; audio_divider <= 0; end

reg  [15:0]        sample = 16'hFFFF;
wire signed [15:0] audio;
nes_audio_hdmi dut (.clk(clk), .sample(sample), .clk_pixel(clk_pixel), .clk_audio(clk_audio), .audio(audio));

integer errors = 0;
task fail(input [8*72-1:0] msg); begin $display("FAIL %0s", msg); errors = errors + 1; end endtask

// Count audio samples (falling edges of clk_audio, where the output updates)
integer nsamp = 0;
reg     clk_audio_d = 0;
always @(posedge clk_pixel) begin
    clk_audio_d <= clk_audio;
    if (clk_audio_d & ~clk_audio) nsamp = nsamp + 1;
end
task wait_samples(input integer n);
    integer s;
    begin s = nsamp; wait (nsamp >= s + n); @(posedge clk_pixel); @(posedge clk_pixel); end
endtask

// 4. Crossing: remember the last few values the NES side held
reg [15:0] held_hist [0:3];
integer    hi;
always @(posedge clk)
    if (dut.hold_count == 0) begin
        for (hi = 3; hi > 0; hi = hi - 1) held_hist[hi] <= held_hist[hi-1];
        held_hist[0] <= sample;         // what held becomes at this edge
    end
reg     cdc_check = 0;
integer cdc_bad = 0, cdc_takes = 0;
always @(posedge clk_pixel)
    if (cdc_check && (dut.toggle_sync[2] ^ dut.toggle_sync[1])) begin
        cdc_takes = cdc_takes + 1;
        #1;
        if (dut.x_now !== held_hist[0] && dut.x_now !== held_hist[1] && dut.x_now !== held_hist[2])
            cdc_bad = cdc_bad + 1;
    end

integer i, sum, mn, mx, n;
initial begin
    for (i = 0; i < 4; i = i + 1) held_hist[i] = 16'hFFFF;

    // 1. APU silence: exactly 0 from power-up
    sample = 16'hFFFF;
    wait_samples(200);
    if (audio !== 0) fail("APU silence (0xFFFF) is not 0");
    else $display("ok   APU silence (0xFFFF) -> %0d", audio);

    // 2. expansion-sound silence: a step, then back to 0
    sample = 16'h7FFF;
    wait_samples(5);
    $display("     step to 0x7FFF: output %0d", audio);
    wait_samples(4000);                 // ~83 ms, over 15 time constants of 256 samples
    if (audio > 1 || audio < -1) fail("expansion silence (0x7FFF) did not settle to 0");
    else $display("ok   expansion silence (0x7FFF) settles to %0d", audio);

    // 3. 1 kHz square wave between 0xFFFF and 0x7FFF
    sum = 0; mn = 32767; mx = -32768; n = 0;
    fork
        begin : tone
            forever begin sample = 16'hFFFF; #500000000; sample = 16'h7FFF; #500000000; end
        end
        begin
            wait_samples(4800);         // 100 ms to settle
            for (i = 0; i < 4800; i = i + 1) begin      // 100 ms = 100 periods
                wait_samples(1);
                sum = sum + audio; n = n + 1;
                if (audio < mn) mn = audio;
                if (audio > mx) mx = audio;
            end
            disable tone;
        end
    join
    $display("     1 kHz square: mean %0d, min %0d, max %0d", sum / n, mn, mx);
    // Swing after halving: (0xFFFF >> 1) - (0x7FFF >> 1) = 16384. A 30 Hz high-pass droops
    // about 9% over a 0.5 ms half period, so allow 16384 +- 10%.
    if (sum / n > 100 || sum / n < -100) fail("square wave not centred on 0");
    else if (mx - mn < 14745 || mx - mn > 18022) fail("square wave swing not 16384 +- 10%");
    else $display("ok   1 kHz square centred on 0, peak-to-peak %0d", mx - mn);

    // 4. crossing, with the sample changing on every NES clock
    cdc_check = 1;
    repeat (20000) @(posedge clk) sample <= $random;
    cdc_check = 0;
    if (cdc_bad) fail("crossing took a value the NES side never held");
    else $display("ok   crossing: %0d values taken, all held by the NES side", cdc_takes);

    if (errors == 0) $display("PASS");
    else             $display("FAILED: %0d test(s)", errors);
    $finish;
end

endmodule
