#!/usr/bin/env bash
# Run the joint surface-water + groundwater PFAS calibration on the Rogue mainstem.
# Fits  C_i = (L/L0)*C_SW_i + g*B_i  by non-negative least squares over 7 source-bearing
# mainstem reaches and reports the headline result:
#   GW effectiveness g = 0.061 (95% CI [0.022, 0.100]); soil-loading L 0.11 -> 0.077;
#   mainstem log-RMSE 0.15 -> 0.07 dex.
#
# Reads the GWT transport result (rogue_pfas_results.npz) + the calibrated SFR budget, so
# run_flow.sh and run_transport.sh must have completed first. Writes /tmp/joint_calibration.npz.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/common.sh"

[ -f "$SWATGENX_ROGUE_DIR/rogue_pfas_results.npz" ] || \
  die "GWT transport result not found -- run scripts/run_transport.sh first"

say "running joint SW+GW NNLS calibration (joint_sw_gw_calibration.py)..."
cd "$PAPER_ROOT/phase3"
"$PYTHON" joint_sw_gw_calibration.py
say "done. Expect: g ~ 0.061, soil-loading L ~ 0.077, joint log-RMSE ~0.07 dex."
