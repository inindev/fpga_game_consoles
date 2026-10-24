# Gowin build for the SNES core on the Tang Nano 20K (GW2AR-LV18QN88C8/I7).
# Run through build/gowin/gw.sh (see build/Makefile); gw_sh puts impl/ in the current directory.
# File list and options follow snestang v0.9 build.tcl (nano20k), in the same order.

set root [file normalize [file join [file dirname [info script]] .. ..]]

# Set by the makefile (CONTROLLERS, TEST_PATTERN): output name, and the pin file it generated in the build
# folder, next to build.vh (which config.v includes; that folder is the include path).
foreach v {RF_NAME RF_CST} {
    if {![info exists ::env($v)]} { error "$v not set: build with make (see makefile)" }
}

set_device GW2AR-LV18QN88C8/I7 -device_version C

add_file -type verilog "$root/boards/tang-nano-20k/snes/config.v"
add_file -type verilog "$root/platform/video/osd.v"
add_file -type verilog "$root/platform/video/video_out.v"
add_file -type verilog "$root/platform/video/snes_video.v"
add_file -type verilog "$root/boards/tang-nano-20k/gowin_pll_hdmi.v"
add_file -type verilog "$root/boards/tang-nano-20k/snes/gowin_pll_snes.v"
add_file -type verilog "$root/platform/memory/sdram_snes.v"
add_file -type verilog "$root/systems/snes/chips/s-cpu_5a22/65c816/alu.v"
add_file -type verilog "$root/systems/snes/chips/s-cpu_5a22/65c816/addsubbcd.v"
add_file -type verilog "$root/systems/snes/chips/s-cpu_5a22/65c816/addrgen.v"
add_file -type verilog "$root/systems/snes/chips/s-cpu_5a22/65c816/bcdadder.v"
add_file -type verilog "$root/systems/snes/chips/s-cpu_5a22/65c816/p65c816.v"
add_file -type verilog "$root/systems/snes/chips/s-cpu_5a22/65c816/adder4.v"
add_file -type verilog "$root/systems/snes/chips/s-cpu_5a22/65c816/bit_adder.v"
add_file -type verilog "$root/systems/snes/chips/s-cpu_5a22/65c816/common.sv"
add_file -type verilog "$root/systems/snes/chips/s-cpu_5a22/65c816/mcode.sv"
add_file -type verilog "$root/systems/snes/cegen.v"
add_file -type verilog "$root/systems/snes/cartridge/enhancement/dsp/dsp_lhrommap.v"
add_file -type verilog "$root/systems/snes/cartridge/enhancement/dsp/dspn.v"
add_file -type verilog "$root/systems/snes/cartridge/enhancement/obc1/obc1.v"
add_file -type verilog "$root/systems/snes/cartridge/enhancement/s-rtc/srtc.v"
add_file -type verilog "$root/systems/snes/cartridge/enhancement/dsp/dsp_data_ram.v"
add_file -type verilog "$root/systems/snes/chips/s-cpu_5a22/cpu.v"
add_file -type verilog "$root/systems/snes/chips/s-dsp/dsp.v"
add_file -type verilog "$root/platform/memory/dual_clk_fifo.v"
add_file -type verilog "$root/platform/input/dualshock_controller.v"
add_file -type verilog "$root/systems/snes/chips/s-ppu/gowin_dpb_cgram.v"
add_file -type verilog "$root/systems/snes/chips/s-ppu/gowin_dpb_hoam.v"
add_file -type verilog "$root/systems/snes/chips/s-ppu/gowin_dpb_oam.v"
add_file -type verilog "$root/third_party/hdmi/audio_clock_regeneration_packet.sv"
add_file -type verilog "$root/third_party/hdmi/audio_info_frame.sv"
add_file -type verilog "$root/third_party/hdmi/audio_sample_packet.sv"
add_file -type verilog "$root/third_party/hdmi/auxiliary_video_information_info_frame.sv"
add_file -type verilog "$root/third_party/hdmi/hdmi.sv"
add_file -type verilog "$root/third_party/hdmi/packet_assembler.sv"
add_file -type verilog "$root/third_party/hdmi/packet_picker.sv"
add_file -type verilog "$root/third_party/hdmi/serializer.sv"
add_file -type verilog "$root/third_party/hdmi/source_product_description_info_frame.sv"
add_file -type verilog "$root/third_party/hdmi/tmds_channel.sv"
add_file -type verilog "$root/platform/iosys/gowin_dpb_menu.v"
add_file -type verilog "$root/platform/iosys/iosys.v"
add_file -type verilog "$root/third_party/picorv32/picorv32.v"
add_file -type verilog "$root/platform/iosys/simplespimaster.v"
add_file -type verilog "$root/platform/iosys/simpleuart.v"
add_file -type verilog "$root/platform/iosys/spi_master.v"
add_file -type verilog "$root/platform/iosys/spiflash.v"
add_file -type verilog "$root/systems/snes/cartridge/main.v"
add_file -type verilog "$root/systems/snes/chips/s-ppu/ppu.v"
add_file -type verilog "$root/systems/snes/chips/s-ppu/ppucgram.v"
add_file -type verilog "$root/systems/snes/chips/s-ppu/ppuhoam.v"
add_file -type verilog "$root/systems/snes/chips/s-ppu/ppuoam.v"
add_file -type verilog "$root/systems/snes/cartridge/smc_parser.v"
add_file -type verilog "$root/systems/snes/chips/s-smp/smp.v"
add_file -type verilog "$root/systems/snes/snes.v"
add_file -type verilog "$root/platform/input/controller_adapter.sv"
add_file -type verilog "$root/platform/input/controller_ds2.sv"
add_file -type verilog "$root/platform/input/controller_snes.v"
add_file -type verilog "$root/platform/input/usb_hid_host/usb_hid_host.v"
add_file -type verilog "$root/platform/input/usb_hid_host/usb_hid_host_rom.v"
add_file -type verilog "$root/boards/tang-nano-20k/snes/top.v"
add_file -type verilog "$root/systems/snes/chips/s-smp/spc700/_spc700_package.v"
add_file -type verilog "$root/systems/snes/chips/s-smp/spc700/addrgen.v"
add_file -type verilog "$root/systems/snes/chips/s-smp/spc700/addsub.v"
add_file -type verilog "$root/systems/snes/chips/s-smp/spc700/alu.v"
add_file -type verilog "$root/systems/snes/chips/s-smp/spc700/bcdadj.v"
add_file -type verilog "$root/systems/snes/chips/s-smp/spc700/mcode.v"
add_file -type verilog "$root/systems/snes/chips/s-smp/spc700/muldiv.v"
add_file -type verilog "$root/systems/snes/chips/s-smp/spc700/spc700.v"
add_file -type verilog "$root/systems/snes/chips/s-wram/swram.v"
add_file -type verilog "$root/platform/io/uart_tx_v2.v"

add_file -type cst $::env(RF_CST)
add_file -type sdc "$root/boards/tang-nano-20k/snes/snes.sdc"

set_option -synthesis_tool gowinsynthesis
set_option -top_module snestang_top
set_option -verilog_std sysv2017
set_option -include_path [file dirname $::env(RF_CST)]
set_option -rw_check_on_ram 1
# Placement and routing algorithms chosen for timing. The core fills ~98% of the logic and
# the HDMI encoder path (hclk, 74.25 MHz) has little margin; of the combinations Gowin
# 1.9.11.03 accepts (place 0-2, route 0-2), place 0 with route 2 gives the most: hclk 75.7
# MHz. Small design changes move placement, so check hclk in the timing report after each.
set_option -place_option 0
set_option -route_option 2
set_option -use_mspi_as_gpio 1
set_option -use_sspi_as_gpio 1
set_option -use_ready_as_gpio 1
set_option -use_done_as_gpio 1
set_option -use_i2c_as_gpio 1
set_option -use_cpu_as_gpio 1
set_option -multi_boot 1
set_option -output_base_name $::env(RF_NAME)

run all
