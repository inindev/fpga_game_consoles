// Testbench for platform/input/controller_snes.v: SNES/NES pad reader with NES-pad detection.
//
// Models the pad side of the wire:
//   - latch (joy_strb) high copies the buttons into the pad's shift register,
//   - each rising edge of joy_clk shifts the next bit onto joy_data,
//   - joy_data is active-low (0 = pressed); with no pad, the pin's pull-up reads 1.
// SNES pad: 12 buttons, then 4 bits that are always high ("not pressed").
// NES pad: 8 buttons, then its CD4021 shifts in its serial input, which is tied to
// ground, so every later bit reads low ("pressed"). That is what the detection uses.
//
// Run: make -C sim controller_snes
`timescale 1ns/1ps

module controller_snes_tb;
    // 1 MHz model clock keeps the simulation short: 6 us = 6 cycles, 16 ms = 16000.
    localparam FREQ = 1_000_000;

    reg clk = 0;
    always #500 clk = ~clk;                 // 1 MHz

    reg resetn = 0;
    wire joy_strb, joy_clk;
    wire [11:0] buttons;

    // ---------------- pad model ----------------
    localparam PAD_NONE = 0, PAD_SNES = 1, PAD_NES = 2;
    integer pad = PAD_NONE;
    reg [11:0] pressed = 0;                 // buttons held, 1 = pressed, SNES bit order
    reg [15:0] shreg = 16'hFFFF;            // wire levels, bit 0 is on the wire now

    function [15:0] wire_bits(input integer kind, input [11:0] p);
        case (kind)
            PAD_SNES: wire_bits = {4'b1111, ~p};                 // bits 13-16 always high
            PAD_NES:  wire_bits = {8'b0000_0000, ~p[7:0]};       // ground shifted in after 8
            default:  wire_bits = 16'hFFFF;                      // pulled up
        endcase
    endfunction

    always @(posedge clk)
        if (joy_strb) shreg <= wire_bits(pad, pressed);                       // latch
    always @(posedge joy_clk)
        if (!joy_strb) shreg <= {(pad == PAD_NES) ? 1'b0 : 1'b1, shreg[15:1]}; // shift
    wire joy_data = (pad == PAD_NONE) ? 1'b1 : shreg[0];

    controller_snes #(.FREQ(FREQ)) dut (
        .clk(clk), .resetn(resetn),
        .joy_strb(joy_strb), .joy_clk(joy_clk), .joy_data(joy_data),
        .buttons(buttons)
    );

    // ---------------- checks ----------------
    integer errors = 0;
    task scan;          // wait until the next complete scan has updated `buttons`
        begin
            @(negedge joy_strb);            // a scan starts...
            @(negedge joy_strb);            // ...and the one before it has finished
        end
    endtask
    task check(input [8*48-1:0] what, input [11:0] want);
        begin
            scan;
            if (buttons === want)
                $display("  PASS  %0s: buttons = %b", what, buttons);
            else begin
                $display("  FAIL  %0s: buttons = %b, expected %b", what, buttons, want);
                errors = errors + 1;
            end
        end
    endtask

    // SNES bit order: R L X A Right Left Down Up Start Select Y B (bit 11 .. bit 0)
    localparam B = 0, Y = 1, SEL = 2, START = 3, UP = 4, DOWN = 5, LEFT = 6, RIGHT = 7,
               A = 8, X = 9, L = 10, R = 11;
    // NES pads send A, B, Select, Start, Up, Down, Left, Right in the first 8 slots.

    initial begin
        repeat (5) @(posedge clk); resetn = 1;

        pad = PAD_NONE;  pressed = 0;
        check("no pad (pull-up)", 12'b0);

        pad = PAD_SNES;  pressed = 0;
        check("SNES pad, nothing pressed", 12'b0);

        pressed = (1 << B) | (1 << START) | (1 << A) | (1 << R);
        check("SNES pad, B+Start+A+R", (1 << B) | (1 << START) | (1 << A) | (1 << R));

        pressed = 12'hFFF;
        check("SNES pad, all 12 buttons", 12'hFFF);

        pad = PAD_NES;   pressed = (1 << 0) | (1 << 7);   // NES A (slot 0) + Right (slot 7)
        check("NES pad, A+Right (A/X/L/R must be 0)", (1 << 0) | (1 << 7));

        pressed = 12'h0FF;
        check("NES pad, all 8 buttons", 12'h0FF);

        pressed = 0;
        check("NES pad, nothing pressed", 12'b0);

        pad = PAD_SNES;  pressed = (1 << X) | (1 << L);
        check("swap back to SNES pad, X+L", (1 << X) | (1 << L));

        if (errors == 0) $display("controller_snes: all tests passed");
        else             $display("controller_snes: %0d test(s) FAILED", errors);
        $finish;
    end

    initial begin       // safety net: a full scan takes ~16.2 ms of model time
        #(400_000_000);
        $display("controller_snes: TIMEOUT");
        $finish;
    end
endmodule
