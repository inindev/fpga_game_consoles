
// Modified for retro-fpga (2026-10-23): USB1/USB2 gamepad ports. See git history.
// Modified for retro-fpga (2026-10-24): controller defines come from make (CONTROLLERS). See git history.
`define NANO
`define SDRAM_3CH
`define CHIP_DSPn
// `define CHIP_GSU

// Controllers: CONTROLLER_SNES, CONTROLLER_DS2, USB1, USB2. make writes them to
// controllers.vh in the build folder from CONTROLLERS (default: all); see makefile.
// All controllers built in are OR'd per player.
`include "controllers.vh"

// `define DISABLE_SNES
// `define DISABLE_SMP

package configPackage;  

localparam SDRAM_DATA_WIDTH = 32;
localparam SDRAM_ROW_WIDTH = 11;

endpackage

