#!/usr/bin/env bash
# Run the steady-state MODFLOW 6 GWF flow model (the PEST++-calibrated Rogue flow field)
# and report the headline flow-calibration numbers:
#   head Nash-Sutcliffe ~0.91, RMSE ~5.6 m, baseflow ~+5.46 m3/s (observed 5.56).
#
# This re-applies the PEST++ ies posterior to the as-built MODFLOW_sfr deck and runs mf6
# (~58 s). It writes the calibrated flow field to $SWATGENX_ROGUE_DIR/MODFLOW_sfr_cal.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/common.sh"
require_exe "$MF6_EXE" "MODFLOW 6 (mf6)"

say "running calibrated steady-state GWF flow (build_rogue_calibrated.py)..."
say "  (applies the ies posterior realization 8 -> MODFLOW_sfr_cal, runs mf6)"
cd "$PAPER_ROOT/pest"
"$PYTHON" build_rogue_calibrated.py
say "done. Expect: head NSE ~0.91, RMSE ~5.6 m, baseflow ~+5.46 m3/s (obs 5.56)."
