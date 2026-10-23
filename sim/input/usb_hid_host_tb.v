// Testbench for platform/input/usb_hid_host/usb_hid_host.v: clock enable, gamepad decoding,
// setup watchdog.
//
// 1. Clock enable: with usbclk = 86.4 MHz and CE_NUM/CE_DEN = 5/36 (the SNES build), the
//    core must tick exactly 5 times every 36 cycles, 7 or 8 cycles apart. A second
//    instance with the default 1/1 (a real 12 MHz clock) must tick every cycle.
// 2. Gamepad decoding: instead of modelling a USB device, the USB engine's outputs
//    (data_rdy, data_strobe, ukpdat) are forced to deliver 8-byte reports, the device
//    type is forced to "gamepad" and conerr is forced low. Reports are in the layout
//    of the 0810:0001 SNES-style pads. Captured from a real pad (usbhid-dump):
//      idle 01 80 80 7F 7F 0F 00 00, L 01 80 80 7F 7F 0F 01 00, R ... 0F 02 00.
//    The d-pad values (bytes 3/4 = 00/FF) and the A/B/X/Y/Select/Start bits come from
//    the same pad's evdev mapping (HID buttons 1-10 in order from byte 5 bit 4).
// 3. Setup watchdog (separate instance, short timeout, line levels and `connected` forced):
//    restarts only while a device is attached (no long SE0) and not connected.
//
// Run: make -C sim usb_hid_host
`timescale 1ns/1ps

module usb_hid_host_tb;
    reg clk = 0;
    always #5.787 clk = ~clk;               // 86.4 MHz

    reg resetn = 0;
    tri0 usb_dp, usb_dm;                    // nothing connected; pull-downs as on the board
    tri0 usb_dp12, usb_dm12;
    wire [11:0] buttons;

    usb_hid_host #(.CE_NUM(5), .CE_DEN(36)) dut (
        .usbclk(clk), .usbrst_n(resetn),
        .usb_dm(usb_dm), .usb_dp(usb_dp),
        .game_snes(buttons)
    );
    usb_hid_host dut12 (                    // default 1/1: ce every cycle
        .usbclk(clk), .usbrst_n(resetn),
        .usb_dm(usb_dm12), .usb_dp(usb_dp12)
    );

    // Setup watchdog, with a short timeout. Line levels and `connected` are forced.
    localparam WD_TIMEOUT = 2000;           // clock-enable ticks
    tri0 usb_dpw, usb_dmw;
    usb_hid_host #(.CE_NUM(5), .CE_DEN(36), .SETUP_TIMEOUT(WD_TIMEOUT)) dutw (
        .usbclk(clk), .usbrst_n(resetn),
        .usb_dm(usb_dmw), .usb_dp(usb_dpw)
    );
    reg w_dp = 0, w_dm = 0, w_conn = 0;
    initial begin
        force dutw.line_dp = w_dp;
        force dutw.line_dm = w_dm;
        force dutw.connected = w_conn;
    end
    integer restarts = 0;
    always @(negedge clk) if (dutw.restart && dutw.ce) restarts = restarts + 1;

    // ---------------- forced USB engine outputs ----------------
    reg       rdy = 0, stb = 0, cerr = 0;
    reg [7:0] cur = 0;
    initial begin
        force dut.data_rdy = rdy;
        force dut.data_strobe = stb;
        force dut.ukpdat = cur;
        force dut.conerr = cerr;
        force dut.typ = 2'd3;               // gamepad
    end

    task wait_ce(input integer n);          // a clock-enable period is at most 8 cycles
        repeat (8 * n) @(posedge clk);
    endtask

    function [63:0] rpt(input [7:0] b0, b1, b2, b3, b4, b5, b6, b7);
        rpt = {b7, b6, b5, b4, b3, b2, b1, b0};
    endfunction

    task send(input [63:0] r);              // deliver one report, byte 0 first
        integer i;
        begin
            rdy = 1; wait_ce(2);
            for (i = 0; i < 8; i = i + 1) begin
                cur = r[i*8 +: 8];
                stb = 1; wait_ce(2);
                stb = 0; wait_ce(2);
            end
            rdy = 0; wait_ce(2);
        end
    endtask

    // ---------------- checks ----------------
    integer errors = 0;
    task check(input [8*48-1:0] what, input [11:0] want);
        begin
            if (buttons === want)
                $display("  PASS  %0s: buttons = %b", what, buttons);
            else begin
                $display("  FAIL  %0s: buttons = %b, expected %b", what, buttons, want);
                errors = errors + 1;
            end
        end
    endtask
    task expect_true(input [8*48-1:0] what, input ok);
        begin
            if (ok) $display("  PASS  %0s", what);
            else begin
                $display("  FAIL  %0s", what);
                errors = errors + 1;
            end
        end
    endtask

    // SNES bit order: R L X A Right Left Down Up Start Select Y B (bit 11 .. bit 0)
    localparam B = 0, Y = 1, SEL = 2, START = 3, UP = 4, DOWN = 5, LEFT = 6, RIGHT = 7,
               A = 8, X = 9, L = 10, R = 11;

    // Clock-enable counters, sampled on the falling edge (ce changes on the rising edge).
    integer ce_count = 0, ce12_count = 0, gap = 0, gap_min = 1000, gap_max = 0, cycles = 0;
    reg counting = 0;
    always @(negedge clk) if (counting) begin
        cycles = cycles + 1;
        gap = gap + 1;
        if (dut.ce) begin
            if (ce_count > 0) begin
                if (gap < gap_min) gap_min = gap;
                if (gap > gap_max) gap_max = gap;
            end
            ce_count = ce_count + 1;
            gap = 0;
        end
        if (dut12.ce) ce12_count = ce12_count + 1;
    end

    initial begin
        // ---- clock enable ----
        repeat (40) @(posedge clk);         // let both accumulators start
        @(negedge clk); counting = 1;
        repeat (36 * 1000) @(negedge clk);
        counting = 0;
        expect_true("5/36: 5000 ticks in 36000 cycles (12.000 MHz)",
                    ce_count == 5000 || ce_count == 5001);
        expect_true("5/36: ticks 7 or 8 cycles apart", gap_min == 7 && gap_max == 8);
        expect_true("1/1: a tick every cycle", ce12_count == cycles);
        $display("        (5/36: %0d ticks, gaps %0d..%0d; 1/1: %0d of %0d cycles)",
                 ce_count, gap_min, gap_max, ce12_count, cycles);

        // ---- gamepad decoding ----
        wait_ce(4); resetn = 1; wait_ce(4);

        send(rpt(8'h01, 8'h80, 8'h80, 8'h7F, 8'h7F, 8'h0F, 8'h00, 8'h00));
        check("idle", 12'b0);

        send(rpt(8'h01, 8'h80, 8'h80, 8'h00, 8'h7F, 8'h0F, 8'h00, 8'h00));
        check("d-pad left (byte 3 = 00)", 1 << LEFT);
        send(rpt(8'h01, 8'h80, 8'h80, 8'h7F, 8'h7F, 8'h0F, 8'h00, 8'h00));
        check("released (directions reset each report)", 12'b0);
        send(rpt(8'h01, 8'h80, 8'h80, 8'hFF, 8'h7F, 8'h0F, 8'h00, 8'h00));
        check("d-pad right (byte 3 = FF)", 1 << RIGHT);
        send(rpt(8'h01, 8'h80, 8'h80, 8'h7F, 8'h00, 8'h0F, 8'h00, 8'h00));
        check("d-pad up (byte 4 = 00)", 1 << UP);
        send(rpt(8'h01, 8'h80, 8'h80, 8'h7F, 8'hFF, 8'h0F, 8'h00, 8'h00));
        check("d-pad down (byte 4 = FF)", 1 << DOWN);
        send(rpt(8'h01, 8'h80, 8'h80, 8'h00, 8'h00, 8'h0F, 8'h00, 8'h00));
        check("d-pad up+left", (1 << UP) | (1 << LEFT));
        send(rpt(8'h01, 8'h80, 8'h80, 8'hFF, 8'hFF, 8'h0F, 8'h00, 8'h00));
        check("d-pad down+right", (1 << DOWN) | (1 << RIGHT));

        send(rpt(8'h01, 8'h80, 8'h80, 8'h7F, 8'h7F, 8'h1F, 8'h00, 8'h00));
        check("X (byte 5 bit 4)", 1 << X);
        send(rpt(8'h01, 8'h80, 8'h80, 8'h7F, 8'h7F, 8'h2F, 8'h00, 8'h00));
        check("A (byte 5 bit 5)", 1 << A);
        send(rpt(8'h01, 8'h80, 8'h80, 8'h7F, 8'h7F, 8'h4F, 8'h00, 8'h00));
        check("B (byte 5 bit 6)", 1 << B);
        send(rpt(8'h01, 8'h80, 8'h80, 8'h7F, 8'h7F, 8'h8F, 8'h00, 8'h00));
        check("Y (byte 5 bit 7)", 1 << Y);
        send(rpt(8'h01, 8'h80, 8'h80, 8'h7F, 8'h7F, 8'h0F, 8'h01, 8'h00));
        check("L (byte 6 bit 0, captured)", 1 << L);
        send(rpt(8'h01, 8'h80, 8'h80, 8'h7F, 8'h7F, 8'h0F, 8'h02, 8'h00));
        check("R (byte 6 bit 1, captured)", 1 << R);
        send(rpt(8'h01, 8'h80, 8'h80, 8'h7F, 8'h7F, 8'h0F, 8'h10, 8'h00));
        check("Select (byte 6 bit 4)", 1 << SEL);
        send(rpt(8'h01, 8'h80, 8'h80, 8'h7F, 8'h7F, 8'h0F, 8'h20, 8'h00));
        check("Start (byte 6 bit 5)", 1 << START);

        send(rpt(8'h01, 8'h80, 8'h80, 8'h7F, 8'h7F, 8'h6F, 8'h00, 8'h00));
        check("A+B", (1 << A) | (1 << B));
        send(rpt(8'h01, 8'h80, 8'h80, 8'h7F, 8'h7F, 8'h0F, 8'h33, 8'h00));
        check("L+R+Select+Start", (1 << L) | (1 << R) | (1 << SEL) | (1 << START));
        send(rpt(8'h01, 8'h80, 8'h80, 8'hFF, 8'hFF, 8'h8F, 8'h02, 8'h00));
        check("down+right+Y+R", (1 << DOWN) | (1 << RIGHT) | (1 << Y) | (1 << R));

        // Report ID 2 (second port of a dual adapter) is ignored: state stays as it was.
        send(rpt(8'h01, 8'h80, 8'h80, 8'h7F, 8'h7F, 8'h2F, 8'h00, 8'h00));
        send(rpt(8'h02, 8'h80, 8'h80, 8'h00, 8'h7F, 8'h0F, 8'h01, 8'h00));
        check("report ID 2 ignored (A still held)", 1 << A);

        // Connection error clears everything.
        cerr = 1; wait_ce(2); cerr = 0; wait_ce(2);
        check("connection error clears buttons", 12'b0);

        send(rpt(8'h01, 8'h80, 8'h80, 8'h7F, 8'h7F, 8'h0F, 8'h00, 8'h00));
        check("idle again", 12'b0);

        // ---- setup watchdog (one timeout is WD_TIMEOUT ticks, at most 8 cycles each) ----
        w_dp = 0; w_dm = 0; w_conn = 0; restarts = 0;           // empty port: SE0
        repeat (8 * 3 * WD_TIMEOUT) @(posedge clk);
        expect_true("watchdog: empty port (SE0), no restart", restarts == 0);

        w_dm = 1; restarts = 0;                                 // device attached, setup stuck
        repeat (8 * 3 * WD_TIMEOUT) @(posedge clk);
        expect_true("watchdog: attached, not connected: restarts", restarts >= 2);

        w_conn = 1; repeat (100) @(posedge clk); restarts = 0;  // device connected
        repeat (8 * 3 * WD_TIMEOUT) @(posedge clk);
        expect_true("watchdog: connected, no restart", restarts == 0);

        w_conn = 0; w_dm = 0; restarts = 0;                     // unplugged
        repeat (8 * 3 * WD_TIMEOUT) @(posedge clk);
        expect_true("watchdog: unplugged, no restart", restarts == 0);

        if (errors == 0) $display("usb_hid_host: all tests passed");
        else             $display("usb_hid_host: %0d test(s) FAILED", errors);
        $finish;
    end

    initial begin       // safety net: the whole run is under 1 ms of model time
        #(10_000_000);
        $display("usb_hid_host: TIMEOUT");
        $finish;
    end
endmodule
