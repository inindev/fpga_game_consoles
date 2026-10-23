# sim/

Testbenches: run one part of the design on its own, in a simulator, with a model of
what it talks to. Much faster than a board build, and you can test cases you don't
have the hardware for.

| Testbench | Tests | What it shows |
|---|---|---|
| `input/controller_snes_tb.v` | `platform/input/controller_snes.v` | a pad model (latch, clock, active-low data); how the reader tells an NES pad from an SNES pad |
| `input/usb_hid_host_tb.v` | `platform/input/usb_hid_host/usb_hid_host.v` | the clock enable averages exactly 12 MHz from 86.4 MHz; reports in the 0810:0001 pad's layout (some captured from a real pad) decode to the right buttons; forcing a module's internal signals to test one part without modelling USB |

Needs [Icarus Verilog](https://steveicarus.github.io/iverilog/) (`brew install icarus-verilog`,
`apt install iverilog`):

```sh
make -C sim controller_snes
make -C sim usb_hid_host
```
Outputs go to `build/out/sim/`.
