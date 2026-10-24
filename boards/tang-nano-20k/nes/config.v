// Modified for retro-fpga (2026-10-23): USB1/USB2 gamepad ports. See git history.
// Modified for retro-fpga (2026-10-24): controller and test-pattern defines come from make
// (CONTROLLERS, TEST_PATTERN). See git history.
`define RES_720P
`define GW_IDE
`define NANO

// Build options, written by make to build.vh in the build folder (see makefile):
// - controllers: CONTROLLER_SNES, CONTROLLER_DS2, USB1, USB2, from CONTROLLERS (default:
//   all). All controllers built in are OR'd per player.
// - VIDEO_TEST_PATTERN, from TEST_PATTERN=1 (see platform/video/video_out.v).
`include "build.vh"

package configPackage;  

    // total space: 4B * 2K * 256 * 4 = 8MB
    localparam SDRAM_DATA_WIDTH = 32;     // 4 bytes per word
    localparam SDRAM_ROW_WIDTH = 11;      // 2K rows
    localparam SDRAM_COL_WIDTH = 8;       // 256 cols
    localparam SDRAM_BANK_WIDTH = 2;      // 4 banks

endpackage