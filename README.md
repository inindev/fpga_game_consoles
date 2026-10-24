# retro-fpga

NES and SNES recreated in FPGA hardware for the Sipeed **Tang Nano 20K**, organized for
learning: every directory corresponds to a real chip, a cartridge part, or something
the FPGA adds that the original console never had. Both systems share one on-screen
menu, and the menu can switch between them.

The design is nand2mario's [NESTang](https://github.com/nand2mario/nestang) and
[SNESTang](https://github.com/nand2mario/snestang), reorganized as one snapshot,
choosing the version of each part that works best together, plus fixes for current
Gowin tools. See `CREDITS.md` and `SOURCES.md`.

## Layout

```
systems/                  the original consoles, chip by chip
  nes/
    nes.v                   the "motherboard": wires the chips together
    chips/rp2a03/           CPU chip (2A03 NTSC / 2A07 PAL)
      cpu6502/                6502 core (T65)
      apu/                    sound: pulse, triangle, noise, DMC
    chips/rp2c02/           PPU, the picture chip (2C02 NTSC / 2C07 PAL)
    cartridge/              cartridge bus, iNES loader, save EEPROM
      mappers/                bank-switching chips on the cartridges (MMC1-5, VRC, ...)
  snes/
    snes.v                  the SNES "motherboard"
    cegen.v                 clock enables (SNES master clock dividers)
    chips/s-cpu_5a22/       CPU chip: 65C816 core + DMA/HDMA, multiply/divide
    chips/s-ppu/            picture chips (S-PPU1/S-PPU2, combined)
    chips/s-smp/            sound CPU (Sony SPC700)
    chips/s-dsp/            sound DSP
    chips/s-wram/           work RAM
    cartridge/              memory map, ROM header parsing
      enhancement/            chips some cartridges carry: DSP-1, OBC1, S-RTC

platform/                 what the FPGA adds (shared by both systems where possible)
  video/                    upscale to 720p, menu overlay, HDMI audio/video packing
  memory/                   SDRAM controllers (stand in for ROM/RAM chips), RAM helpers
  input/                    DualShock 2, SNES/NES pads, USB HID host, autofire
  iosys/                    the menu computer: PicoRV32 + SPI flash/SD + UART
  io/                       UART helpers

boards/tang-nano-20k/     everything specific to this board: top level per system,
                          pins (.cst), timing (.sdc), Gowin-generated PLLs
firmware/                 the menu (C, runs on the PicoRV32): one firmware for both cores
third_party/              external code kept as-is: hdmi (hdl-util), picorv32
build/gowin/              Gowin build scripts + headless, network-isolated wrapper
tools/import/             how this snapshot was assembled (manifest, patches)
```

Where a shared part still differs between the two systems, it lives in a `nes/` or
`snes/` subfolder until the two are unified and tested. In `platform/video/`, each system
has a small adapter (`nes_video.sv`, `snes_video.v`) in front of the shared `video_out.v`.

### Suggested reading order

1. `systems/nes/nes.v`: how the NES chips connect.
2. `systems/nes/chips/rp2a03/apu/apu.v`: a self-contained, readable chip.
3. `systems/nes/cartridge/cart.sv` and one mapper (`mappers/mmc1.sv`).
4. `boards/tang-nano-20k/nes/top.sv`: how the console meets the real board
   (clocks, SDRAM, HDMI, controllers, menu).
5. `platform/iosys/` + `firmware/firmware.c`: the menu computer, hardware and software.
6. Then the SNES, which follows the same pattern with more chips.

## Building

The gateware needs Gowin's tools (Linux x86-64); the firmware needs a RISC-V GCC.

```sh
export GOWIN_HOME=/path/to/Gowin/IDE           # tested: V1.9.11.03 Education
make nes          # -> build/out/nes_nano20k.{fs,bin}    (~3 min)
make snes         # -> build/out/snes_nano20k.{fs,bin}   (~4 min)
make firmware RISCV=/path/to/riscv-none-elf    # -> build/out/firmware.bin
make sdcard       # -> build/out/sdcard/cores/ (every NES/SNES core built)
```

To build only some controller types, see [Controllers](#controllers).

`build/gowin/gw.sh` runs Gowin headless (Qt `offscreen`) inside an empty network
namespace (`unshare -rn`), so the vendor tool can't reach the network.

### A minimal Gowin toolchain

The full Gowin download is 1.9 GB of mostly GUI, documentation and other device
families. `build/gowin/make-kit.sh` copies out only what command-line builds need:
the build engine, Verilog and VHDL support, the IP generator, device data and
primitive simulation models for the chosen chips.

```sh
build/gowin/make-kit.sh --docs --examples /path/to/Gowin_V1.9.11.03_Education_Linux /path/to/gowin-kit
chmod -R a-w /path/to/gowin-kit                 # Gowin never writes to its install
export GOWIN_HOME=/path/to/gowin-kit/IDE
build/gowin/kit-tests/run.sh                    # blinkers for Nano 20K + 9K, IP generation
make nes snes                                   # the real designs
```

| Option | Adds |
|---|---|
| `--devices LIST` | chip families (default `GW1N*,GW2A*`: Tang Nano 1K/4K/9K/20K, Primer 20K; `all` adds the GW5A boards, ~200 MB) |
| `--docs` | Gowin's English user guides (`IDE/doc/EN`): primitives, block RAM, clocks, DSP, I/O, timing, synthesis |
| `--examples` | Gowin's example projects (`IDE/data/examples`) |
Gowin's software can't be redistributed, so the kit stays on your machine; only the
script is in this repo.

## Putting it on the board

```sh
openFPGALoader -b tangnano20k -f build/out/nes_nano20k.fs              # core, flash address 0
openFPGALoader -b tangnano20k -f -o 0x500000 build/out/firmware.bin    # menu, once
```
Copy `build/out/sdcard/cores/` to the SD card as `/cores`. Menu item **2) Select core**
writes the chosen core to flash; reboot to start it. Games: `.nes` for the NES core,
`.sfc`/`.smc` for the SNES core.

Test a build without touching flash: `openFPGALoader -b tangnano20k build/out/nes_nano20k.fs`
(lost at power-off).

### Controllers

By default both cores read DualShock 2 pads, SNES/NES pads and low-speed USB gamepads at
the same time; all inputs for a player are combined, so use whichever is plugged in.
Pins are in `boards/tang-nano-20k/controllers/` (`ds2.cst`, `snes.cst`, `usb.cst`).

- **DualShock 2**: Sipeed's joystick adapters on the bottom six pins of each header
  (player 1 left, player 2 right).
- **SNES/NES pads**: left header positions 8–13, three pins per player: player 1 at 8–10
  (clock 27, latch 28, data 25), player 2 at 11–13 (clock 26, latch 29, data 30). These
  positions have no power pins; NESTang powers the pads from the right header (5V at
  position 1, GND at 2).
- **USB gamepads** (low-speed only, no hubs; mapped for 0810:0001 SNES-style pads): two
  USB-A sockets wired to the top of the right-hand header.

`CONTROLLERS` builds in only the types named (`usb`, `ds2`, `snes`); the pins of the
others are left unused. Several of those pins are shared with other parts of the board
(`boards/tang-nano-20k/pinout.md`): pins 25/26 with HDMI CEC/HPD, 52/53 with the HDMI EDID
lines and 17–20 with LEDs. The default build keeps the plain file name; otherwise the
chosen types are appended, in the order `usb`, `ds2`, `snes`:

```sh
make nes snes                      # all three -> nes_nano20k.bin, snes_nano20k.bin
make nes snes CONTROLLERS=usb      # USB only  -> nes_nano20k_usb.bin, snes_nano20k_usb.bin
make nes CONTROLLERS="usb ds2"     # -> nes_nano20k_usb_ds2.bin
```

| Header pin | USB |
|---|---|
| 5V | VBUS, both sockets |
| GND | GND, both sockets |
| 42 / 41 | player 1 D+ / D- |
| 56 / 54 | player 2 D+ / D- |

Each socket also needs a 15 kΩ resistor from D+ to GND and one from D- to GND. Pins 54/56
are shared with the onboard audio amplifier, so the cores keep it switched off (pin 51).
Full wiring, with a diagram and a diagnostic core for checking pads:
[boards/tang-nano-20k/usb-gamepads.md](boards/tang-nano-20k/usb-gamepads.md).

### Picture

Both cores output 1280x720 at 60 Hz through the same scaler (`platform/video/video_out.v`):

- Each source line becomes exactly 3 output lines: 224 lines (SNES) fill 672, 239
  (SNES overscan mode) 717 and 240 (NES) all 720.
- Across, **Options › Pixel shape** chooses the width: **8:7** (default, 878 pixels: the
  pixel shape both consoles produced on a TV), **Square** (768, each pixel exactly 3x3)
  or **4:3** (fills a 4:3 frame). Where an output pixel falls across two source pixels it
  is a mix of the two by how much of each it covers, so all source pixels keep the same
  width. The setting is saved in `/snestang.ini` as `pixel_shape`.
- The console is locked to the HDMI frame rate: it runs about 0.7% fast and pauses once
  per frame for about 120 µs, so every frame is shown exactly once and nothing tears.
- The menu has its own fixed 3x window and shows over the game dimmed to 1/4.

`make nes TEST_PATTERN=1` (or `snes`) builds a core that shows grey steps instead of the
game (`build/out/nes_nano20k_testpattern.bin`), for checking how a TV handles the HDMI
colour range: an upper row of 16 near-black patches (0, 4 … 60) and a lower row of 16
near-white patches (195, 199 … 255). If the TV shows every patch distinct, it receives
every level; patches that merge into one black or one white are being clipped.

## Status

Verified on hardware (Tang Nano 20K), built with Gowin V1.9.11.03 Education:

| Core | Logic | Block RAM | HDMI clock (74.25 MHz needed) |
|---|---|---|---|
| NES | 68% | 10/46 | 74.7 MHz |
| SNES | 98% | 46/46 | 74.9 MHz |

## Conventions

- File and directory names are lowercase. Exceptions: `README.md`, `LICENSE`,
  `CREDITS.md`, `SOURCES.md`, and `firmware/start.S` (the capital `.S` tells gcc to
  run the C preprocessor).
- Module names inside files are unchanged from upstream, so they can still be
  compared with the original projects.
