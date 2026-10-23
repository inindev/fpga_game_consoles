// Modified for retro-fpga (2026-10-23): USB1/USB2 gamepad ports. See git history.
`define RES_720P
`define GW_IDE
`define NANO

`define CONTROLLER_SNES
`define CONTROLLER_DS2

// USB gamepads on the pin header (pins and wiring in nes.cst); all controllers are OR'd per player
`define USB1
`define USB2

package configPackage;  

    // total space: 4B * 2K * 256 * 4 = 8MB
    localparam SDRAM_DATA_WIDTH = 32;     // 4 bytes per word
    localparam SDRAM_ROW_WIDTH = 11;      // 2K rows
    localparam SDRAM_COL_WIDTH = 8;       // 256 cols
    localparam SDRAM_BANK_WIDTH = 2;      // 4 banks

endpackage