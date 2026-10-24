# Gowin build for the NES core on the Tang Nano 20K (GW2AR-LV18QN88C8/I7).
# Run through build/gowin/gw.sh (see build/Makefile); gw_sh puts impl/ in the current directory.
# File list and options follow nestang v0.12 build.tcl (nano20k), in the same order.

set root [file normalize [file join [file dirname [info script]] .. ..]]

# Set by the makefile (CONTROLLERS): output name, and the pin file it generated in the build
# folder, next to controllers.vh (which config.v includes; that folder is the include path).
foreach v {RF_NAME RF_CST} {
    if {![info exists ::env($v)]} { error "$v not set: build with make (see makefile)" }
}

set_device GW2AR-LV18QN88C8/I7 -device_version C

add_file -type verilog "$root/boards/tang-nano-20k/nes/config.v"
add_file -type verilog "$root/boards/tang-nano-20k/gowin_pll_hdmi.v"
add_file -type verilog "$root/boards/tang-nano-20k/nes/gowin_pll_nes.v"
add_file -type verilog "$root/systems/nes/chips/rp2a03/apu/apu.v"
add_file -type verilog "$root/platform/input/autofire.v"
add_file -type verilog "$root/systems/nes/cartridge/cart.sv"
add_file -type verilog "$root/platform/input/controller_snes.v"
add_file -type verilog "$root/platform/input/controller_ds2.sv"
add_file -type verilog "$root/platform/memory/dpram.v"
add_file -type verilog "$root/platform/input/dualshock_controller.v"
add_file -type verilog "$root/systems/nes/cartridge/eeprom_24c0x.sv"
add_file -type verilog "$root/systems/nes/cartridge/game_loader.v"
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
add_file -type verilog "$root/systems/nes/cartridge/mappers/generic.sv"
add_file -type verilog "$root/systems/nes/cartridge/mappers/iir_filter.v"
add_file -type verilog "$root/systems/nes/cartridge/mappers/jycompany.sv"
add_file -type verilog "$root/systems/nes/cartridge/mappers/misc.sv"
add_file -type verilog "$root/systems/nes/cartridge/mappers/mmc1.sv"
add_file -type verilog "$root/systems/nes/cartridge/mappers/mmc2.sv"
add_file -type verilog "$root/systems/nes/cartridge/mappers/mmc3.sv"
add_file -type verilog "$root/systems/nes/cartridge/mappers/mmc5.sv"
add_file -type verilog "$root/systems/nes/cartridge/mappers/namco.sv"
add_file -type verilog "$root/systems/nes/cartridge/mappers/sachen.sv"
add_file -type verilog "$root/systems/nes/cartridge/mappers/sunsoft.sv"
add_file -type verilog "$root/systems/nes/nes.v"
add_file -type verilog "$root/platform/video/osd.v"
add_file -type verilog "$root/platform/video/video_out.v"
add_file -type verilog "$root/platform/video/nes_video.sv"
add_file -type verilog "$root/boards/tang-nano-20k/nes/top.sv"
add_file -type verilog "$root/systems/nes/chips/rp2c02/ppu.v"
add_file -type verilog "$root/platform/memory/sdram_nes.v"
add_file -type verilog "$root/systems/nes/chips/rp2a03/cpu6502/t65.v"
add_file -type verilog "$root/systems/nes/chips/rp2a03/cpu6502/t65_alu.v"
add_file -type verilog "$root/systems/nes/chips/rp2a03/cpu6502/t65_mcode.v"
add_file -type verilog "$root/systems/nes/chips/rp2a03/cpu6502/t65_pack.v"
add_file -type verilog "$root/platform/io/uart_tx_v2.v"
add_file -type verilog "$root/platform/input/usb_hid_host/usb_hid_host.v"
add_file -type verilog "$root/platform/input/usb_hid_host/usb_hid_host_rom.v"

add_file -type cst $::env(RF_CST)
add_file -type sdc "$root/boards/tang-nano-20k/nes/nes.sdc"

set_option -synthesis_tool gowinsynthesis
set_option -top_module nestang_top
set_option -verilog_std sysv2017
set_option -include_path [file dirname $::env(RF_CST)]
set_option -rw_check_on_ram 1
set_option -place_option 2
set_option -use_mspi_as_gpio 1
set_option -use_sspi_as_gpio 1
set_option -use_ready_as_gpio 1
set_option -use_done_as_gpio 1
set_option -use_i2c_as_gpio 1
set_option -use_cpu_as_gpio 1
set_option -multi_boot 1
set_option -output_base_name $::env(RF_NAME)

run all
