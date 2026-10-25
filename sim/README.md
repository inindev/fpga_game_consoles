# sim/

Testbenches: run one part of the design on its own, in a simulator, with a model of
what it talks to. Much faster than a board build, and you can test cases you don't
have the hardware for.

| Testbench | Tests | What it shows |
|---|---|---|
| `input/controller_snes_tb.v` | `platform/input/controller_snes.v` | a pad model (latch, clock, active-low data); how the reader tells an NES pad from an SNES pad |
| `input/usb_hid_host_tb.v` | `platform/input/usb_hid_host/usb_hid_host.v` | the clock enable averages exactly 12 MHz from 86.4 MHz; reports in the 0810:0001 pad's layout (some captured from a real pad) decode to the right buttons; forcing a module's internal signals to test one part without modelling USB |
| `video/nes_audio_hdmi_tb.v` | `platform/video/nes_audio_hdmi.sv` | NES audio for HDMI: silence at 0 for both resting levels (APU alone, expansion sound), a tone keeps its swing centred on 0, and the clock crossing only takes values the NES side held |
| `video/video_out_tb.v` | `platform/video/video_out.v`, `osd.v` | every pixel of whole HDMI frames against a model: 8:7, square and 4:3 at 224, 239 and 240 lines (blended columns checked against a real-arithmetic coverage model), black borders, menu text at 3x over the dimmed game (~10 min) |
| `video/nes_video_tb.v` | `platform/video/nes_video.sv` | frame lock: a PPU timing model that stops on `pause`; once locked, each HDMI frame shows exactly one NES frame, in order |
| `video/snes_video_tb.v` | `platform/video/snes_video.v` | the same for the SNES (pause during DRAM refresh), and the 224/239 line count (`LINES=224` for the normal mode) |

The video testbenches use Gowin's primitive models (`GOWIN_HOME`) and `video/hdmi_sim.v`,
a stand-in for the HDMI encoder that keeps its pixel counters (Icarus cannot compile
`third_party/hdmi`).

Needs [Icarus Verilog](https://steveicarus.github.io/iverilog/) (`brew install icarus-verilog`,
`apt install iverilog`):

```sh
make -C sim controller_snes
make -C sim usb_hid_host
make -C sim nes_audio_hdmi
make -C sim video_out GOWIN_HOME=/path/to/Gowin/IDE      # also nes_video, snes_video
```
Outputs go to `build/out/sim/`.
