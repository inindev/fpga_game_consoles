# Simulation testbenches (Icarus Verilog).
#
#   make -C sim controller_snes     SNES/NES pad reader
#   make -C sim usb_hid_host        USB gamepad core: clock enable, report decoding
#   make -C sim video_out           scaler and menu overlay (needs GOWIN_HOME)
#   make -C sim nes_audio_hdmi      NES audio to HDMI: clock crossing, DC blocker
#   make -C sim nes_video           NES frame lock with HDMI (needs GOWIN_HOME)
#   make -C sim snes_video          SNES frame lock and line count (needs GOWIN_HOME)
#   make -C sim all
#
# IVERILOG/VVP can point at a non-standard install, e.g.
#   make -C sim IVERILOG="iverilog -B /opt/ivl/lib/ivl" VVP="vvp -M /opt/ivl/lib/ivl"
#
# Testbenches that use Gowin primitives (block RAM, LVDS buffer) take Gowin's simulation
# models from GOWIN_HOME (the IDE directory): simlib/gw2a/prim_sim.v.

IVERILOG ?= iverilog
VVP      ?= vvp
OUT      := ../build/out/sim
ROOT     := ..
GOWIN_PRIMS = $(GOWIN_HOME)/simlib/gw2a/prim_sim.v

# video/hdmi_sim.v stands in for third_party/hdmi, which Icarus cannot compile
VIDEO_SRC := $(ROOT)/platform/video/video_out.v $(ROOT)/platform/video/osd.v \
             $(ROOT)/platform/iosys/gowin_dpb_menu.v video/hdmi_sim.v

.PHONY: all controller_snes usb_hid_host nes_audio_hdmi video_out nes_video snes_video clean gowin_prims

all: controller_snes usb_hid_host nes_audio_hdmi video_out nes_video snes_video

nes_audio_hdmi:
	@mkdir -p $(OUT)
	$(IVERILOG) -g2012 -Wall -Wno-timescale -o $(OUT)/$@.vvp video/nes_audio_hdmi_tb.v $(ROOT)/platform/video/nes_audio_hdmi.sv
	$(VVP) -n $(OUT)/$@.vvp

controller_snes:
	@mkdir -p $(OUT)
	$(IVERILOG) -g2012 -Wall -Wno-timescale -o $(OUT)/$@.vvp input/controller_snes_tb.v $(ROOT)/platform/input/controller_snes.v
	$(VVP) -n $(OUT)/$@.vvp

# Runs from the ROM's folder so $readmemh finds usb_hid_host_rom.hex.
usb_hid_host:
	@mkdir -p $(OUT)
	$(IVERILOG) -g2012 -Wall -Wno-timescale -o $(OUT)/$@.vvp input/usb_hid_host_tb.v $(ROOT)/platform/input/usb_hid_host/usb_hid_host.v $(ROOT)/platform/input/usb_hid_host/usb_hid_host_rom.v
	cd $(ROOT)/platform/input/usb_hid_host && $(VVP) -n $(abspath $(OUT))/$@.vvp

gowin_prims:
	@test -f "$(GOWIN_PRIMS)" || { echo "set GOWIN_HOME to the Gowin IDE directory (need $(GOWIN_PRIMS))"; exit 1; }

video_out: gowin_prims
	@mkdir -p $(OUT)
	$(IVERILOG) -g2012 -Wno-timescale -o $(OUT)/$@.vvp video/video_out_tb.v $(VIDEO_SRC) $(GOWIN_PRIMS)
	$(VVP) -n $(OUT)/$@.vvp

nes_video: gowin_prims
	@mkdir -p $(OUT)
	$(IVERILOG) -g2012 -Wno-timescale -o $(OUT)/$@.vvp video/nes_video_tb.v $(ROOT)/platform/video/nes_video.sv $(ROOT)/platform/video/nes_audio_hdmi.sv $(VIDEO_SRC) $(GOWIN_PRIMS)
	$(VVP) -n $(OUT)/$@.vvp

# 239 visible lines (overscan) leaves the least room in the line buffer; LINES=224 for the normal mode
LINES ?= 239
snes_video: gowin_prims
	@mkdir -p $(OUT)
	$(IVERILOG) -g2012 -Wno-timescale -Psnes_video_tb.LINES=$(LINES) -o $(OUT)/$@.vvp video/snes_video_tb.v $(ROOT)/platform/video/snes_video.v $(ROOT)/platform/memory/dual_clk_fifo.v $(VIDEO_SRC) $(GOWIN_PRIMS)
	$(VVP) -n $(OUT)/$@.vvp

clean:
	rm -rf $(OUT)
