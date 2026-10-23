# Gowin build for the USB probe core on the Tang Nano 20K (GW2AR-LV18QN88C8/I7): a diagnostic
# core that prints what the USB gamepad ports receive over the USB-C serial port.
# Run through build/gowin/gw.sh (see the makefile); gw_sh puts impl/ in the current directory.

set root [file normalize [file join [file dirname [info script]] .. ..]]
set_device GW2AR-LV18QN88C8/I7 -device_version C

add_file -type verilog "$root/boards/tang-nano-20k/usb_probe/gowin_pll_usb.v"
add_file -type verilog "$root/boards/tang-nano-20k/snes/gowin_pll_snes.v"
add_file -type verilog "$root/platform/input/usb_hid_host/usb_hid_host.v"
add_file -type verilog "$root/platform/input/usb_hid_host/usb_hid_host_rom.v"
add_file -type verilog "$root/platform/io/uart_tx_v2.v"
add_file -type verilog "$root/boards/tang-nano-20k/usb_probe/top.v"
add_file -type cst "$root/boards/tang-nano-20k/usb_probe/usb_probe.cst"
add_file -type sdc "$root/boards/tang-nano-20k/usb_probe/usb_probe.sdc"

set_option -synthesis_tool gowinsynthesis
set_option -top_module usb_probe_top
set_option -verilog_std sysv2017
set_option -use_mspi_as_gpio 1
set_option -use_sspi_as_gpio 1
set_option -use_ready_as_gpio 1
set_option -use_done_as_gpio 1
set_option -use_i2c_as_gpio 1
set_option -use_cpu_as_gpio 1
set_option -output_base_name usb_probe_nano20k

run all
