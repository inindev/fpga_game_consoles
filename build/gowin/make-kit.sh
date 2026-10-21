#!/usr/bin/env bash
# Build a minimal, headless Gowin toolchain ("kit") from a full Gowin EDA install.
#
#   build/gowin/make-kit.sh [options] <full Gowin dir containing IDE/> <kit dir>
#   e.g. build/gowin/make-kit.sh --docs --examples ~/fpga/gowin-1.9.11.03-edu ~/fpga/gowin-1.9.11.03-kit
#
# Options:
#   --devices LIST   comma-separated device patterns (shell globs, as named in
#                    IDE/share/device/), or "all". Default: GW1N*,GW2A*
#                    (LittleBee + Arora: Tang Nano 1K/4K/9K/20K, Tang Primer 20K).
#                    GW5A* (Arora V: Primer 25K, Mega, Console) adds ~200 MB.
#   --docs           English user guides (doc/EN, ~44 MB of PDFs) into IDE/doc/EN
#   --examples       Gowin's example projects (data/examples, ~6 MB)
#
# The kit can: build Verilog and VHDL designs for the chosen devices from the command
# line (gw_sh), generate Gowin IP (GowinModGen), and simulate Gowin primitives
# (simlib/<family>). It leaves out the GUI applications, other languages' docs,
# SerDes/eye-diagram tools, signal-integrity models, and the bundled libfreetype
# (Gowin's release note says to delete it on Linux).
#
# What gw_sh needs was measured with strace on full NES and SNES builds, a VHDL test
# and an IP-generation test (see GOWIN-MIN-LOG.md on the build host). Kept by
# category, not by trace alone, so designs that use other Gowin features still work.
# build/gowin/kit-tests/run.sh checks a kit.
#
# Gowin's software is not redistributable: the kit is for your own machine and is
# never committed to this repo. Tested with Gowin V1.9.11.03 Education (Linux).
set -euo pipefail

usage() { echo "usage: make-kit.sh [--devices LIST|all] [--docs] [--examples] <full Gowin dir> <kit dir>" >&2; exit 1; }
DEVICES="GW1N*,GW2A*"; DOCS=0; EXAMPLES=0
while [ $# -gt 0 ]; do
  case "$1" in
    --devices) DEVICES=${2:?}; shift 2 ;;
    --docs) DOCS=1; shift ;;
    --examples) EXAMPLES=1; shift ;;
    -*) usage ;;
    *) break ;;
  esac
done
[ $# -eq 2 ] || usage
SRC=$1/IDE
DST=$2/IDE
[ -x "$SRC/bin/gw_sh" ] || { echo "make-kit: $SRC/bin/gw_sh not found" >&2; exit 1; }
[ -e "$DST" ] && { echo "make-kit: $DST already exists" >&2; exit 1; }

copy() {  # copy paths (relative to IDE/) that exist, keeping the directory layout
  local p
  for p in "$@"; do
    [ -e "$SRC/$p" ] || { echo "make-kit: missing $p" >&2; exit 1; }
    mkdir -p "$DST/$(dirname "$p")"
    cp -a "$SRC/$p" "$DST/$p"
  done
}

# 1. Programs: the build engine (synthesis, place & route and bitstream all run inside
#    gw_sh) and the IP generator, plus the data files they read.
copy bin/gw_sh bin/GowinModGen bin/qt.conf bin/nlsresource \
     bin/primitive.xml bin/hardcore.xml bin/prim_syn.v bin/prim_syn.vhd bin/prim_syns \
     bin/vhdl_packages            # all VHDL standards and libraries (VHDL-87 .. 2019)

# 2. Libraries gw_sh loads (from the traces), including ones it opens at run time.
#    The Qt GUI/WebEngine libraries are linked into gw_sh, so it won't start without them.
copy $(printf 'lib/%s ' \
  libalog.so libAssistant.so libCmdOption.so libcrypto.so.10 libDevice.so libExtSys.so \
  libGaoUtils.so libGLdispatch.so.0 libGLX.so.0 libGowinProxy.so libgowin.so \
  libGowinSynProxy.so libGvioUtils.so libgwsyn.so libGWTE.so libhdlresolve.so \
  libicudata.so.56 libicui18n.so.56 libicuuc.so.56 libJson.so libnetcatcher.so \
  libNlsData.so libNlsUtils.so libQt5Concurrent.so.5 libQt5Core.so.5 libQt5Gui.so.5 \
  libQt5Network.so.5 libQt5Positioning.so.5 libQt5PrintSupport.so.5 libQt5QmlModels.so.5 \
  libQt5Qml.so.5 libQt5Quick.so.5 libQt5QuickWidgets.so.5 libQt5Sql.so.5 \
  libQt5WebChannel.so.5 libQt5WebEngineCore.so.5 libQt5WebEngineWidgets.so.5 \
  libQt5Widgets.so.5 libQt5Xml.so.5 libQUtility.so libQZip.so librtlhierarchy.so \
  librtlparser.so librtlviewer.so libstdc++.so.6 libStyle.so libtcl8.6.so libUtils.so \
  libXau.so.6 libxcb.so.1 libXext.so.6 libXrender.so.1)
copy lib/tcl8.6                   # Tcl runtime scripts used by gw_sh's interpreter

# 3. Plugins gw_sh loads at startup; only Qt's headless "offscreen" display.
copy $(printf 'plugins/ide/%s ' libCoreGen.so libFpgaPrj.so libGAOIns.so libGPC.so \
  libGVIO.so libIdeCore.so libRtlGAOIns.so)
copy plugins/qt/platforms/libqoffscreen.so plugins/qt/platforms/libqminimal.so

# 4. IP cores: gw_sh loads every core's plugin at startup; the rest is what IP
#    generation needs. Per-core documentation left out.
copy ipcore
find "$DST/ipcore" -mindepth 2 -maxdepth 2 -type d -name doc -exec rm -rf {} +

# 5. Device data for the chosen devices (each has share/device/<dev>, most also
#    data/device/<dev>), plus the shared device catalogues.
copy share/device/device_info.csv share/device/pn_voltage.csv share/firmcore share/config \
     data/config data/device/device_info.csv data/device/device_package.csv \
     data/ipcores data/iotable data/hardware_core
[ "$DEVICES" = all ] && DEVICES="*"
families=""
for d in "$SRC"/share/device/*/; do
  d=$(basename "$d")
  for pat in ${DEVICES//,/ }; do
    # shellcheck disable=SC2053  # $pat is a glob on purpose
    if [[ $d == $pat ]]; then
      copy "share/device/$d"
      [ -e "$SRC/data/device/$d" ] && copy "data/device/$d"
      fam=$(echo "$d" | sed -E 's/^(GW[0-9]).*/\1/' | tr 'A-Z' 'a-z')   # GW1NR-9C -> gw1
      families="$families $fam"
      echo "make-kit: device $d"
      break
    fi
  done
done
[ -n "$families" ] || { echo "make-kit: no devices match '$DEVICES'" >&2; exit 1; }

# 6. Simulation models of the chosen families' primitives (simlib/gw1n, gw2a, gw5a),
#    for testbenches (iverilog/Verilator).
for fam in $(echo $families | tr ' ' '\n' | sort -u); do
  for s in "$SRC"/simlib/"$fam"*; do [ -e "$s" ] && copy "simlib/$(basename "$s")"; done
done

# 7. Optional reading and examples.
[ $DOCS = 1 ] && copy doc/EN
[ $EXAMPLES = 1 ] && copy data/examples

# 8. Safety net: anything the kept programs and libraries link against that is
#    bundled with Gowin but not copied yet.
added=1
while [ $added -gt 0 ]; do
  added=0
  while read -r so; do
    for need in $(readelf -d "$so" 2>/dev/null | sed -n 's/.*NEEDED.*\[\(.*\)\]/\1/p'); do
      [ "$need" = libfreetype.so.6 ] && continue
      if [ -e "$SRC/lib/$need" ] && [ ! -e "$DST/lib/$need" ]; then
        echo "make-kit: also copying lib/$need (linked by ${so#$DST/})"
        copy "lib/$need"; added=1
      fi
    done
  done < <(find "$DST" -type f \( -name '*.so*' -o -path '*/bin/gw_sh' -o -path '*/bin/GowinModGen' \))
done

echo "make-kit: $(find "$DST" -type f | wc -l) files, $(du -sh "$DST" | cut -f1) in $DST"
