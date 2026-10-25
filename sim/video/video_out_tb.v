// Testbench for platform/video/video_out.v and osd.v: the scaler and the menu overlay.
//
// The ring buffer is filled with a fixed pattern (each slot and column a different color),
// then whole HDMI frames are checked pixel by pixel against a model of what should be on
// screen: black outside the picture, each source line on 3 output lines, and each output
// column the source pixel under it or, where it straddles two source pixels, the mix
// weighted by how much of it each covers (computed here in real arithmetic, independently
// of the hardware's integer stepping). Checked for 8:7, square and 4:3 at 224, 239 and
// 240 lines. Then the menu: characters written through the register interface must show
// at 3x in the 768x672 window at (256, 24), over the game dimmed to 1/4, the cursor '>' in
// orange, and the banner row slanted, red on its white box.
// The output is in limited range: the model's 0-255 values go through the design's
// conversion (to_limited), which is checked first against CTA-861's
// round(16 + x * 219 / 255) for all 256 inputs: within 1, and exact at 0 and 255.

`timescale 1ns / 1ps

module video_out_tb;

reg clk = 0, hclk = 0;
always #23.148 clk = ~clk;              // 21.6 MHz
always #6.734 hclk = ~hclk;             // 74.25 MHz

reg         resetn = 0;
reg         pix_we = 0;
reg  [7:0]  pix_y = 0, pix_x = 0;
reg  [14:0] pix_data = 0;
reg  [8:0]  src_lines = 224;
reg         src_active = 1;
reg  [1:0]  shape = 0;
reg         overlay = 0;
reg         osd_we = 0;
reg  [31:0] osd_wdata = 0;
wire        frame_go;

video_out #(.PIX_FMT(0), .DW(15), .AUDIO_RATE(32000)) dut (
    .clk(clk), .resetn(resetn),
    .pix_we(pix_we), .pix_y(pix_y), .pix_x(pix_x), .pix_data(pix_data),
    .src_lines(src_lines), .src_active(src_active), .shape(shape), .frame_go(frame_go),
    .overlay(overlay), .osd_we(osd_we), .osd_wdata(osd_wdata),
    .hclk(hclk), .hclk5(1'b0), .clk_audio(1'b0), .audio_l(16'd0), .audio_r(16'd0),
    .tmds_clk_n(), .tmds_clk_p(), .tmds_d_n(), .tmds_d_p()
);

// Source pattern: BGR555 per ring slot and column
function [14:0] src(input [3:0] slot, input [7:0] x);
    reg [4:0] r, g, b;
    begin
        r = x[4:0] ^ {slot, 1'b0};
        g = {x[7:5], 2'b00} + {1'b0, slot};
        b = {slot[1:0], x[7:5]} ^ 5'b10101;
        src = {b, g, r};
    end
endfunction

function [23:0] to_rgb(input [14:0] q);
    to_rgb = {q[4:0], q[4:2], q[9:5], q[9:7], q[14:10], q[14:12]};
endfunction

// Menu contents as written by the test (0 = blank)
reg [6:0] chars [0:31][0:27];

// Banner as set by the test
reg     ban_on = 0;
integer ban_row = 0, ban_x0 = 0, ban_x1 = 0;

function [7:0] font_byte(input [6:0] c, input [2:0] row);
    reg [10:0] a;
    begin
        a = {1'b1, c, row};
        font_byte = dut.osd.menu_mem.dpb_inst_0.ram_MEM[a*8 +: 8];
    end
endfunction

// Expected pixel. tol is set to the allowed difference per channel.
integer tol;
function [23:0] expected(input integer x, input integer y);
    integer v, y0, w, x0, sy, i, s, ch, a8, b8, mx, my;
    real left, right, wb, e;
    reg [23:0] a, b, g;
    reg [7:0] fb;
    reg big, box, text;
    begin
        tol = 0;
        v = src_lines > 240 ? 240 : src_lines;
        y0 = (720 - 3 * v) / 2;
        case (shape)
        1:       begin w = 768;   x0 = 256; end
        2:       begin w = 4 * v; x0 = 640 - 2 * v; end
        default: begin w = 878;   x0 = 201; end
        endcase
        g = 0;
        if (src_active && y >= y0 && y < y0 + 3 * v && x >= x0 && x < x0 + w) begin
            sy = (y - y0) / 3;
            i = x - x0;
            left = i * 256.0 / w;
            right = (i + 1) * 256.0 / w;
            s = $rtoi(left);
            a = to_rgb(src(sy % 16, s));
            if (right <= s + 1 + 1e-9)
                g = a;
            else begin
                b = to_rgb(src(sy % 16, s + 1));
                wb = (right - (s + 1)) * w / 256.0;     // share of the output pixel over B
                for (ch = 0; ch < 3; ch = ch + 1) begin
                    a8 = a[ch*8 +: 8];
                    b8 = b[ch*8 +: 8];
                    e = a8 + (b8 - a8) * wb;
                    g[ch*8 +: 8] = $rtoi(e + 0.5);
                end
                tol = 1;
            end
        end
        expected = g;
        if (overlay) begin
            expected = {2'b0, g[23:18], 2'b0, g[15:10], 2'b0, g[7:2]};
            if (y >= 24 && y < 696) begin
                my = (y - 24) / 3;
                // The banner row is shifted right by 7 - (line in the row) columns
                big = ban_on && my / 8 == ban_row;
                mx = x - 256 - (big ? 7 - my % 8 : 0);
                text = 0;
                if (mx >= 0 && mx < 768) begin
                    mx = mx / 3;
                    fb = font_byte(chars[mx / 8][my / 8], my % 8);
                    text = fb[mx % 8];
                end
                box = ban_on && my + 2 >= 8 * ban_row && my + 2 < 8 * ban_row + 12 &&
                      x >= 256 + 24 * ban_x0 - 12 && x < 256 + 24 * (ban_x1 + 1) + 19;
                if (big || box) begin
                    if (text || box) begin
                        expected = text ? 24'hE60012 : 24'hFFFFFF;
                        tol = 0;
                    end
                end else if (text) begin
                    expected = my / 8 == 26                 ? 24'h505050 :
                               chars[mx / 8][my / 8] == ">" ? 24'hF8C080 : 24'hF8F880;
                    tol = 0;
                end
            end
        end
    end
endfunction

// Frame checker: compares every visible pixel of one frame
reg     checking = 0;
integer errors = 0, checked = 0, frame_errors;
always @(posedge hclk) begin
    if (checking && dut.cx < 1280 && dut.cy < 720) begin : chk
        reg [23:0] e, r;
        integer ch, d, bad;
        e = dut.limited_rgb(expected(dut.cx, dut.cy));
        r = dut.rgb;
        bad = 0;
        for (ch = 0; ch < 3; ch = ch + 1) begin
            d = r[ch*8 +: 8] - e[ch*8 +: 8];
            if (d > tol || d < -tol) bad = 1;
        end
        checked = checked + 1;
        if (bad) begin
            frame_errors = frame_errors + 1;
            if (frame_errors <= 5)
                $display("  MISMATCH at (%0d,%0d): got %06x expected %06x (tol %0d)",
                         dut.cx, dut.cy, r, e, tol);
        end
    end
end

task wait_line(input integer line);
    begin
        @(posedge hclk);
        while (!(dut.cx == 0 && dut.cy == line)) @(posedge hclk);
    end
endtask

// Check the next full frame. Settings must have been set before the previous frame's line
// 720, where the geometry is taken.
task check_frame(input [255:0] name);
    begin
        wait_line(720);                 // geometry for the next frame taken here
        wait_line(0);
        frame_errors = 0;
        checking = 1;
        wait_line(720);
        checking = 0;
        errors = errors + frame_errors;
        $display("%s %0s: %0d mismatches", frame_errors ? "FAIL" : "ok  ", name, frame_errors);
    end
endtask

task set_mode(input [1:0] sh, input [8:0] lines);
    begin
        @(posedge clk);
        shape <= sh;
        src_lines <= lines;
    end
endtask

task osd_write(input [4:0] x, input [4:0] y, input [6:0] c);
    begin
        @(posedge clk);
        osd_we <= 1;
        osd_wdata <= {6'b0, 2'd0, 3'b0, x, 3'b0, y, 1'b0, c};
        @(posedge clk);
        osd_we <= 0;
        chars[x][y] = c;
    end
endtask

task osd_banner(input on, input [4:0] y, input [4:0] x0, input [4:0] x1);
    begin
        @(posedge clk);
        osd_we <= 1;
        osd_wdata <= {6'b0, 2'd3, 3'b0, x0, 3'b0, y, on, 2'b0, x1};
        @(posedge clk);
        osd_we <= 0;
        ban_on = on;
        ban_row = y;
        ban_x0 = x0;
        ban_x1 = x1;
    end
endtask

// frame_go: one pulse per HDMI frame
integer go_count = 0;
always @(posedge clk) if (frame_go) go_count = go_count + 1;

integer k, gx, gy, go_before;
reg [111:0] title;
initial begin
    // limited-range conversion against CTA-861's formula
    begin : lim_check
        integer x, want, got, lim_errors;
        lim_errors = 0;
        for (x = 0; x < 256; x = x + 1) begin
            want = $rtoi(16.0 + x * 219.0 / 255.0 + 0.5);
            got = dut.to_limited(x[7:0]);
            if (got - want > 1 || want - got > 1 || ((x == 0 || x == 255) && got != want)) begin
                lim_errors = lim_errors + 1;
                $display("  MISMATCH to_limited(%0d) = %0d, CTA-861 %0d", x, got, want);
            end
        end
        errors = errors + lim_errors;
        $display("%s limited range: 0..255 -> %0d..%0d", lim_errors ? "FAIL" : "ok  ",
                 dut.to_limited(8'd0), dut.to_limited(8'd255));
    end

    for (gx = 0; gx < 32; gx = gx + 1)
        for (gy = 0; gy < 28; gy = gy + 1)
            chars[gx][gy] = 0;

    // fill all 16 ring slots
    repeat (4) @(posedge clk);
    resetn <= 1;
    for (k = 0; k < 4096; k = k + 1) begin
        @(posedge clk);
        pix_we <= 1;
        pix_y <= k[11:8];
        pix_x <= k[7:0];
        pix_data <= src(k[11:8], k[7:0]);
    end
    @(posedge clk);
    pix_we <= 0;

    set_mode(0, 224); check_frame("8:7, 224 lines");
    go_before = go_count;
    set_mode(1, 224); check_frame("square, 224 lines");
    if (go_count - go_before != 2) begin
        $display("FAIL frame_go: %0d pulses in 2 frames", go_count - go_before);
        errors = errors + 1;
    end else
        $display("ok   frame_go: one pulse per frame");
    set_mode(2, 224); check_frame("4:3, 224 lines");
    set_mode(0, 239); check_frame("8:7, 239 lines");
    set_mode(2, 239); check_frame("4:3, 239 lines");
    set_mode(0, 240); check_frame("8:7, 240 lines");
    set_mode(1, 240); check_frame("square, 240 lines");
    set_mode(2, 240); check_frame("4:3, 240 lines");

    @(posedge clk) src_active <= 0;
    set_mode(0, 224); check_frame("no game: black");
    @(posedge clk) src_active <= 1;

    // Menu: column 0, the last cell, the version row, and a full row (with '>' in column 29)
    osd_write(0, 0, "A");
    osd_write(31, 27, "Z");
    osd_write(10, 26, "v");
    for (k = 0; k < 32; k = k + 1)
        osd_write(k, 13, "!" + k);
    @(posedge clk) overlay <= 1;
    set_mode(0, 224); check_frame("menu over 8:7 game");
    set_mode(1, 240); check_frame("menu over square 240-line game");

    // Banner as on the main menu: row 7, box over cells 9..22. Characters in rows 6 and 8
    // where the box margin covers them show red; outside the box, normal.
    title = "Super Nintendo";
    for (k = 0; k < 14; k = k + 1)
        osd_write(9 + k, 7, title[(13 - k) * 8 +: 8]);
    osd_write(10, 6, "W");
    osd_write(20, 8, "M");
    osd_write(3, 8, "#");
    osd_banner(1, 7, 9, 22);
    set_mode(0, 224); check_frame("banner, row 7");
    // Full width on row 0: box beyond both window edges, row 13 text still normal
    osd_banner(1, 0, 0, 31);
    check_frame("banner, row 0, full width");
    osd_banner(0, 0, 0, 0);
    check_frame("banner off");

    if (errors == 0)
        $display("PASS: %0d pixels checked", checked);
    else
        $display("FAILED: %0d mismatches", errors);
    $finish;
end

endmodule
