# Tang Nano 20K pinout

What each FPGA pin on the Sipeed Tang Nano 20K is physically wired to: header
positions, onboard parts and connectors. It describes the board, not any design. How a
design uses a pin is in that design's `.cst` file.

Each fact has a source tag:

| Tag | Source |
|---|---|
| [sch] | Sipeed schematic: FPGA sheet and circuit sheets |
| [top] | Sipeed schematic, top-level sheet: hierarchical blocks and headers J5/J6 |
| [gw] | Gowin's pin table for the part: `IDE/data/device/GW2AR-18C/QFN88.json` (Gowin IDE 1.9.11.03) |
| [img] | Sipeed's official pinout diagram for the board |
| [wiki] | Sipeed wiki: board page and "Unbox" page |
| [ex] | Sipeed's example constraint files (`TangNano-20K-example`) |

FPGA pin numbers come from the schematic's FPGA sheet. All 66 I/O pin names there
match Gowin's pin table.

Some sources disagree in places: a few circuit-sheet net labels and a few details on the
pinout image. These are listed in [Source disagreements](#source-disagreements).

## Board summary

| Item | Detail | Source |
|---|---|---|
| FPGA | Gowin GW2AR-LV18QN88C8/I7 (IC1, QFN88) | [sch] |
| SDRAM | 64 Mbit, 32-bit SDR, inside the FPGA package; no board pins | [wiki] |
| SPI flash | XT25F64FWOIGT (U2), 64 Mbit, on the FPGA's MSPI pins | [sch] |
| Main clock | 27 MHz oscillator module (U3) to FPGA pin 4 | [sch] |
| Clock generator | MS5351M (U12), own 25 MHz crystal, 3 outputs to FPGA pins 10, 11, 13; set over I2C by the BL616 | [sch] |
| Debugger MCU | BL616C-50 (U5), 40 MHz crystal: USB, JTAG, UART and SPI to the FPGA; I2C to the MS5351 | [sch] |
| Audio amplifier | MAX98357AEWL+T (IC3), I2S DAC + class-D amp, 5 V; speaker pads J4 | [sch] |
| LEDs | 6 orange, active low | [sch] |
| RGB LED | WS2812B-2020 (U1), powered from 5 V | [sch] |
| Storage | TF (microSD) socket J7, no card detect | [sch] |
| Display | HDMI connector J3; 40-pin RGB LCD FPC connector | [sch] |
| Buttons | S1 (pin 88), S2 (pin 87), both active high; SW4 is the BL616 boot button | [sch] |
| Power and USB | USB-C J1: VBUS through a 2 A fuse to +5V; USB data to the BL616 only | [sch] |
| Regulators | +5V to +3V3 and +1V0 (MT3520B bucks); separate 3.3 V LDOs (ME6211C33) for I/O banks 4 and 5 | [sch] |
| Headers | J6 (left) and J5 (right), 20 pins each | [sch] [img] |

## FPGA pin map

Every pin of IC1.

- **Name, bank and special function:** from [gw]. They match the schematic symbol.
- **Net:** the schematic net at the pin [sch].
- **Header:** L = left (J6), R = right (J5), then the position.
- **TL:** marks a true-LVDS-capable pin [gw].

| Pin | Name | Bank | Special function | TL | Net | Wired to | Header |
|---|---|---|---|---|---|---|---|
| 1 | VCC | | Core supply | | +1V0 | | |
| 2 | VSS | | Ground | | GND | | |
| 3 | VCCIO2/6/7, VCCX | | Bank 2/6/7 I/O and aux supply | | +3V3 | | |
| 4 | IOL7A | 7 | LPLL1_T_IN | | `PIN04_SYS_CLK` | 27 MHz oscillator U3 (via R10 22 Ω) | |
| 5 | IOR25B | 2 | TMS | | `PIN05_SYS_TMS` | BL616 JTAG; TP6 | |
| 6 | IOR26A | 2 | TCK | TL | `PIN06_SYS_TCK` | BL616 JTAG; TP3; R5 4.7 kΩ to GND | |
| 7 | IOR26B | 2 | TDI | TL | `PIN07_SYS_TDI` | BL616 JTAG; TP5 | |
| 8 | IOR25A | 2 | TDO | | `PIN08_SYS_TDO` | BL616 JTAG; TP4; R1 4.7 kΩ to +3V3 | |
| 9 | IOR31B | 3 | RECONFIG_N | TL | `PIN09_SYS_RECFG` | TP1 only | |
| 10 | IOL29A | 6 | GCLKT_6 | TL | `PIN10_5351CKP` | MS5351 CLK0 | |
| 11 | IOL29B | 6 | GCLKC_6 | TL | `PIN11_5351CKN` | MS5351 CLK1 | |
| 12 | VCCIO2/6/7, VCCX | | Bank 2/6/7 I/O and aux supply | | +3V3 | | |
| 13 | IOL45A | 6 | LPLL2_T_IN | | `PIN13_SPI_SCLK` | MS5351 CLK2 **and** BL616 SPI_SCLK | |
| 14 | VCCPLLL1 | | Left PLL supply | | `VCCPLLL` | | |
| 15 | IOL47A | 6 | LPLL2_T_FB | TL | `PIN15_SYS_LED0` | LED0 | L6 |
| 16 | IOL47B | 6 | LPLL2_C_FB | TL | `PIN16_SYS_LED1` | LED1 | L7 |
| 17 | IOL49A | 6 | | TL | `PIN17_SYS_LED2` | LED2 | L15 |
| 18 | IOL49B | 6 | | TL | `PIN18_SYS_LED3` | LED3 | L18 |
| 19 | IOL51A | 6 | | TL | `PIN19_SYS_LED4` | LED4 | L17 |
| 20 | IOL51B | 6 | | TL | `PIN20_SYS_LED5` | LED5 | L16 |
| 21 | VSS | | Ground | | GND | | |
| 22 | VCC | | Core supply | | +1V0 | | |
| 23 | VCCIO5 | | Bank 5 I/O supply | | `VCCO_5`, 3.3 V from U11 (C3 100 nF) | | |
| 24 | VSS | | Ground | | GND | | |
| 25 | IOB6A | 5 | | TL | `PIN25_LCD_HS` | LCD HSYNC; HDMI CEC (via R51 100 Ω) | L10 |
| 26 | IOB6B | 5 | | TL | `PIN26_LCD_VS` | LCD VSYNC; HDMI HPD (divider, 5.1 kΩ to GND) | L11 |
| 27 | IOB8A | 5 | | TL | `PIN27_LCD_B7` | LCD B7 | L8 |
| 28 | IOB8B | 5 | | TL | `PIN28_LCD_B6` | LCD B6 | L9 |
| 29 | IOB14A | 5 | | TL | `PIN29_LCD_B5` | LCD B5 | L12 |
| 30 | IOB14B | 5 | | TL | `PIN30_LCD_B4` | LCD B4 | L13 |
| 31 | IOB18A | 5 | | TL | `PIN31_LCD_B3` | LCD B3 | L14 |
| 32 | IOB18B | 5 | | TL | `PIN32_LCD_G7` | LCD G7 | |
| 33 | IOB24A | 5 | | TL | `DVI_TXC_P` | HDMI CK+; LCD G6 | |
| 34 | IOB24B | 5 | | TL | `DVI_TXC_N` | HDMI CK-; LCD G5 | |
| 35 | IOB30A | 4 | GCLKT_4 | TL | `DVI_TX0_P` | HDMI D0+; LCD G4 | |
| 36 | IOB30B | 4 | GCLKC_4 | TL | `DVI_TX0_N` | HDMI D0-; LCD G3 | |
| 37 | IOB34A | 4 | | TL | `DVI_TX1_P` | HDMI D1+; LCD G2 | |
| 38 | IOB34B | 4 | | TL | `DVI_TX1_N` | HDMI D1-; LCD R7 | |
| 39 | IOB40A | 4 | | TL | `DVI_TX2_P` | HDMI D2+; LCD R6 | |
| 40 | IOB40B | 4 | | TL | `DVI_TX2_N` | HDMI D2-; LCD R5 | |
| 41 | IOB43A | 4 | | | `PIN41_LCD_R4` | LCD R4 | R6 |
| 42 | IOB42B | 4 | | TL | `PIN42_LCD_R3` | LCD R3 | R5 |
| 43 | VSS | | Ground | | GND | | |
| 44 | VCCIO4 | | Bank 4 I/O supply | | `VCCO_4`, 3.3 V from U4 (C5 100 nF) | | |
| 45 | VCC | | Core supply | | +1V0 | | |
| 46 | VSS | | Ground | | GND | | |
| 47 | EXTR | | External reference resistor | | | R11 10 kΩ to GND | |
| 48 | IOR49B | 3 | | TL | `PIN48_LCD_DE` | LCD DEN | R10 |
| 49 | IOR49A | 3 | | TL | `PIN49_LCD_BL` | LCD backlight enable | R12 |
| 50 | VCCPLLR1 | | Right PLL supply | | `VCCPLLR` | | |
| 51 | IOR45A | 3 | RPLL2_T_IN | | `PIN51_PA_SD/EN` | Amplifier SD_MODE (enable) | R9 |
| 52 | IOR39A | 3 | SCLK | | `PIN52_DCD_DAT` | HDMI DDC data (level shifter, 2.2 kΩ pull-up) | R20 |
| 53 | IOR38B | 3 | DOUT/WE_N | TL | `PIN53_DCD_CLK` | HDMI DDC clock (level shifter, 2.2 kΩ pull-up) | R19 |
| 54 | IOR38A | 3 | DIN/CLKHOLD_N | TL | `PIN54_I2S_DIN` | Amplifier DIN | R8 |
| 55 | IOR36B | 3 | SSPI_CS_N/D0 | | `PIN55_I2S_LRCK` | Amplifier LRCLK | R11 |
| 56 | IOR36A | 3 | SO/D1 | | `PIN56_I2S_BCLK` | Amplifier BCLK | R7 |
| 57 | IOR35A | 3 | FASTRD_N/D3 | TL | `MSPI_WP` | Flash WP# (R2 4.7 kΩ to +3V3) | |
| 58 | VCCIO3 | | Bank 3 I/O supply | | +3V3 | | |
| 59 | IOR34B | 3 | MCLK/D4 | | `MSPI_CLK` | Flash CLK (via R8 0 Ω); R4 1 kΩ to GND | |
| 60 | IOR34A | 3 | MCS_N/D5 | | `MSPI_CS` | Flash CS# (R3 4.7 kΩ to +3V3) | |
| 61 | IOR33B | 3 | MO/D6 | TL | `MSPI_DI` | Flash DI | |
| 62 | IOR33A | 3 | MI/D7 | TL | `MSPI_DO` | Flash DO | |
| 63 | IOR29A | 3 | GCLKT_3 | TL | `MSPI_HOLD` | Flash HOLD# (R9 4.7 kΩ to +3V3) | |
| 64 | VCCIO2/6/7, VCCX | | Bank 2/6/7 I/O and aux supply | | +3V3 | | |
| 65 | VSS | | Ground | | GND | | |
| 66 | VCC | | Core supply | | +1V0 | | |
| 67 | VCCIO1 | | Bank 1 I/O supply | | +3V3 | | |
| 68 | VSS | | Ground | | GND | | |
| 69 | IOT50A | 1 | | TL | `PIN69_SYS_TX` | BL616 UART RX (FPGA transmits) | |
| 70 | IOT44B | 1 | | TL | `PIN70_SYS_RX` | BL616 UART TX (FPGA receives) | |
| 71 | IOT44A | 1 | | TL | `PIN71_HSPI_D0` | Header only | R18 |
| 72 | IOT40B | 1 | | TL | `PIN72_HSPI_D1` | Header only | R17 |
| 73 | IOT40A | 1 | | TL | `PIN73_HSPI_D2` | Header only | L1 |
| 74 | IOT34B | 1 | | TL | `PIN74_HSPI_D3` | Header only | L2 |
| 75 | IOT34A | 1 | | TL | `PIN75_SPI_MISO` | BL616 SPI_MISO | L3 |
| 76 | IOT30B | 1 | GCLKC_1 | TL | `PIN76_SPI_MOSI` | BL616 SPI_MOSI | R3 |
| 77 | IOT30A | 1 | GCLKT_1 | TL | `PIN77_LCD_CK` | LCD CLK | L5 |
| 78 | VCCIO0 | | Bank 0 I/O supply | | +3V3 | | |
| 79 | IOT27B | 0 | GCLKC_0 | | `PIN79_WS2812` | WS2812 DIN (via R60 100 Ω, R52 5.1 kΩ to GND) | R14 |
| 80 | IOT27A | 0 | GCLKT_0 | | `PIN80_SDIO_D2` | TF card DAT2 (10 kΩ pull-up) | R4 |
| 81 | IOT17B | 0 | | | `PIN81_SDIO_D3` | TF card DAT3 (10 kΩ pull-up) | |
| 82 | IOT17A | 0 | | | `PIN82_SDIO_CMD` | TF card CMD (10 kΩ pull-up) | |
| 83 | IOT6B | 0 | | TL | `PIN83_SDIO_CLK` | TF card CLK (via R49 22 Ω) | |
| 84 | IOT6A | 0 | | TL | `PIN84_SDIO_D0` | TF card DAT0 (10 kΩ pull-up) | |
| 85 | IOT4B | 0 | | TL | `PIN85_SDIO_D1` | TF card DAT1 (10 kΩ pull-up) | L4 |
| 86 | IOT4A | 0 | | TL | `PIN86_SPI_DIR` | BL616 SPI_DIR | R13 |
| 87 | IOR30B | 3 | MODE1 | | `PIN87_MODE1_KEY2` | Button S2; R7 1 kΩ to GND | |
| 88 | IOR30A | 3 | MODE0 | | `PIN88_MODE0_KEY1` | Button S1; R6 1 kΩ to GND | |
| 89 | EPAD | | Exposed pad | | GND | | |

- **Pins on the headers:** 34 FPGA pins. See [Headers](#headers).

## Power and banks

| Supply pins | Rail | Source |
|---|---|---|
| VCC (core): 1, 22, 45, 66 | +1V0 | [sch] |
| VCCIO2/6/7 + VCCX: 3, 12, 64 | +3V3 | [sch] |
| VCCIO0: 78 | +3V3 | [sch] |
| VCCIO1: 67 | +3V3 | [sch] |
| VCCIO3: 58 | +3V3 | [sch] |
| VCCIO4: 44 | `VCCO_4`, 3.3 V from its own regulator U4 | [sch] |
| VCCIO5: 23 | `VCCO_5`, 3.3 V from its own regulator U11 | [sch] |
| VCCPLLL1: 14, VCCPLLR1: 50 | `VCCPLLL`, `VCCPLLR` | [sch] |

| Bank | Pins | Supply | Voltage |
|---|---|---|---|
| 0 | 79–86 | +3V3 | 3.3 V |
| 1 | 69–77 | +3V3 | 3.3 V |
| 2 | 5–8 (JTAG) | +3V3 | 3.3 V |
| 3 | 9, 48–49, 51–57, 59–63, 87, 88 | +3V3 | 3.3 V |
| 4 | 35–42 | `VCCO_4` (U4) | 3.3 V |
| 5 | 25–34 | `VCCO_5` (U11) | 3.3 V |
| 6 | 10, 11, 13, 15–20 | +3V3 | 3.3 V |
| 7 | 4 | +3V3 | 3.3 V |

Every I/O bank is 3.3 V. Banks 4 and 5 (pins 25–42: HDMI TMDS, LCD data, HSYNC/VSYNC)
have their own regulators instead of sharing the main +3V3 rail.

### Regulators

All regulators run from the board's +5V rail (fused USB VBUS) [sch].

| Ref | Part | Output | Type | Details |
|---|---|---|---|---|
| U9 | MT3520B | +3V3 | Buck | L1 2.2 µH (0806); C11 10 µF in, C23 22 µF out; FB2 ferrite bead (MPZ1608S101ATAH0) to the +3V3 rail; feedback R17 68 kΩ / R18 15 kΩ |
| U10 | MT3520B | +1V0 (FPGA core) | Buck | L2 2.2 µH (0806); C12 10 µF in, C24 22 µF out; FB3 ferrite bead (MPZ1608S101ATAH0) to the +1V0 rail; feedback R19 10 kΩ / R20 15 kΩ |
| U4 | ME6211C33 | `VCCO_4` (3.3 V) | LDO | C6 100 nF in, C41 100 nF out; output pin 5; NC pin 4 |
| U11 | ME6211C33 | `VCCO_5` (3.3 V) | LDO | C50 100 nF in, C52 100 nF out; output pin 5; NC pin 4 |

- **Always on:** each regulator's enable (EN or CE) is tied to its input, so it runs
  whenever +5V is present.
- **LDO voltage:** the ME6211's output voltage comes from the part number ("C33" =
  3.3 V).
- **Buck voltages:** the rails are named +3V3 and +1V0. Both feedback dividers fit a
  0.6 V reference: 0.6 × (1 + 68/15) ≈ 3.32 V and 0.6 × (1 + 10/15) = 1.00 V. The 0.6 V
  figure is inferred from the dividers, not read from the datasheet.

## Headers

Diagram orientation: USB-C at the top, HDMI at the bottom, components facing you.
Position 1 is at the USB-C end.

- **Name, bank, net:** from [gw] and [sch].
- **Pinout label:** what Sipeed's pinout image calls the pin [img]. It differs from the
  schematic for the SPI pins.

### Left header (J6)

| Pos | Pin | Name | Bank | Net | Pinout label | Wired to |
|---|---|---|---|---|---|---|
| 1 | 73 | IOT40A | 1 | `PIN73_HSPI_D2` | HSPI_DIN2 | Header only |
| 2 | 74 | IOT34B | 1 | `PIN74_HSPI_D3` | HSPI_DIN3 | Header only |
| 3 | 75 | IOT34A | 1 | `PIN75_SPI_MISO` | HSPI_DIR | BL616 SPI_MISO |
| 4 | 85 | IOT4B | 0 | `PIN85_SDIO_D1` | SDIO_D1 | TF card DAT1 |
| 5 | 77 | IOT30A | 1 | `PIN77_LCD_CK` | LCD_CLK | LCD CLK |
| 6 | 15 | IOL47A | 6 | `PIN15_SYS_LED0` | LED0 | LED0 |
| 7 | 16 | IOL47B | 6 | `PIN16_SYS_LED1` | LED1 | LED1 |
| 8 | 27 | IOB8A | 5 | `PIN27_LCD_B7` | LCD_B7 | LCD B7 |
| 9 | 28 | IOB8B | 5 | `PIN28_LCD_B6` | LCD_B6 | LCD B6 |
| 10 | 25 | IOB6A | 5 | `PIN25_LCD_HS` | LCD_HS | LCD HSYNC, HDMI CEC |
| 11 | 26 | IOB6B | 5 | `PIN26_LCD_VS` | LCD_VS | LCD VSYNC, HDMI HPD |
| 12 | 29 | IOB14A | 5 | `PIN29_LCD_B5` | LCD_B5 | LCD B5 |
| 13 | 30 | IOB14B | 5 | `PIN30_LCD_B4` | LCD_B4 | LCD B4 |
| 14 | 31 | IOB18A | 5 | `PIN31_LCD_B3` | LCD_B3 | LCD B3 |
| 15 | 17 | IOL49A | 6 | `PIN17_SYS_LED2` | LED2 | LED2 |
| 16 | 20 | IOL51B | 6 | `PIN20_SYS_LED5` | LED5 | LED5 |
| 17 | 19 | IOL51A | 6 | `PIN19_SYS_LED4` | LED4 | LED4 |
| 18 | 18 | IOL49B | 6 | `PIN18_SYS_LED3` | LED3 | LED3 |
| 19 | — | — | — | +3V3 | 3V3 | |
| 20 | — | — | — | GND | GND | |

The LEDs run LED2, LED5, LED4, LED3 at positions 15–18 (pins 17, 20, 19, 18). They are
not in order. Some LED pins also carry LCD touch lines; see
[RGB LCD connector](#rgb-lcd-connector).

### Right header (J5)

| Pos | Pin | Name | Bank | Net | Pinout label | Wired to |
|---|---|---|---|---|---|---|
| 1 | — | — | — | +5V | 5V | Fused USB 5 V |
| 2 | — | — | — | GND | GND | |
| 3 | 76 | IOT30B | 1 | `PIN76_SPI_MOSI` | HSPI_DAT | BL616 SPI_MOSI |
| 4 | 80 | IOT27A | 0 | `PIN80_SDIO_D2` | SDIO_D2 | TF card DAT2 |
| 5 | 42 | IOB42B | 4 | `PIN42_LCD_R3` | LCD_R3 | LCD R3 |
| 6 | 41 | IOB43A | 4 | `PIN41_LCD_R4` | LCD_R4 | LCD R4 |
| 7 | 56 | IOR36A | 3 | `PIN56_I2S_BCLK` | I2S_BCLK | Amplifier BCLK |
| 8 | 54 | IOR38A | 3 | `PIN54_I2S_DIN` | I2S_DIN | Amplifier DIN |
| 9 | 51 | IOR45A | 3 | `PIN51_PA_SD/EN` | PA_EN | Amplifier enable |
| 10 | 48 | IOR49B | 3 | `PIN48_LCD_DE` | LCD_DE | LCD DEN |
| 11 | 55 | IOR36B | 3 | `PIN55_I2S_LRCK` | I2S_LRCK | Amplifier LRCLK |
| 12 | 49 | IOR49A | 3 | `PIN49_LCD_BL` | LCD_BL | LCD backlight enable |
| 13 | 86 | IOT4A | 0 | `PIN86_SPI_DIR` | HSPI_CSN | BL616 SPI_DIR |
| 14 | 79 | IOT27B | 0 | `PIN79_WS2812` | 2812_DIN | WS2812 DIN |
| 15 | — | — | — | GND | GND | |
| 16 | — | — | — | +3V3 | 3V3 | |
| 17 | 72 | IOT40B | 1 | `PIN72_HSPI_D1` | HSPI_DIN1 | Header only |
| 18 | 71 | IOT44A | 1 | `PIN71_HSPI_D0` | HSPI_DIN0 | Header only |
| 19 | 53 | IOR38B | 3 | `PIN53_DCD_CLK` | EDID_CLK | HDMI DDC clock |
| 20 | 52 | IOR39A | 3 | `PIN52_DCD_DAT` | EDID_DAT | HDMI DDC data |

- **5V pin:** the board's +5V rail, on the fused side of FU1.
- **3V3 pins:** the +3V3 rail.

### Clock-capable pins on the headers

| Pin | Function [gw] | Header | Notes |
|---|---|---|---|
| 77 | GCLKT_1 | L5 | Global clock, true side |
| 76 | GCLKC_1 | R3 | Global clock, complement side (pairs with 77) |
| 80 | GCLKT_0 | R4 | Global clock, true side |
| 79 | GCLKC_0 | R14 | Global clock, complement side (pairs with 80) |
| 15 | LPLL2_T_FB | L6 | Left PLL 2 feedback, true side |
| 16 | LPLL2_C_FB | L7 | Left PLL 2 feedback, complement side |
| 51 | RPLL2_T_IN | R9 | Right PLL 2 input |

The pinout image labels pins 15/16 `LPLL2_T`/`LPLL2_C`. Gowin calls them PLL feedback
pins; PLL 2's input is pin 13, off the headers.

## Onboard circuits

### Clocks

| Pin | Function [gw] | Source | Net |
|---|---|---|---|
| 4 | LPLL1_T_IN | 27 MHz oscillator U3 | `PIN04_SYS_CLK` |
| 10 | GCLKT_6 | MS5351 CLK0 | `PIN10_5351CKP` / `SYS_GCLK6_P` |
| 11 | GCLKC_6 | MS5351 CLK1 | `PIN11_5351CKN` / `SYS_GCLK6_N` |
| 13 | LPLL2_T_IN | MS5351 CLK2 **and** BL616 SPI_SCLK | `PIN13_SPI_SCLK` / `SYS_LPLL2_in` |

#### 27 MHz oscillator (U3)

| U3 pin | Signal | Connection |
|---|---|---|
| 1 | EN | +3V3 (always on) |
| 2 | GND | GND |
| 3 | OUT | R10 22 Ω to FPGA pin 4 |
| 4 | VCC | +3V3, C4 100 nF to GND |

Sipeed's wiki calls this a crystal; the schematic shows an oscillator module.

#### MS5351 clock generator (U12)

| U12 pin | Signal | Connection |
|---|---|---|
| 1 | VDD | +3V3, C64 100 nF to GND |
| 7 | VDDO | +3V3 (output supply) |
| 8 | GND | GND |
| 2, 3 | XA, XB | Y1 25 MHz crystal (`EX_PLL_XI`, `EX_PLL_XO`), C65/C66 10 pF to GND |
| 4 | SCL | `5351_IIC_SCL`, to BL616 GPIO_22 |
| 5 | SDA | `5351_IIC_SDA`, to BL616 GPIO_21 |
| 10 | CLK0 | FPGA pin 10 |
| 9 | CLK1 | FPGA pin 11 |
| 6 | CLK2 | FPGA pin 13 (shared with BL616 SPI_SCLK) |

- **CLK0/CLK1:** wired to the true and complement sides of one global clock pair
  (GCLK6), so they can be used as a differential pair or as two single clocks.
- **Control:** the I2C lines go only to the BL616. The BL616 sets the clocks with the
  `pll_clk` command in its terminal [wiki].
- **Pin 13 is shared:** MS5351 CLK2 and BL616 GPIO_1 (`SPI_SCLK`) are both wired to it
  [sch]. Only one of them should drive it at a time; keep the other off (CLK2 can be
  turned off with `pll_clk O2` [wiki]).

### Configuration and JTAG

| Pin | Function [gw] | Connection |
|---|---|---|
| 5 | TMS | BL616 `JTAG_TMS` (GPIO_16), TP6 |
| 6 | TCK | BL616 `JTAG_TCK` (GPIO_10), TP3, R5 4.7 kΩ to GND |
| 7 | TDI | BL616 `JTAG_TDI` (GPIO_12), TP5 |
| 8 | TDO | BL616 `JTAG_TDO` (GPIO_14), TP4, R1 4.7 kΩ to +3V3 |
| 9 | RECONFIG_N | TP1 only (TP2 is GND) |
| 87 | MODE1 | Button S2, R7 1 kΩ to GND |
| 88 | MODE0 | Button S1, R6 1 kΩ to GND |
| 47 | EXTR | R11 10 kΩ to GND |
| 52–56 | SCLK, DOUT/WE_N, DIN/CLKHOLD_N, SSPI_CS_N/D0, SO/D1 | HDMI DDC and amplifier I2S |
| 57, 59–63 | FASTRD_N/D3, MCLK, MCS_N, MO, MI, (GCLKT_3) | SPI flash |

- **MODE0/MODE1 at power-up:** the 1 kΩ pull-downs hold both low. Pressing S1 or S2
  during power-up changes them; check Gowin's GW2AR documentation for what that does.
- **Configuration functions on pins 52–56:** these are on the HDMI DDC and amplifier
  lines. Their configuration roles matter only in configuration modes that use them.
- **Test points:** TP1–TP6 bring out RECONFIG_N, GND and the four JTAG lines.

### SPI flash (U2)

XT25F64FWOIGT, 64 Mbit, on the FPGA's master-SPI configuration pins [sch].

| U2 pin | Signal | FPGA pin | Net | Extra |
|---|---|---|---|---|
| 1 | CS# | 60 (MCS_N) | `MSPI_CS` | R3 4.7 kΩ to +3V3 |
| 2 | DO (IO1) | 62 (MI) | `MSPI_DO` | |
| 3 | WP# (IO2) | 57 (FASTRD_N/D3) | `MSPI_WP` | R2 4.7 kΩ to +3V3 |
| 4 | GND | | GND | |
| 5 | DI (IO0) | 61 (MO) | `MSPI_DI` | |
| 6 | CLK | 59 (MCLK) | `MSPI_CLK` | R8 0 Ω in series; R4 1 kΩ to GND |
| 7 | HOLD# (IO3) | 63 | `MSPI_HOLD` | R9 4.7 kΩ to +3V3 |
| 8 | VCC | | +3V3 | C2 100 nF to GND |

The flash pins aren't on the headers.

### Buttons

| Pin | Net | Button |
|---|---|---|
| 88 (MODE0) | `PIN88_MODE0_KEY1` → `KEY_S1` | S1 |
| 87 (MODE1) | `PIN87_MODE1_KEY2` → `KEY_S2` | S2 |

```
+3V3 ── R 330Ω ── S1 ──┬── KEY_S1 ──┬── FPGA pin 88
                      │            │
                 C 100nF      R6 1kΩ
                      │            │
                     GND          GND
```

S2 is the same circuit, through R44, C25 and R7 to pin 87.

| Part | S1 | S2 |
|---|---|---|
| Series resistor | R43, 330 Ω | R44, 330 Ω |
| Capacitor to GND | C15, 100 nF | C25, 100 nF |
| Pull-down (FPGA sheet) | R6, 1 kΩ | R7, 1 kΩ |

- **Active high:** released, the pin is held low by the 1 kΩ pull-down.
- **Pressed voltage (calculated):** about 3.3 × 1000 / 1330 ≈ 2.5 V at the pin.
- **Debounce:** the resistor and capacitor give some hardware debounce. Still debounce
  in logic.

### LEDs

Each LED runs from +3V3 through the LED and a 510 Ω resistor to its FPGA pin. Driving
the pin low turns it on [sch].

| Pin | Net | Resistor | LED | Header |
|---|---|---|---|---|
| 15 | `PIN15_SYS_LED0` | R12 510 Ω | LED0 (orange) | L6 |
| 16 | `PIN16_SYS_LED1` | R13 510 Ω | LED1 (orange) | L7 |
| 17 | `PIN17_SYS_LED2` | R14 510 Ω | LED2 (orange) | L15 |
| 18 | `PIN18_SYS_LED3` | R15 510 Ω | LED3 (orange) | L18 |
| 19 | `PIN19_SYS_LED4` | R16 510 Ω | LED4 (orange) | L17 |
| 20 | `PIN20_SYS_LED5` | R28 510 Ω | LED5 (orange) | L16 |

- **External loads:** each LED pin has an LED and 510 Ω path to +3V3. Anything else
  connected to these pins (header, LCD touch lines) sees it.
- **Idle state:** with the pin released (high-impedance), the LED path pulls it toward
  3.3 V minus the LED's forward drop.

### WS2812 RGB LED (U1)

WS2812B-2020 on FPGA pin 79 [sch]:

| U1 pin | Signal | Connection |
|---|---|---|
| 4 | VDD | +5V |
| 2 | VSS | GND |
| 3 | DIN | R60 100 Ω in series from pin 79's net. R52 5.1 kΩ from that net to GND (pull-down) |
| 1 | DOUT | Net `WS2812_DOUT` (no other connection shown) |

- **Logic levels:** the LED runs from 5 V while the FPGA drives 3.3 V. Check the
  WS2812B datasheet's input-high threshold at 5 V before relying on it.

### Audio amplifier (IC3)

MAX98357AEWL+T: an I2S DAC and class-D amplifier in one chip, powered from +5V [sch].

| FPGA pin | Net | IC3 pin | Signal |
|---|---|---|---|
| 56 | `PIN56_I2S_BCLK` | C1 | BCLK |
| 55 | `PIN55_I2S_LRCK` | C3 | LRCLK |
| 54 | `PIN54_I2S_DIN` | B1 | DIN |
| 51 | `PIN51_PA_SD/EN` | A1 (via R45 0 Ω) | SD_MODE (low = shutdown) |

| IC3 pin | Signal | Connection |
|---|---|---|
| A2 | VDD | +5V, C67 10 µF and C68 100 nF to GND |
| B2 | GAIN_SLOT | +5V (sets the gain; see the datasheet) |
| C2 | GND | GND |
| A3 | OUTP | `AUDIO_OUTP` to J4 pin 1 |
| B3 | OUTN | `AUDIO_OUTN` to J4 pin 2 |

- **Enable net:** C14, from the enable net to GND, is marked NC (not fitted).
- **Speaker pads:** J4 is the pair of oval pads marked `SPEAKER_P` / `SPEAKER_N` on the
  pinout image, just inside the right header beside the FPGA. The upper pad is P (OUTP)
  and the lower is N (OUTN). They are not FPGA I/O. The speaker connects directly across
  them.

### TF (microSD) card (J7)

Micro_SD_Card_Det socket [sch].

| FPGA pin | J7 pin | Signal | Pull-up (to +3V3) | Series | Header |
|---|---|---|---|---|---|
| 83 | 5 | CLK | none | R49 22 Ω | |
| 82 | 3 | CMD | R55 10 kΩ | | |
| 84 | 7 | DAT0 | R56 10 kΩ | | |
| 85 | 8 | DAT1 | R57 10 kΩ | | L4 |
| 80 | 1 | DAT2 | R53 10 kΩ | | R4 |
| 81 | 2 | DAT3/CD | R54 10 kΩ | | |

| J7 pin | Signal | Connection |
|---|---|---|
| 4 | VDD | +3V3, with C26 4.7 µF to GND |
| 6 | VSS | GND |
| 9, 10 | DET_B, DET_A | Both tied to GND. Card detect does not reach the FPGA |
| 11 | SHIELD | GND |

### HDMI connector (J3)

On the "DVI TX" sheet [sch].

| FPGA pin | FPGA-side net | Path | J3 pin | J3 signal |
|---|---|---|---|---|
| 33 / 34 | `DVI_TXC_P` / `_N` | C61/C62, U8 | 10 / 12 | CK+ / CK- |
| 35 / 36 | `DVI_TX0_P` / `_N` | C59/C60, U8 | 7 / 9 | D0+ / D0- |
| 37 / 38 | `DVI_TX1_P` / `_N` | C57/C58, U7 | 4 / 6 | D1+ / D1- |
| 39 / 40 | `DVI_TX2_P` / `_N` | C55/C56, U7 | 1 / 3 | D2+ / D2- |
| 53 | `PIN53_DCD_CLK` | Level shifter Q1A | 15 | SCL (DDC/EDID clock) |
| 52 | `PIN52_DCD_DAT` | Level shifter Q1B | 16 | SDA (DDC/EDID data) |
| 25 | `PIN25_LCD_HS` | R51 100 Ω | 13 | CEC |
| 26 | `PIN26_LCD_VS` | Divider R47/R46 | 19 | HPD (hot-plug detect) |

The schematic spells DDC as "DCD" in its net names. This document uses its names as
printed.

#### TMDS lanes

- **True-LVDS pairs:** all four pairs (33/34 to 39/40) are true-LVDS-capable [gw].
- **Banks:** pins 33/34 are in bank 5; 35–40 are in bank 4.
- **AC-coupled:** a 100 nF series capacitor on each line (C55–C62).
- **ESD protection:** RCLAMP0524P arrays (U7: D2, D1; U8: D0, CK), wired straight
  through (IN to OUT) with GND on pins 3 and 8.
- **499 Ω 1% to GND** on each line on the connector side of the capacitors (R32–R39).

#### DDC (EDID) level shifter

FPGA side 3.3 V, connector side 5 V, through a dual N-MOSFET (Q1, 2N7002KD) with gates
tied to +3.3V:

| Line | FPGA side | MOSFET | Connector side |
|---|---|---|---|
| Clock | `DCD_CLK`, R48 2.2 kΩ to +3.3V | Q1A (gate 2, pins 1 → 6) | `DVI_DCD_CLK`, R41 2.2 kΩ to +5VD |
| Data | `DCD_DAT`, R50 2.2 kΩ to +3.3V | Q1B (gate 5, pins 4 → 3) | `DVI_DCD_DAT`, R42 2.2 kΩ to +5VD |

So pins 52 and 53 each have a 2.2 kΩ pull-up to 3.3 V on the board.

#### CEC and HPD

- **CEC:** FPGA pin 25 connects to J3 pin 13 through R51 (100 Ω). `DVI_CEC` has R40
  (27 kΩ 1%) pull-up to +3.3V.
- **HPD:** J3 pin 19 reaches FPGA pin 26 through R47 (2.2 kΩ). R46 (5.1 kΩ) goes from the
  pin-26 side to GND, and D8 (TVS) from HPD to GND. So pin 26 has a 5.1 kΩ pull-down on
  the board.
- **HPD voltage (calculated):** a 5 V HPD from the display gives about
  5 × 5.1 / 7.3 ≈ 3.5 V at pin 26.

#### Connector power and shields

- **+5V (pin 18):** fed by +5VD.
- **D4:** a TVS diode with C63 (100 nF/16 V), both from +5VD to GND.
- **Shield and ground pins:** D2S (2), D1S (5), D0S (8), CKS (11) and GND (17) go to GND.
- **Not connected:** UTILITY (14) and the shell (SH) are both marked no-connect.
- **Rails:** the sheet uses its own rail names, each fed through an LMBR4010BST5G
  Schottky diode: `+5VD` from `+5V` (D5) and `+3.3V` from `+3V3` (D3).
- **Diode direction (inferred):** from the usual layout, not read from the sheet, the
  diodes point toward the HDMI side, so the display can't back-power the board.

### RGB LCD connector

FPC-40-0.5mm, on the "RGB LCD" sheet [sch].

- **Color depth:** the connector has 24-bit color pins, but only the top bits are wired
  (R7–R3, G7–G2, B7–B3: 16-bit RGB565).
- **Unused low bits:** R0–R2, G0–G1 and B0–B2 are tied to GND.

| FPC pin | Signal | FPGA pin | Also wired to | Header |
|---|---|---|---|---|
| 1 | LEDK | | VLED- (backlight driver) | |
| 2 | LEDA | | VLED+ (backlight driver) | |
| 3 | GND | | GND | |
| 4 | VCC | | +3V3 | |
| 5–7 | R0–R2 | | GND | |
| 8 | R3 | 42 | | R5 |
| 9 | R4 | 41 | | R6 |
| 10 | R5 | 40 | HDMI D2- | |
| 11 | R6 | 39 | HDMI D2+ | |
| 12 | R7 | 38 | HDMI D1- | |
| 13–14 | G0–G1 | | GND | |
| 15 | G2 | 37 | HDMI D1+ | |
| 16 | G3 | 36 | HDMI D0- | |
| 17 | G4 | 35 | HDMI D0+ | |
| 18 | G5 | 34 | HDMI CK- | |
| 19 | G6 | 33 | HDMI CK+ | |
| 20 | G7 | 32 | | |
| 21–23 | B0–B2 | | GND | |
| 24 | B3 | 31 | | L14 |
| 25 | B4 | 30 | | L13 |
| 26 | B5 | 29 | | L12 |
| 27 | B6 | 28 | | L9 |
| 28 | B7 | 27 | | L8 |
| 29 | GND | | GND | |
| 30 | CLK | 77 | | L5 |
| 31 | DISP | | +3V3 (display always enabled) | |
| 32 | HSYNC | 25 | HDMI CEC | L10 |
| 33 | VSYNC | 26 | HDMI HPD | L11 |
| 34 | DEN | 48 | | R10 |
| 35 | NC | | not connected | |
| 36 | GND | | GND | |
| 37 | XR (`LCD_INIT0`) | 18 (top) / 15 (LCD sheet) | LED3 / LED0 | |
| 38 | YD (`LCD_INIT1`) | 19 (top) / 16 (LCD sheet) | LED4 / LED1 | |
| 39 | XL (`LCD_INIT2`) | 20 (top) / 17 (LCD sheet) | LED5 / LED2 | |
| 40 | YU (`LCD_INIT3`) | 17 (top) / 18 (LCD sheet) | LED2 / LED3 | |
| MP | pad1, pad2 | | GND | |

- **Touch lines (37–40):** resistive-touch lines, wired to LED pins. The top-level sheet
  maps them to pins 18, 19, 20, 17. The LCD sheet's own labels say 15, 16, 17, 18.
- **Which to trust:** the FPGA sheet doesn't settle it. The top level has been right in
  every other conflict, but confirm with a meter.

#### Backlight driver (U6)

LP3320 boost converter. It runs from +5V and drives the panel LEDs between VLED+ and
VLED- [sch].

| Part | Connection |
|---|---|
| C53 22 µF | +5V input to GND |
| L4 2.2 µH (0806) | +5V to SW (U6 pin 1) |
| D1 1N5819WS | SW to VLED+ |
| C54 2.2 µF/50 V | VLED+ to GND; OV (pin 5) senses VLED+ |
| R31 5.6 Ω 1% | VLED- to GND; FB (pin 3) senses VLED- (LED current sense) |
| R29 27 kΩ | +3V3 to EN (pin 4): backlight on by default |
| R30 100 Ω | `DSI_LCD_BLD` (FPGA pin 49) to EN |

Because of R29, the backlight is on unless pin 49 drives EN low.

### BL616 debugger (U5)

BL616C-50-Q2I-QFN40, on the "USB-JTAG" sheet [sch].

| Link | BL616 net | BL616 pin | FPGA pin | FPGA net |
|---|---|---|---|---|
| JTAG | `JTAG_TMS` | 15 (GPIO_16) | 5 | `PIN05_SYS_TMS` |
| JTAG | `JTAG_TCK` | 9 (GPIO_10) | 6 | `PIN06_SYS_TCK` |
| JTAG | `JTAG_TDI` | 11 (GPIO_12) | 7 | `PIN07_SYS_TDI` |
| JTAG | `JTAG_TDO` | 13 (GPIO_14) | 8 | `PIN08_SYS_TDO` |
| UART | `BL616_UART_RX` | 12 (GPIO_13) | 69 (FPGA TX) | `PIN69_SYS_TX` |
| UART | `BL616_UART_TX` | 10 (GPIO_11) | 70 (FPGA RX) | `PIN70_SYS_RX` |
| SPI | `SPI_DIR` | 4 (GPIO_0) | 86 | `PIN86_SPI_DIR` |
| SPI | `SPI_MOSI` | 31 (GPIO_27) | 76 | `PIN76_SPI_MOSI` |
| SPI | `SPI_MISO` | 34 (GPIO_30) | 75 | `PIN75_SPI_MISO` |
| SPI | `SPI_SCLK` | 5 (GPIO_1) | 13 (shared with MS5351 CLK2) | `PIN13_SPI_SCLK` |
| I2C | `5351_IIC_SDA` | 28 (GPIO_21) | — | to MS5351 |
| I2C | `5351_IIC_SCL` | 29 (GPIO_22) | — | to MS5351 |
| USB | `BL616_USBP` / `USBN` | 25 / 26 | — | to USB-C J1 |

- **SPI on the headers:** pins 86, 76 and 75 are at R13, R3 and L3. The pinout image
  calls them HSPI_CSN, HSPI_DAT and HSPI_DIR, which don't match the schematic's roles.
- **UART:** appears on the PC as a USB serial port. The FPGA can't be programmed while
  that port is open [ex].

| BL616 pin | Signal | Connection |
|---|---|---|
| 6 (GPIO_2) | `BL616_BOOT` | R22 10 kΩ and C51 100 nF to GND; SW4 push button and R23 10 kΩ to +3V3 |
| 17 | CHIP_EN (`BL616_EN`) | R21 27 kΩ to +3V3, C42 100 nF to GND (power-on reset delay) |
| 35, 36 | XTAL_IN, XTAL_OUT | Y2 40 MHz crystal |
| 1 | ANT | `BL616_ANT` |
| 7, 14, 16, 27, 32, 33 | GPIO_3, 15, 17, 20, 28, 29 | Net names only (`BL616_IOn`), no destination shown |
| 8, 30 | VDDIO1, VDDIO2 | +3V3 |
| 41 | GND_EP | GND |

- **Boot button:** pressing SW4 pulls `BL616_BOOT` high. SW4 is probably the button
  labeled UPDATE on the board; not confirmed.
- **Power:** an on-chip DC-DC converter (SW_DCDC pin 21, DCDC_OUT pin 22, L3 2.2 µH,
  C48 4.7 µF) supplies the RF rail. The 3.3 V supply pins have local decoupling
  (C33–C49).

#### USB-C connector (J1)

USB_C_Receptacle_USB2.0. The USB data lines go only to the BL616, never to the FPGA
[sch].

| J1 pin | Signal | Connection |
|---|---|---|
| A4 | VBUS | FU1 fuse (6 V, 2 A) to the board's +5V rail |
| A5 | CC1 | R24 5.1 kΩ to GND |
| B5 | CC2 | R25 5.1 kΩ to GND |
| A7, B7 | D- (both sides tied) | `BL616_USB#_N`, R26 0 Ω, to BL616 `BL616_USBN` |
| A6, B6 | D+ (both sides tied) | `BL616_USB#_P`, R27 0 Ω, to BL616 `BL616_USBP` |
| A8, B8 | SBU1, SBU2 | Not connected |
| A1 | GND | GND |
| S1 | SHIELD | GND |

- **ESD protection:** TVS diodes to GND on D- (D2), D+ (D6) and VBUS (D7).
- **Both plug orientations:** the A and B data pins are tied together, so the cable
  works either way up.
- **Device role (inferred):** 5.1 kΩ to GND on both CC pins is the standard USB-C signal
  for a device (power sink). So a C-to-C cable from a USB-C host powers the board and
  connects it. This comes from the USB-C convention, not the sheet.

## Shared wiring

FPGA pins wired to more than one thing. Driving one endpoint affects the others.

| Pins | Wired to |
|---|---|
| 13 | MS5351 CLK2 and BL616 SPI_SCLK (two possible drivers) |
| 33–40 | HDMI TMDS and LCD G6–G2, R7–R5 |
| 25 | LCD HSYNC, HDMI CEC (100 Ω, 27 kΩ pull-up) and header |
| 26 | LCD VSYNC, HDMI HPD (2.2 kΩ, 5.1 kΩ to GND) and header |
| 15–20 | LEDs (510 Ω to +3V3), header, and four of them LCD touch lines |
| 75, 76, 86 | BL616 SPI and header |
| 27–31, 41, 42, 48, 49, 77 | LCD connector and header |
| 51, 54–56 | Amplifier and header |
| 52, 53 | HDMI DDC (2.2 kΩ pull-ups) and header |
| 79 | WS2812 (5.1 kΩ to GND) and header |
| 80, 85 | TF card DAT2/DAT1 (10 kΩ pull-ups) and header |
| 87, 88 | Buttons, 1 kΩ pull-downs and FPGA MODE1/MODE0 |

## Source disagreements

### Circuit-sheet net labels

The circuit sheets put an FPGA pin number in their net names. These disagree with the
FPGA sheet and top-level sheet, which agree with each other and with Gowin's names:

| Sheet | Signal | Circuit-sheet label | FPGA sheet |
|---|---|---|---|
| TF CARD | CLK | `PIN83_SDIO_CLK` | 83 |
| TF CARD | CMD | `PIN84_SDIO_CMD` | 82 |
| TF CARD | DAT0 | `PIN83_SDIO_D0` | 84 |
| TF CARD | DAT1 | `PIN82_SDIO_D1` | 85 |
| TF CARD | DAT2 | `PIN86_SDIO_D2` | 80 |
| TF CARD | DAT3 | `PIN85_SDIO_D3` | 81 |
| DAC + Audio PA | PA_SD/EN | `PIN53_PA_SD/EN` | 51 |
| RGB LCD | XR, YD, XL, YU | `PIN15`–`PIN18_SYS_LED*` | not shown; top level says 18, 19, 20, 17 |

### Pinout image

| Item | Pinout image | Gowin and schematic |
|---|---|---|
| Pin 31 name | IOB29A | IOB18A |
| Pins 41, 42 bank | 5 (colored as bank 5; legend has no bank 4) | 4 |
| Pins 15, 16 | `LPLL2_T`, `LPLL2_C` | `LPLL2_T_FB`, `LPLL2_C_FB` (PLL feedback); PLL 2 input is pin 13 |
| Pins 75, 76, 86 | HSPI_DIR, HSPI_DAT, HSPI_CSN | `SPI_MISO`, `SPI_MOSI`, `SPI_DIR` |
| Pin 80 | no clock label | GCLKT_0 |

## Open questions

- **LCD touch lines.** Pins 18, 19, 20, 17 (top level) or 15–18 (LCD sheet). Check FPC
  pins 37–40 against the LED pins with a meter.
- **SW4 is UPDATE?** SW4 is the BL616 boot button; matching it to the UPDATE silkscreen
  is assumed.

Schematic download: <https://dl.sipeed.com/shareURL/TANG/Nano_20K/2_Schematic>

## Sources

- **Schematic, FPGA sheet:** IC1, U2 (flash), U3 (oscillator), test points.
- **Schematic, top-level sheet:** blocks DISPLAY, PERIPHERALS, AUDIO, USB_JTAG and
  headers J5/J6.
- **Schematic, circuit sheets:** "Button x 2", "DVI TX", "RGB LCD" / "LCD BACKLIGHT",
  "TF CARD", "LED", "WS2812", "AUX_PLL", "DAC + Audio PA", USB-C connector,
  "USB-JTAG", and the power regulators (U9, U10, U4, U11).
- **Gowin pin table:** `IDE/data/device/GW2AR-18C/QFN88.json`, Gowin IDE V1.9.11.03
  Education.
- **Pinout diagram:** Sipeed, "Tang Nano 20K pinout" image.
- **Wiki, board page:** <https://wiki.sipeed.com/hardware/en/tang/tang-nano-20k/nano-20k.html>
- **Wiki, Unbox page (MS5351):**
  <https://wiki.sipeed.com/hardware/en/tang/tang-nano-20k/example/unbox.html>
- **Example constraints:** `TangNano-20K-example/` (`hdmi`, `rgb_lcd`, `audio`,
  `ws2812`, `uart`, `led`).
