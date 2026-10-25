// NES audio to HDMI: clock-domain crossing and DC blocking. Written for retro-fpga.
//
// The NES core delivers an unsigned 16-bit sample in its own clock domain, inverted:
// silence is the highest value (0xFFFF from the APU alone; cartridges with expansion sound
// mix a halved APU sample with their own channels, so they rest near 0x7FFF). While a game
// plays, the resting level also moves: the triangle channel holds its last step when it
// stops, and the DMC holds the output level the game last set. HDMI audio is signed and
// expects silence at 0.
//
// A real NES has no DC at its output: it high-pass filters the DACs (90 Hz and 440 Hz on the
// NES, 37 Hz on the Famicom; nesdev wiki, "APU Mixer"). This module does the same:
//
// 1. Crossing (NES clk -> clk_pixel). The NES side holds the sample, updating it every
//    2^HOLD_BITS NES clocks together with a toggle. The pixel side copies the held value
//    once the toggle has passed three flip-flops, by which time the value has been stable
//    for many pixel clocks, so all 16 bits come from the same sample.
// 2. DC blocker, once per audio sample, a first-order high-pass:
//        y[n] = x[n] - x[n-1] + y[n-1] * (1 - 2^-POLE_SHIFT)
//    Cutoff = fs * 2^-POLE_SHIFT / (2 * pi): 29.8 Hz at fs = 48 kHz, POLE_SHIFT = 8, close
//    to the Famicom's filter and below any musical bass. y carries FRAC fraction bits, so
//    the output settles to within 1 LSB of 0.
// 3. The output changes on the falling edge of clk_audio (made in the clk_pixel domain by
//    nes_video.sv), half a period away from the rising edge where the HDMI encoder samples
//    it.
module nes_audio_hdmi #(
    parameter int HOLD_BITS  = 6,       // NES-side update period: 64 NES clocks (~3 us)
    parameter int POLE_SHIFT = 8,
    parameter int FRAC       = 8
) (
    input  logic        clk,            // NES clock
    input  logic [15:0] sample,         // NES clock domain, inverted (see above)
    input  logic        clk_pixel,
    input  logic        clk_audio,      // audio sample clock, made in the clk_pixel domain
    output logic signed [15:0] audio    // signed, silence = 0
);

logic signed [15:0] audio_r = 16'sd0;
assign audio = audio_r;

// ---- 1. Hold the sample and toggle, in the NES clock domain ----
logic [HOLD_BITS-1:0] hold_count = '0;
logic [15:0] held = 16'hFFFF;
logic        held_toggle = 1'b0;
always_ff @(posedge clk) begin
    hold_count <= hold_count + 1'b1;
    if (hold_count == '0) begin
        held <= sample;
        held_toggle <= ~held_toggle;
    end
end

// Synchronize the toggle; copy the held value when it flips
logic [2:0]  toggle_sync = 3'b000;
logic [15:0] x_now = 16'hFFFF;
always_ff @(posedge clk_pixel) begin
    toggle_sync <= {toggle_sync[1:0], held_toggle};
    if (toggle_sync[2] ^ toggle_sync[1])
        x_now <= held;
end

// ---- 2. DC blocker ----
localparam int W = 16 + FRAC + 2;                       // y * 2^FRAC, with headroom
logic signed [16:0]      x;                             // 0..32767: sample halved for headroom
logic signed [16:0]      x_prev = 17'sd32767;           // x of the power-up x_now: silence -> 0
logic signed [W-1:0]     y = '0;
logic signed [W-1:0]     y_next;
logic signed [W-FRAC-1:0] y_int;
assign x = $signed({2'b00, x_now[15:1]});
always_comb begin
    y_next = y - (y >>> POLE_SHIFT) + ($signed(W'(x - x_prev)) <<< FRAC);
    y_int = y_next >>> FRAC;
end

// ---- 3. Update once per audio sample, on the falling edge of clk_audio ----
logic clk_audio_d = 1'b0;
always_ff @(posedge clk_pixel) begin
    clk_audio_d <= clk_audio;
    if (clk_audio_d & ~clk_audio) begin
        x_prev <= x;
        y <= y_next;
        // A full-scale step can reach +-32767; saturate to 16-bit signed
        if (y_int > 32767)       audio_r <= 16'sd32767;
        else if (y_int < -32768) audio_r <= -16'sd32768;
        else                     audio_r <= y_int[15:0];
    end
end

endmodule
