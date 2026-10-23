
// Modified for retro-fpga (2026-10-23): USB1/USB2 gamepad ports. See git history.
`define NANO
`define SDRAM_3CH
`define CHIP_DSPn
// `define CHIP_GSU

`define CONTROLLER_DS2
`define CONTROLLER_SNES

// USB gamepads on the pin header (pins and wiring in snes.cst); all controllers are OR'd per player
`define USB1
`define USB2

// `define DISABLE_SNES
// `define DISABLE_SMP

package configPackage;  

localparam SDRAM_DATA_WIDTH = 32;
localparam SDRAM_ROW_WIDTH = 11;

endpackage

