#!/usr/bin/env bash
# Check a Gowin toolchain (full install or a make-kit.sh kit).
#
#   GOWIN_HOME=/path/to/IDE build/gowin/kit-tests/run.sh
#
# 1. Builds a Verilog and a VHDL LED blinker for the Tang Nano 20K (GW2AR-18C)
#    and the Tang Nano 9K (GW1NR-9C): synthesis, place & route, bitstream.
# 2. Regenerates the Nano 20K PLLs from their .mod files with GowinModGen and
#    compares them with the committed .v files, ignoring comments (headers carry the
#    tool version; gowin_pll_snes.v was renamed upstream and its endmodule comment wasn't).
# Also run `make nes snes verify` from the repo root: the real designs.
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../../.." && pwd)
: "${GOWIN_HOME:?set GOWIN_HOME to the Gowin IDE directory}"
WORK=${OUT:-$ROOT/build/out/kit-tests}
rm -rf "$WORK" && mkdir -p "$WORK"
fail=0
pass() { printf '  PASS  %s\n' "$1"; }
bad()  { printf '  FAIL  %s  (%s)\n' "$1" "$2"; fail=1; }

echo "Blinkers (synthesis, place & route, bitstream):"
for board in "tang-nano-20k GW2AR-LV18QN88C8/I7" "tang-nano-9k GW1NR-LV9QN88PC6/I5"; do
  set -- $board
  for lang in verilog vhdl; do
    name="$1-$lang"; d="$WORK/$name"; mkdir -p "$d"
    if [ $lang = verilog ]; then src="-type verilog $HERE/blink.v"; else src="-type vhdl $HERE/blink.vhd"; fi
    cat > "$d/build.tcl" <<EOF
set_device $2 -device_version C
add_file $src
add_file -type cst $HERE/$1.cst
set_option -synthesis_tool gowinsynthesis
set_option -top_module blink
set_option -verilog_std sysv2017
set_option -vhdl_std vhd2008
set_option -output_base_name blink
run all
EOF
    if (cd "$d" && "$ROOT/build/gowin/gw.sh" build.tcl > gw_sh.log 2>&1) && [ -s "$d/impl/pnr/blink.fs" ]; then
      pass "$name"
    else
      bad "$name" "see $d/gw_sh.log"
    fi
  done
done

echo "IP generation (GowinModGen):"
for v in boards/tang-nano-20k/nes/gowin_pll_nes.v boards/tang-nano-20k/snes/gowin_pll_snes.v; do
  base=$(basename "$v" .v); d="$WORK/ipgen-$base"; mkdir -p "$d"
  # the committed .mod has the upstream author's output path; send output here instead
  sed "s#^-path .*#-path $d/#" "$ROOT/${v%.v}.mod" > "$d/$base.mod"
  if (cd "$d" && unshare -rn env QT_QPA_PLATFORM=offscreen "$GOWIN_HOME/bin/GowinModGen" -do "$base.mod" > modgen.log 2>&1) \
     && diff -q <(sed 's#//.*##' "$d/$base.v") <(sed 's#//.*##' "$ROOT/$v") > /dev/null; then
    pass "$base matches $v"
  else
    bad "$base" "see $d/modgen.log or diff with $v"
  fi
done

[ $fail = 0 ] && echo "All kit tests passed." || { echo "Some kit tests FAILED."; exit 1; }
