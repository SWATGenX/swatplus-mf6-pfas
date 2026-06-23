#!/usr/bin/env bash
# Shared environment for the Rogue SWAT+ <-> MODFLOW 6 reproducibility scripts.
# Source this from the run/build scripts. Override any of these in your shell.
set -euo pipefail

# Repo root = parent of scripts/
REPRO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPRO_ROOT

# MODFLOW 6 executable. We ship/point at the known-good USGS mf6 6.7.0 binary used to
# produce the manuscript results. Override MF6_EXE to your own build.
export MF6_EXE="${MF6_EXE:-/data/SWATGenXApp/codes/bin/mf6}"

# pestpp-ies executable (flow calibration). Override to your own build.
export PESTPP_IES="${PESTPP_IES:-/data/SWATGenXApp/codes/publication/swatplus-modflow6-coupling/pest/bin/pestpp-ies}"

# Python with flopy/pyemu/geopandas (the production venv by default).
export PYTHON="${PYTHON:-/data/SWATGenXApp/codes/.venv/bin/python}"

# The (www-data-owned) deployment workspace the phase3 / pest scripts read by default.
# For an external checkout, point this at the unzipped model bundle and the phase3
# scripts' hard-coded ROGUE path will need the same override (see README known gaps).
export SWATGENX_ROGUE_DIR="${SWATGENX_ROGUE_DIR:-/data/SWATGenXApp/Users/admin/SWATplus_by_VPUID/0405/usgs_station/04118500}"

# The original analysis code (phase3 + pest live one level up from reproducibility/).
export PAPER_ROOT="${PAPER_ROOT:-$(cd "$REPRO_ROOT/.." && pwd)}"

say() { printf '\033[1;34m[repro]\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m[repro] ERROR:\033[0m %s\n' "$*" >&2; exit 1; }

require_exe() {
  local p="$1" name="$2"
  [ -x "$p" ] || die "$name not found/executable at: $p (set the override env var)"
}
