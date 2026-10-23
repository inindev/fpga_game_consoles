# retro-fpga build entry point.
#
#   make nes        NES core      -> build/out/nes_nano20k.{fs,bin}
#   make snes       SNES core     -> build/out/snes_nano20k.{fs,bin}
#   make usb_probe  USB port diagnostic core (prints reports on the USB-C serial port)
#                                 -> build/out/usb_probe_nano20k.{fs,bin}
#   make firmware   menu firmware -> build/out/firmware.bin
#   make sdcard     collect cores/ for the SD card -> build/out/sdcard/
#   make verify     compare build/out/*.bin with the hardware-tested builds
#   make clean
#
# Gateware needs Gowin's tools (x86-64 Linux):  GOWIN_HOME=/path/to/IDE
# Firmware needs a RISC-V GCC (xPack riscv-none-elf 13.2.0-2 tested):
#   RISCV=/path/to/bin/riscv-none-elf   (prefix, without -gcc)

OUT      := build/out
GW       := build/gowin/gw.sh
RISCV    ?= riscv-none-elf

.PHONY: all nes snes usb_probe firmware sdcard verify clean

all: nes snes firmware

nes snes usb_probe:
	@mkdir -p $(OUT)/$@
	cd $(OUT)/$@ && rm -rf impl && GOWIN_HOME="$(GOWIN_HOME)" $(CURDIR)/$(GW) $(CURDIR)/build/gowin/$@_nano20k.tcl > gw_sh.log 2>&1 \
	  || { grep -E "ERROR" gw_sh.log; echo "build failed: see $(OUT)/$@/gw_sh.log"; exit 1; }
	@# -f: gw_sh writes the bitstreams read-only, so a plain cp can't overwrite them
	cp -f $(OUT)/$@/impl/pnr/$@_nano20k.fs $(OUT)/$@/impl/pnr/$@_nano20k.bin $(OUT)/
	@grep -A1 -E "^ *(Logic|BSRAM) " $(OUT)/$@/impl/pnr/$@_nano20k.rpt.txt | grep -E "Logic|BSRAM" || true
	@sha256sum $(OUT)/$@_nano20k.bin

firmware:
	$(MAKE) -C firmware RISCV=$(RISCV)
	@mkdir -p $(OUT) && cp firmware/firmware.bin $(OUT)/

sdcard:
	@mkdir -p $(OUT)/sdcard/cores
	cp $(OUT)/nes_nano20k.bin $(OUT)/snes_nano20k.bin $(OUT)/sdcard/cores/
	@echo "Copy $(OUT)/sdcard/cores/ to the root of the SD card; use menu '2) Select core'."

# The .bin has no timestamp (the .fs header does), so it is the file to compare.
# Same hash = same bitstream as the one tested on hardware.
verify:
	sha256sum -c build/expected.sha256

clean:
	rm -rf $(OUT)
	$(MAKE) -C firmware RISCV=$(RISCV) clean
