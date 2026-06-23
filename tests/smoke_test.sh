#!/usr/bin/env bash
# Shell smoke test: a SHORT reproduction that asserts the key numbers.
#   - runs the calibrated steady GWF flow (~58 s) and checks head NSE / baseflow
#   - runs the joint SW+GW calibration and checks g ~ 0.061
# Falls back gracefully (SKIP, exit 0) if the model workspace or mf6 is unavailable.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../scripts/common.sh"

if [ ! -d "$SWATGENX_ROGUE_DIR/MODFLOW_sfr" ]; then
  echo "[smoke] SKIP: model workspace not found at $SWATGENX_ROGUE_DIR"; exit 0
fi
if [ ! -x "$MF6_EXE" ]; then
  echo "[smoke] SKIP: mf6 not found at $MF6_EXE"; exit 0
fi

fail() { echo "[smoke] FAIL: $*" >&2; exit 1; }

say "[1/2] steady GWF flow ..."
OUT="$("$PYTHON" "$PAPER_ROOT/pest/build_rogue_calibrated.py" 2>&1)" || fail "flow run errored:\n$OUT"
echo "$OUT"
echo "$OUT" | grep -qE "head NSE=0\.9" || fail "head NSE not ~0.9"
echo "$OUT" | grep -qE "baseflow=\+5\.[0-9]" || fail "baseflow not ~+5 m3/s"
say "    flow OK (NSE ~0.91, baseflow ~+5.46)"

if [ -f "$SWATGENX_ROGUE_DIR/rogue_pfas_results.npz" ]; then
  say "[2/2] joint SW+GW calibration ..."
  OUT="$("$PYTHON" "$PAPER_ROOT/phase3/joint_sw_gw_calibration.py" 2>&1)" || fail "joint run errored:\n$OUT"
  echo "$OUT"
  echo "$OUT" | grep -qE "g=0\.0[5-7]" || fail "GW effectiveness g not ~0.061"
  say "    joint OK (g ~ 0.061)"
else
  say "[2/2] SKIP joint calibration (run scripts/run_transport.sh first)"
fi
say "smoke test PASSED"
