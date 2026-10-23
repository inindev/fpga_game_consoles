// USB probe: a diagnostic core for the USB gamepad ports (not a console).
//
// Prints what each USB port receives over the USB-C serial port (115200 8N1):
//
//   P1 t=3 e=0 r=01 80 80 7F 7F 0F 00 00 b=............ n=01A3 c=1 w=0
//
//   t  device type (0 none, 1 keyboard, 2 mouse, 3 gamepad)
//   e  connection error flag
//   r  the last report, bytes in the order the core received them (its byte 0 first)
//   b  decoded buttons R L X A > < v ^ S s Y B (right left down up Start select),
//      '.' when not pressed
//   n  reports received so far (hex)
//   c  connected: setup finished and the device is being polled
//   w  setup watchdog restarts so far (hex, wraps at F)
//
// One port runs usb_hid_host from a real 12 MHz PLL, as upstream does; the other runs it from
// 86.4 MHz with CE_NUM/CE_DEN = 5/36, exactly as the SNES core does (see SWAP below). Moving
// one pad between the ports shows whether the clock enable changes what is received.
// A line is printed when a port's report, type or error flag changes, and every 2 s.
// LEDs (on = lit): led[0] port 1 sees a gamepad, led[1] port 2 sees a gamepad.

module usb_probe_top (
    input  sys_clk,                 // 27 MHz crystal
    output UART_TXD,
    output [1:0] led,
    inout  usb1_dp, usb1_dm,
    inout  usb2_dp, usb2_dm,
    output pa_en
);

assign pa_en = 1'b0;                // onboard audio amp off: its I2S inputs share USB2's pins

// ---------------- clocks and resets ----------------
wire clk12, clk86;
gowin_pll_usb  pll_usb  (.clkin(sys_clk), .reset(1'b0), .clkout(clk12), .clkoutp(), .lock());
gowin_pll_snes pll_snes (.clkin(sys_clk), .clkout(clk86), .clkoutp(), .clkoutd());

reg [7:0] rst12 = 0, rst86 = 0;
wire rstn12 = &rst12, rstn86 = &rst86;
always @(posedge clk12) if (~rstn12) rst12 <= rst12 + 8'd1;
always @(posedge clk86) if (~rstn86) rst86 <= rst86 + 8'd1;

// ---------------- the two USB ports ----------------
wire [1:0]  typ1, typ2;
wire        rep1, rep2, err1, err2, con1, con2, wd1, wd2;
wire [63:0] raw1, raw2;
wire [11:0] btn1, btn2;

// SWAP chooses which pins get which clock, to tell a pin problem from a clock-enable problem.
// 0: port 1 (pins 42/41) 12 MHz PLL, port 2 (pins 56/54) clock enable. 1: the other way round.
localparam SWAP = 1;
wire clk_p1  = SWAP ? clk86  : clk12;
wire clk_p2  = SWAP ? clk12  : clk86;
wire rstn_p1 = SWAP ? rstn86 : rstn12;
wire rstn_p2 = SWAP ? rstn12 : rstn86;

usb_hid_host #(.CE_NUM(SWAP ? 5 : 1), .CE_DEN(SWAP ? 36 : 1)) usb1 (
    .usbclk(clk_p1), .usbrst_n(rstn_p1),
    .usb_dm(usb1_dm), .usb_dp(usb1_dp),
    .typ(typ1), .report(rep1), .conerr(err1), .connected(con1), .restart(wd1),
    .game_snes(btn1), .dbg_hid_report(raw1)
);
usb_hid_host #(.CE_NUM(SWAP ? 1 : 5), .CE_DEN(SWAP ? 1 : 36)) usb2 (
    .usbclk(clk_p2), .usbrst_n(rstn_p2),
    .usb_dm(usb2_dm), .usb_dp(usb2_dp),
    .typ(typ2), .report(rep2), .conerr(err2), .connected(con2), .restart(wd2),
    .game_snes(btn2), .dbg_hid_report(raw2)
);

assign led = ~{typ2 == 2'd3, typ1 == 2'd3};             // LEDs are active low

// ---------------- hand each port's state to the 27 MHz printer ----------------
// One snapshot in flight per port (req/ack handshake), so the printer only ever
// copies values that are held still.
localparam SW = 64 + 12 + 2 + 1 + 1 + 4 + 16;  // raw, buttons, type, error, connected,
                                                // watchdog restarts, report count

wire [SW-1:0] snap1, snap2;
wire          req1, req2;
reg           ack1 = 0, ack2 = 0;

probe_port port1 (.clk(clk_p1), .report(rep1), .typ(typ1), .err(err1), .con(con1), .wd(wd1),
                  .raw(raw1), .btn(btn1), .snap(snap1), .req(req1), .ack(ack1));
probe_port port2 (.clk(clk_p2), .report(rep2), .typ(typ2), .err(err2), .con(con2), .wd(wd2),
                  .raw(raw2), .btn(btn2), .snap(snap2), .req(req2), .ack(ack2));

reg [1:0] req1_s = 0, req2_s = 0;
reg [SW-1:0] cur1 = 0, cur2 = 0;                        // latest snapshot of each port
reg new1 = 0, new2 = 0;                                 // not yet printed

// printer state (the printer itself is below)
reg          printing = 0;
reg  [6:0]   pos = 0;
reg          line_port = 0;                             // 0: port 1, 1: port 2
reg [SW-1:0] line = 0;
wire         pick1 = ~printing & new1;                  // printer takes port 1's snapshot
wire         pick2 = ~printing & ~new1 & new2;

reg [25:0] timer = 0;                                   // 2 s at 27 MHz
always @(posedge sys_clk) begin
    if (pick1) new1 <= 0;                               // first, so a snapshot arriving
    if (pick2) new2 <= 0;                               // in the same cycle is kept
    req1_s <= {req1_s[0], req1};
    req2_s <= {req2_s[0], req2};
    if (req1_s[1] != ack1) begin cur1 <= snap1; ack1 <= req1_s[1]; new1 <= 1; end
    if (req2_s[1] != ack2) begin cur2 <= snap2; ack2 <= req2_s[1]; new2 <= 1; end
    timer <= timer + 26'd1;
    if (timer == 26'd53_999_999) begin
        timer <= 0;
        new1 <= 1; new2 <= 1;
    end
end

// ---------------- printer ----------------
localparam LEN = 68;                                    // characters per line, incl. \r\n
localparam [8*12-1:0] NAMES = "RLXA><v^SsYB";           // button letters, bit 11 first

wire [63:0] l_raw = line[99:36];
wire [11:0] l_btn = line[35:24];
wire [1:0]  l_typ = line[23:22];
wire        l_err = line[21];
wire        l_con = line[20];
wire [3:0]  l_wd  = line[19:16];
wire [15:0] l_cnt = line[15:0];

function [7:0] hexc(input [3:0] v);
    hexc = (v < 4'd10) ? 8'h30 + v : 8'h41 + v - 8'd10;
endfunction

reg [7:0] ch;
integer j, m, i;
always @* begin
    ch = " ";
    j = 0; m = 0; i = 0;
    if (pos == 0)       ch = "P";
    else if (pos == 1)  ch = line_port ? "2" : "1";
    else if (pos == 3)  ch = "t";
    else if (pos == 4)  ch = "=";
    else if (pos == 5)  ch = 8'h30 + l_typ;
    else if (pos == 7)  ch = "e";
    else if (pos == 8)  ch = "=";
    else if (pos == 9)  ch = 8'h30 + l_err;
    else if (pos == 11) ch = "r";
    else if (pos == 12) ch = "=";
    else if (pos >= 13 && pos <= 36) begin              // 8 bytes as "HH "
        j = (pos - 13) / 3;
        m = (pos - 13) % 3;
        if (m == 0)      ch = hexc(l_raw[j*8+4 +: 4]);
        else if (m == 1) ch = hexc(l_raw[j*8 +: 4]);
    end
    else if (pos == 37) ch = "b";
    else if (pos == 38) ch = "=";
    else if (pos >= 39 && pos <= 50) begin              // 12 buttons, bit 11 first
        i = pos - 39;
        ch = l_btn[11 - i] ? NAMES[(11 - i)*8 +: 8] : ".";
    end
    else if (pos == 52) ch = "n";
    else if (pos == 53) ch = "=";
    else if (pos >= 54 && pos <= 57) ch = hexc(l_cnt[(57 - pos)*4 +: 4]);
    else if (pos == 59) ch = "c";
    else if (pos == 60) ch = "=";
    else if (pos == 61) ch = 8'h30 + l_con;
    else if (pos == 63) ch = "w";
    else if (pos == 64) ch = "=";
    else if (pos == 65) ch = hexc(l_wd);
    else if (pos == 66) ch = 8'h0D;
    else if (pos == 67) ch = 8'h0A;
end

reg  [7:0] din = 0;
reg        wr_en = 0;
wire       tx_busy;
uart_tx_V2 #(.clk_freq(27000000), .uart_freq(115200)) tx (
    .clk(sys_clk), .din(din), .wr_en(wr_en), .tx_busy(tx_busy), .tx_p(UART_TXD)
);

always @(posedge sys_clk) begin
    wr_en <= 0;
    if (pick1) begin line <= cur1; line_port <= 0; printing <= 1; pos <= 0; end
    else if (pick2) begin line <= cur2; line_port <= 1; printing <= 1; pos <= 0; end
    else if (printing && !tx_busy && !wr_en) begin
        din <= ch;
        wr_en <= 1;
        if (pos == LEN - 1) printing <= 0;
        else pos <= pos + 7'd1;
    end
end

endmodule

// One USB port's state, captured in its own clock domain for the printer.
module probe_port (
    input             clk,
    input             report,       // pulse after each report (one clock-enable period long)
    input      [1:0]  typ,
    input             err,
    input             con,          // connected
    input             wd,           // setup watchdog restart pulse (one clock-enable period)
    input      [63:0] raw,
    input      [11:0] btn,
    output     [99:0] snap,         // {raw, btn, typ, err, con, restarts, count}
    output            req,          // toggles when snap holds a new value
    input             ack           // printer's copy of req (other clock domain)
);
    reg [99:0] snap_r = 0;
    reg        req_r = 0;
    assign snap = snap_r;
    assign req = req_r;
    reg        rep_r = 0, err_r = 0, con_r = 0, wd_r = 0, dirty = 1;
    reg [1:0]  typ_r = 0, ack_s = 0;
    reg [3:0]  restarts = 0;
    reg [15:0] cnt = 0;
    wire       new_rep = report & ~rep_r;
    wire       new_wd = wd & ~wd_r;

    always @(posedge clk) begin
        ack_s <= {ack_s[0], ack};
        rep_r <= report;
        typ_r <= typ;
        err_r <= err;
        con_r <= con;
        wd_r <= wd;
        if (dirty && req_r == ack_s[1]) begin           // printer has the previous one
            snap_r <= {raw, btn, typ, err, con, restarts, cnt};
            req_r <= ~req_r;
            dirty <= 0;
        end
        if (new_rep) begin cnt <= cnt + 16'd1; dirty <= 1; end
        if (new_wd) begin restarts <= restarts + 4'd1; dirty <= 1; end
        if (typ != typ_r || err != err_r || con != con_r) dirty <= 1;
    end
endmodule
