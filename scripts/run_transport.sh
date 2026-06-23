#!/usr/bin/env bash
# Run the 40-year MODFLOW 6 GWT PFAS fate-and-transport model on the calibrated flow field
# and report the headline transport numbers:
#   GW plume validation vs 846 measured PFOS obs: ~1.1 dex overall, ~71% within x10;
#   SFT routes the discharged PFAS into ~1,354 of 1,506 stream reaches.
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
say "done. Expect: GW plume log-RMSE ~1.1 dex, ~71% within 10x; ~1,354 reaches > 1 ng/L."
