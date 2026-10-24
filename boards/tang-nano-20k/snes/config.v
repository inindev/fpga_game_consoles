
// Modified for retro-fpga (2026-10-23): USB1/USB2 gamepad ports. See git history.
// Modified for retro-fpga (2026-10-24): controller and test-pattern defines come from make
// (CONTROLLERS, TEST_PATTERN). See git history.
`define NANO
`define SDRAM_3CH
`define CHIP_DSPn
// `define CHIP_GSU

// Build options, written by make to build.vh in the build folder (see makefile):
// - controllers: CONTROLLER_SNES, CONTROLLER_DS2, USB1, USB2, from CONTROLLERS (default:
//   all). All controllers built in are OR'd per player.
// - VIDEO_TEST_PATTERN, from TEST_PATTERN=1 (see platform/video/video_out.v).
`include "build.vh"

// `define DISABLE_SNES
// `define DISABLE_SMP

package configPackage;  

localparam SDRAM_DATA_WIDTH = 32;
localparam SDRAM_ROW_WIDTH = 11;

endpackage

