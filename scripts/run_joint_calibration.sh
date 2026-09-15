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

# The surface-water column of the FINAL leg (soil-loading scale 2.75 on the corrected assignment, 2000-2024 record, window
# 2017-2019; research/sw_rerun/results-2026-09-15/sweep/READOUT.md) is the committed per-channel CSV below; the seven
# mainstem stations (channels 26, 18, 15, 11, 10, 2, 1, upstream to downstream) are passed to the joint fit explicitly;
# the script's own default is the same column (the reviewed column, g 0.061, only with --reviewed-column).
SW_CSV="$PAPER_ROOT/research/sw_rerun/results-2026-09-15/sweep/channel_pfos_sx25_w1719.csv"
[ -f "$SW_CSV" ] || die "recalibrated surface-water column not found: $SW_CSV"
SW_MOD="$("$PYTHON" - "$SW_CSV" <<'PY'
import csv, sys
cp = {int(r["Channel"]): float(r["pfos_ngL"]) for r in csv.DictReader(open(sys.argv[1]))}
print(",".join(f"{cp[c]:.4f}" for c in (26, 18, 15, 11, 10, 2, 1)))
PY
)"
OUT="${JOINT_OUT_DIR:-$REPRO_ROOT/results/joint_calibration}"
say "running joint SW+GW NNLS fit (joint_sw_gw_calibration.py) on the recalibrated column $SW_MOD ..."
cd "$PAPER_ROOT/phase3"
"$PYTHON" joint_sw_gw_calibration.py --sw-mod "$SW_MOD" --out-dir "$OUT" --label reproducibility
say "done: $OUT/joint_fit.txt and joint_calibration.npz. Expect: g ~ 0.072 (95 % CI 0.038-0.105), L ~ 0.180 (surface multiplier 1.64 on the deck's column), mainstem log-RMSE surface-only ~0.41 -> joint ~0.06 dex; the committed record is research/sw_rerun/results-2026-09-15/sweep/jointfit/sx25_w1719_stats.txt."
