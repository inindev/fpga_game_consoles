# sim/

Testbenches: run one part of the design on its own, in a simulator, with a model of
what it talks to. Much faster than a board build, and you can test cases you don't
have the hardware for.

| Testbench | Tests | What it shows |
|---|---|---|
| `input/controller_snes_tb.v` | `platform/input/controller_snes.v` | a pad model (latch, clock, active-low data); how the reader tells an NES pad from an SNES pad |

Needs [Icarus Verilog](https://steveicarus.github.io/iverilog/) (`brew install icarus-verilog`,
`apt install iverilog`):

```sh
make -C sim controller_snes
```
Outputs go to `build/out/sim/`.
