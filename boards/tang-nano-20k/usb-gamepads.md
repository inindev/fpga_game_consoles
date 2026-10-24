# USB gamepads on the Tang Nano 20K

How to wire two USB gamepads to the Tang Nano 20K for the NES and SNES cores. Header
positions and pin numbers are from [pinout.md](pinout.md); the pins are in
[controllers/usb.cst](controllers/usb.cst).

## What works

- **Low-speed USB gamepads only** (1.5 Mbit/s). Full-speed pads, such as Xbox 360 and
  PlayStation 4/5 pads, don't work.
- **No hubs:** one pad per socket.
- **Button layout:** mapped for the common 0810:0001 SNES-style USB pads. Other low-speed
  pads may work with some buttons in different places; the [USB probe core](#checking-a-pad)
  shows what a pad sends.
- **Builds:** USB is in every default build. With `CONTROLLERS`, include `usb` (see the
  README's Controllers section).

## Parts

- 2 × USB-A female sockets on a breakout board with 2.54 mm pins
- 4 × 15 kΩ resistors
- Jumper wires

## Connections

Everything is on the right-hand header (J5), positions 1–8. Position 1 is at the USB-C end.

| Right header | FPGA pin | Connects to |
|---|---|---|
| 1 | 5V | VBUS of both sockets |
| 2 | GND | GND of both sockets, and the four 15 kΩ resistors |
| 5 | 42 | Player 1 socket D+ |
| 6 | 41 | Player 1 socket D- |
| 7 | 56 | Player 2 socket D+ |
| 8 | 54 | Player 2 socket D- |

Each socket also needs two 15 kΩ resistors: one from D+ to GND and one from D- to GND.

USB-A socket pins, as usually marked on the breakout:

| Socket pin | Signal | Usual wire color |
|---|---|---|
| 1 | VBUS (5 V) | red |
| 2 | D- | white |
| 3 | D+ | green |
| 4 | GND | black |

## Diagram

One socket. The second is the same, with D+ on pin 56 (position 7) and D- on pin 54
(position 8), sharing 5V and GND.

```
 Tang Nano 20K                                        USB-A socket
 right header                                         (player 1)

 pos 1   5V      ───────────────────────────────────  1  VBUS

 pos 6   pin 41  ─────────────────────┬─────────────  2  D-
                                      │
                                    15 kΩ
                                      │
 pos 5   pin 42  ─────────┬───────────┼─────────────  3  D+
                          │           │
                        15 kΩ         │
                          │           │
 pos 2   GND     ─────────┴───────────┴─────────────  4  GND
```

## Why the 15 kΩ resistors

A USB host has a 15 kΩ resistor from each data line to ground; a low-speed device has a
1.5 kΩ resistor from D- to its supply. With nothing plugged in, both lines sit low. A pad
pulls D- high, and the core sees that as the pad attaching (`usb_hid_host.v`). The FPGA's
internal pull-downs (`PULL_MODE=DOWN` in `usb.cst`) are weak and not a specified 15 kΩ,
so the external resistors set the proper levels. NESTang's USB guide calls them necessary for
stability.

## Shared pins

- **Pins 54/56 (player 2)** are also the I2S inputs of the onboard audio amplifier. The
  cores keep the amplifier switched off (pin 51 held low), so the speaker pads are unused.
- **Pins 41/42 (player 1)** are also the R4/R3 lines of the RGB LCD connector. Don't
  connect an LCD panel at the same time.

## Checking a pad

`make usb_probe` builds a diagnostic core that prints what each socket receives over the
USB-C serial port (115200 8N1): device type, the raw report and the decoded buttons. LED0
lights when socket 1 sees a gamepad, LED1 for socket 2. The fields are explained at the
top of `boards/tang-nano-20k/usb_probe/top.v`.

```sh
make usb_probe
openFPGALoader -b tangnano20k build/out/usb_probe_nano20k.fs    # not saved to flash
```

Close the serial port before loading a core: the FPGA can't be programmed while the port
is open.
