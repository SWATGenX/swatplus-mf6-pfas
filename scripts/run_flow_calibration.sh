#!/usr/bin/env bash
# (Optional / heavy) Re-run the PEST++ ies pilot-point + baseflow FLOW calibration that
# produced the posterior used by run_flow.sh. This is the inversion (243 pilot points,
# 120 realizations x 3 iterations) that yields head NSE ~0.91 and the baseflow match.
#
# The published run was dispatched to a 64-vCPU EC2 box (a few minutes wall) via
# pest/dispatch_pest.sh, because the iterative ensemble smoother runs many parallel
# forward models. Running it single-box here is possible but slow; this script documents
# the setup + master command. It is NOT part of the fast test path.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/common.sh"
require_exe "$MF6_EXE" "MODFLOW 6 (mf6)"
require_exe "$PESTPP_IES" "pestpp-ies"

ROGUE_PST_DIR="$PAPER_ROOT/pest/rogue"
say "PEST++ ies flow calibration"
say "  control file: $ROGUE_PST_DIR/control.pst"
say "  243 pilot points + globals (kv/rch/drn/ghb/pump/sfrk); obs = ~5,383 heads + baseflow"
say "  target baseflow 5.56 m3/s gaining (USGS 04118500, BFI 0.74)"
echo
say "To (re)generate the control files from the model + Wellogic heads:"
echo "    cd $PAPER_ROOT/pest && $PYTHON setup_rogue_pest.py"
echo
say "To run the ies (recommended: many cores; this is the cloud-dispatched step):"
echo "    cd $ROGUE_PST_DIR && noptmax in control.pst is the iteration count"
echo "    $PESTPP_IES control.pst                       # serial master+agent (slow)"
echo "    # or master/agent parallel -- see pest/dispatch_pest.sh for the EC2 recipe"
echo
say "After it finishes, apply the posterior with: bash scripts/run_flow.sh"
