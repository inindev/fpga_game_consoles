# Simulation testbenches (Icarus Verilog).
#
#   make -C sim controller_snes     SNES/NES pad reader
#   make -C sim all
#
# IVERILOG/VVP can point at a non-standard install, e.g.
#   make -C sim IVERILOG="iverilog -B /opt/ivl/lib/ivl" VVP="vvp -M /opt/ivl/lib/ivl"

IVERILOG ?= iverilog
VVP      ?= vvp
OUT      := ../build/out/sim
ROOT     := ..

.PHONY: all controller_snes clean

all: controller_snes

controller_snes:
	@mkdir -p $(OUT)
	$(IVERILOG) -g2012 -Wall -Wno-timescale -o $(OUT)/$@.vvp input/controller_snes_tb.v $(ROOT)/platform/input/controller_snes.v
	$(VVP) -n $(OUT)/$@.vvp

clean:
	rm -rf $(OUT)
