"""Lightweight reproducibility smoke tests for the Rogue SWAT+ <-> MODFLOW 6 paper.

These assert the *headline numbers* of the manuscript within tolerance:

  1. test_flow_calibration   -- the calibrated steady GWF run reproduces head NSE ~0.91,
                                RMSE ~5.6 m, baseflow ~+5.46 m3/s (~58 s).
  2. test_joint_calibration  -- joint_sw_gw_calibration.py reproduces g ~ 0.061 and
                                soil-loading L ~ 0.077 (fast; reads the GWT result).

They require the model workspace ($SWATGENX_ROGUE_DIR), mf6, and the flopy/scipy stack.
Where a prerequisite is missing the test SKIPS (it never silently passes). Run with:

    pytest -q reproducibility/tests/test_reproduce.py
    # the joint test alone (fast, no mf6 run): pytest -k joint ...
"""
import os
import re
import subprocess
import sys
import numpy as np
import pytest

HERE = os.path.dirname(os.path.abspath(__file__))
REPRO = os.path.dirname(HERE)
PAPER = os.path.abspath(os.path.join(REPRO, ".."))
ROGUE = os.environ.get(
    "SWATGENX_ROGUE_DIR",
    "/data/SWATGenXApp/Users/admin/SWATplus_by_VPUID/0405/usgs_station/04118500",
)
PY = os.environ.get("PYTHON", sys.executable)


def _have_workspace():
    return os.path.isdir(os.path.join(ROGUE, "MODFLOW_sfr"))


def _run(script_dir, script):
    """Run an analysis script, return its stdout (raises on non-zero exit)."""
    r = subprocess.run([PY, script], cwd=script_dir, capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(f"{script} failed:\n{r.stdout}\n{r.stderr}")
    return r.stdout


@pytest.mark.skipif(not _have_workspace(), reason="Rogue model workspace not available")
def test_flow_calibration():
    """Steady GWF run reproduces head NSE 0.91 / RMSE 5.6 m / baseflow +5.46 m3/s."""
    pytest.importorskip("flopy")
    out = _run(os.path.join(PAPER, "pest"), "build_rogue_calibrated.py")
    print(out)
    m = re.search(r"baseflow=([+\-0-9.]+) m3/s, head NSE=([0-9.]+), RMSE=([0-9.]+)", out)
    assert m, f"could not parse flow metrics from:\n{out}"
    baseflow, nse, rmse = float(m.group(1)), float(m.group(2)), float(m.group(3))
    assert nse == pytest.approx(0.91, abs=0.05), f"head NSE {nse} != ~0.91"
    assert rmse == pytest.approx(5.6, abs=1.0), f"head RMSE {rmse} != ~5.6 m"
    assert baseflow == pytest.approx(5.46, abs=0.6), f"baseflow {baseflow} != ~+5.46 m3/s"


@pytest.mark.skipif(not _have_workspace(), reason="Rogue model workspace not available")
def test_joint_calibration():
    """joint_sw_gw_calibration.py reproduces g ~ 0.061 and soil-loading L ~ 0.077."""
    pytest.importorskip("flopy")
    pytest.importorskip("geopandas")
    if not os.path.isfile(os.path.join(ROGUE, "rogue_pfas_results.npz")):
        pytest.skip("GWT transport result (rogue_pfas_results.npz) not present -- "
                    "run scripts/run_transport.sh first")
    out = _run(os.path.join(PAPER, "phase3"), "joint_sw_gw_calibration.py")
    print(out)
    npz = "/tmp/joint_calibration.npz"
    assert os.path.isfile(npz), "joint_calibration.npz not written"
    d = np.load(npz)
    g, L = float(d["g"]), float(d["L"])
    assert g == pytest.approx(0.061, abs=0.02), f"GW effectiveness g {g} != ~0.061"
    assert L == pytest.approx(0.077, abs=0.02), f"soil-loading L {L} != ~0.077"


if __name__ == "__main__":
    # allow `python test_reproduce.py` as a shell smoke test
    sys.exit(pytest.main([__file__, "-q", "-s"]))
