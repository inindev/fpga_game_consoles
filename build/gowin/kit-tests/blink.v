// Kit test: Verilog flow. Toggles one LED from the 27 MHz board clock (~0.8 Hz).
module blink (
    input  clk,
    output led
);
    reg [24:0] count = 0;
    always @(posedge clk) count <= count + 1'b1;
    assign led = count[24];
endmodule
