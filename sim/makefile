# Simulation testbenches (Icarus Verilog).
#
#   make -C sim controller_snes     SNES/NES pad reader
#   make -C sim usb_hid_host        USB gamepad core: clock enable, report decoding
#   make -C sim all
#
# IVERILOG/VVP can point at a non-standard install, e.g.
#   make -C sim IVERILOG="iverilog -B /opt/ivl/lib/ivl" VVP="vvp -M /opt/ivl/lib/ivl"

IVERILOG ?= iverilog
VVP      ?= vvp
OUT      := ../build/out/sim
ROOT     := ..

.PHONY: all controller_snes usb_hid_host clean

all: controller_snes usb_hid_host

controller_snes:
	@mkdir -p $(OUT)
	$(IVERILOG) -g2012 -Wall -Wno-timescale -o $(OUT)/$@.vvp input/controller_snes_tb.v $(ROOT)/platform/input/controller_snes.v
	$(VVP) -n $(OUT)/$@.vvp

# Runs from the ROM's folder so $readmemh finds usb_hid_host_rom.hex.
usb_hid_host:
	@mkdir -p $(OUT)
	$(IVERILOG) -g2012 -Wall -Wno-timescale -o $(OUT)/$@.vvp input/usb_hid_host_tb.v $(ROOT)/platform/input/usb_hid_host/usb_hid_host.v $(ROOT)/platform/input/usb_hid_host/usb_hid_host_rom.v
	cd $(ROOT)/platform/input/usb_hid_host && $(VVP) -n $(abspath $(OUT))/$@.vvp

clean:
	rm -rf $(OUT)
