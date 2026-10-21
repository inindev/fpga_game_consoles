# Credits

retro-fpga is a reorganized snapshot of two projects by **nand2mario**, plus small fixes.
Almost all of the hardware design is their work and the work they built on.
`SOURCES.md` lists where every file came from.

## Upstream projects

| Project | Author | Used for |
|---|---|---|
| [NESTang](https://github.com/nand2mario/nestang) v0.12 | nand2mario | NES core, Tang Nano 20K top level, menu hardware (`iosys`) |
| [SNESTang](https://github.com/nand2mario/snestang) v0.9 | nand2mario | SNES core, menu firmware |

## Work the upstream projects build on

Credited in the NESTang and SNESTang READMEs and in the source file headers:

| Work | Author(s) | Where it ended up |
|---|---|---|
| [fpganes](https://github.com/strigeus/fpganes) | Ludvig Strigeus | `systems/nes/` (NES core, PPU, APU) |
| [NES for Tang Nano 9K](https://github.com/hi631/tang-nano-9K) | hi631 | NES on Tang boards; basis of `usb_hid_host` |
| NES mappers (MiSTer NES core) | Kitrinx and other MiSTer contributors | `systems/nes/cartridge/mappers/` |
| T65 (6502 core) | Daniel Wallner, MikeJ and others | `systems/nes/chips/rp2a03/cpu6502/` |
| [SNES_FPGA](https://github.com/gyurco/SNES_FPGA) (MiSTer/MiST SNES) | Sergiy Dvodnenko (srg320), gyurco | `systems/snes/` |
| [hdl-util/hdmi](https://github.com/hdl-util/hdmi) | Sameer Puri | `third_party/hdmi/` |
| [PicoRV32](https://github.com/YosysHQ/picorv32) | Claire Xenia Wolf | `third_party/picorv32/` |
| [FatFs](http://elm-chan.org/fsw/ff/) | ChaN | `firmware/fatfs/` |

## Licenses

The project as a whole is distributed under the **GNU General Public License v3.0**
(`LICENSE`), the license of both upstream projects. Files that carry their own license
or copyright header (for example PicoRV32's ISC license, FatFs's BSD-style license)
keep it unchanged. Files changed for retro-fpga say so in their first line and are listed
under "Modifications" in `SOURCES.md`.
