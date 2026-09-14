#!/usr/bin/env bash
# Run the 40-year MODFLOW 6 GWT PFAS fate-and-transport model on the calibrated flow field
# and compare the simulated plume with the 846 measured groundwater PFOS observations (73 cells).
#   The manuscript reports that comparison as RANGE, not cell-level skill: the plume spans the
#   observed range above the 10 ng/L background up to the prescribed source, with 19 of 63
#   predicted cells observed below the lowest simulated value (9.3 ng/L). The log-RMSE and
#   within-10x fraction the script prints are its own diagnostics, not manuscript claims.
#   SFT routes the discharged PFAS into the SFR channel network.
#
# Freundlich sorption (porosity 0.30, bulk density 1800 kg/m3), TVD advection, source
# PRESCRIBED to the measured House Street plume (constant-concentration cells), 40-yr
# transient with adaptive time stepping (ATS). Couples GWF6-GWT6 via the exchange; SFT
# carries the groundwater-discharged PFAS into the SFR channel network.
#
# Requires run_flow.sh to have produced MODFLOW_sfr_cal first.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/common.sh"
require_exe "$MF6_EXE" "MODFLOW 6 (mf6)"

[ -d "$SWATGENX_ROGUE_DIR/MODFLOW_sfr_cal" ] || \
  die "calibrated flow field not found -- run scripts/run_flow.sh first"

say "running 40-yr GWT PFAS transport (phase3_rogue_pfas.py)..."
cd "$PAPER_ROOT/phase3"
"$PYTHON" phase3_rogue_pfas.py
say "done. The plume comparison establishes range, not cell-level skill (see README, Headline results);"
say "the log-RMSE / within-10x lines above are the script's own diagnostics, not manuscript claims."
