#!/usr/bin/env bash
# Document the three executables used for the manuscript and verify they are present.
#
# This repository was produced with the prebuilt, known-good binaries listed below.
# Compiling MODFLOW 6, SWAT+, and PEST++ from source is DOCUMENTED here so a reader can
# reproduce the toolchain locally, but the from-source commands are marked
# "verify locally" -- they are the upstream-recommended invocations, not run by this
# script. By default build.sh only checks that the binaries this repo expects exist.
#
# Usage:
#   bash scripts/build.sh            # check the binaries are present + print versions
#   bash scripts/build.sh --help     # show the from-source build recipes
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/common.sh"

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  cat <<'EOF'
================================================================================
FROM-SOURCE BUILD RECIPES (documented; verify locally)
================================================================================

1) MODFLOW 6  (the GWF flow + GWT transport engine; this repo used USGS mf6 6.7.0)
   Source:  https://github.com/MODFLOW-USGS/modflow6  (tag 6.7.0)
   Standard meson build (gfortran):
       git clone --branch 6.7.0 https://github.com/MODFLOW-USGS/modflow6
       cd modflow6
       meson setup builddir --prefix=$PWD/install --buildtype=release
       meson install -C builddir
       # -> install/bin/mf6
   Intel build (optional, faster):  FC=ifx meson setup builddir ...  (then as above)

2) SWAT+   (the surface-water hydrology + in-stream PFAS engine)
   This project builds SWAT+ with the Intel Fortran compiler at -O3:
       ifx -O3 -ipo <swatplus sources> -o swatplus
   NOTE: large SWAT+ models are known to fail when built with gfortran; ifx -O3 is
   the supported toolchain for this work. The Rogue model inputs in models/rogue/
   run on a stock SWAT+ executable (the in-stream PFAS routing is an add-on; stock
   SWAT+ runs the deck but does not emit the PFAS channel outputs).

3) PEST++  (pestpp-ies, iterative ensemble smoother; flow calibration only)
   Source:  https://github.com/usgs/pestpp
       git clone https://github.com/usgs/pestpp
       cd pestpp
       cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build -j
       # -> build/bin/pestpp-ies
================================================================================
EOF
  exit 0
fi

say "checking known-good binaries (override with MF6_EXE / PESTPP_IES / PYTHON)..."

require_exe "$MF6_EXE" "MODFLOW 6 (mf6)"
say "mf6:        $MF6_EXE"
"$MF6_EXE" --version | sed 's/^/            /' || true

if [ -x "$PESTPP_IES" ]; then
  say "pestpp-ies: $PESTPP_IES"
  "$PESTPP_IES" --version 2>/dev/null | head -1 | sed 's/^/            /' || true
else
  say "pestpp-ies: NOT found at $PESTPP_IES (only needed for run_flow_calibration.sh)"
fi

require_exe "$PYTHON" "Python interpreter"
say "python:     $PYTHON"
"$PYTHON" -c "import flopy, numpy, pandas, scipy; print('            flopy', flopy.__version__, '| numpy', numpy.__version__)" \
  || die "Python deps missing -- run: pip install -r requirements.txt"

say "toolchain OK. See 'bash scripts/build.sh --help' for from-source recipes."
