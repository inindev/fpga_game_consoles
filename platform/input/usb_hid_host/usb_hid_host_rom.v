// Modified for retro-fpga (2026-10-23): added clock enable ce (see usb_hid_host.v). See git history.
module usb_hid_host_rom(clk, ce, adr, data);
	input clk;
	input ce;
	input [13:0] adr;
	output [3:0] data;
	reg [3:0] data; 
	reg [3:0] mem [536];
	initial $readmemh("usb_hid_host_rom.hex", mem);
	always @(posedge clk) if (ce) data <= mem[adr];
endmodule
