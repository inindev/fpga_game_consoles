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
`snes/` subfolder (for example `platform/iosys/nes/`) until the two are unified and tested.

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
make sdcard       # -> build/out/sdcard/cores/
```

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
make nes snes verify                            # must still match build/expected.sha256
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

## Status

Verified on hardware (Tang Nano 20K), built with Gowin V1.9.11.03 Education:

| Core | Logic | Block RAM | HDMI clock (74.25 MHz needed) |
|---|---|---|---|
| NES | 65% | 30/46 | 76.9 MHz |
| SNES | 91% | 44/46 | 94.5 MHz |

`make verify` checks that `build/out/*.bin` is byte-identical to those tested builds
(hashes in `build/expected.sha256`). Compare `.bin`, not `.fs`: the `.fs` header has a
build timestamp. A change that alters the hardware will change the hash; update
`build/expected.sha256` only after testing the new build on the board.

## Conventions

- File and directory names are lowercase. Exceptions: `README.md`, `LICENSE`,
  `CREDITS.md`, `SOURCES.md`, and `firmware/start.S` (the capital `.S` tells gcc to
  run the C preprocessor).
- Module names inside files are unchanged from upstream, so they can still be
  compared with the original projects.
