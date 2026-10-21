#!/usr/bin/env bash
# Run Gowin's command-line build tool (gw_sh) headless and without network access.
#
#   GOWIN_HOME=/path/to/Gowin/IDE  build/gowin/gw.sh <script.tcl> [args...]
#
# - Network: the tool runs in an empty network namespace (`unshare -rn`), so it
#   cannot reach anything. Needs unprivileged user namespaces (Debian default).
#   Set GOWIN_ALLOW_NETWORK=1 to skip this (not recommended).
# - Display: gw_sh starts a Qt GUI application even in console mode;
#   QT_QPA_PLATFORM=offscreen lets it run without one.
# - freetype: Gowin bundles an old libfreetype.so.6 that breaks the system's
#   fontconfig ("undefined symbol: FT_Done_MM_Var"). Gowin's own release note says
#   to delete it; if it is still there we preload the system copy instead.
#
# Tested with Gowin V1.9.11.03 Education (Linux x86-64) on Debian 13.
set -euo pipefail

: "${GOWIN_HOME:?set GOWIN_HOME to the Gowin IDE directory (the one containing bin/gw_sh)}"
GW_SH="$GOWIN_HOME/bin/gw_sh"
[ -x "$GW_SH" ] || { echo "gw.sh: $GW_SH not found or not executable" >&2; exit 1; }

env_args=(QT_QPA_PLATFORM=offscreen)
if [ -e "$GOWIN_HOME/lib/libfreetype.so.6" ]; then
  sys_ft=$(/sbin/ldconfig -p 2>/dev/null | awk '/libfreetype\.so\.6 .*x86-64/ {print $NF; exit}')
  [ -n "${sys_ft:-}" ] && env_args+=(LD_PRELOAD="$sys_ft")
fi

if [ "${GOWIN_ALLOW_NETWORK:-0}" = 1 ]; then
  exec env "${env_args[@]}" "$GW_SH" "$@"
fi
unshare -rn true 2>/dev/null || {
  echo "gw.sh: 'unshare -rn' is not available here (needs unprivileged user namespaces)." >&2
  echo "       Set GOWIN_ALLOW_NETWORK=1 to run without network isolation." >&2
  exit 1
}
exec unshare -rn env "${env_args[@]}" "$GW_SH" "$@"
