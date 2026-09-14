#!/usr/bin/env python3
"""Assemble the Rogue (USGS 04118500) reproducibility model bundle.

Copies ONLY the essential MODFLOW 6 / SWAT+ *input* files from the (www-data-owned)
deployment workspace into ``reproducibility/models/rogue/`` and zips them. Binary
outputs (.hds, .ucn, .cbc, .lst, .grb), logs and intermediate rasters are excluded
so the bundle stays small (the deployment workspace is tens of GB; the inputs are
a few hundred MB).

Run it AS www-data (the workspace is www-data-owned), via the only sudo form that
has passwordless access on this server::

    sudo -n -u www-data /data/SWATGenXApp/codes/.venv/bin/python \
        reproducibility/scripts/make_model_bundle.py

Override the source workspace with $SWATGENX_ROGUE_DIR (default = the internal
deployment path). The destination is always ``reproducibility/models/rogue/`` next
to this script, and the zip is ``reproducibility/models/rogue_model_bundle.zip``.

What goes in (all *inputs*, no outputs):
  flow/        MODFLOW 6 GWF steady flow inputs (calibrated, MODFLOW_sfr_cal)
  transport/   MODFLOW 6 GWT PFAS transport inputs (pfas.*) + the GWF deck it couples to
  swat/        the as-built MODFLOW_sfr deck + SWAT+ TxtInOut + supporting geodata
  data/        observation tables + the rivs1 channel shapefile + grid centroids
"""
import os
import sys
import glob
import shutil
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPRO = os.path.dirname(HERE)                       # reproducibility/
DST = os.path.join(REPRO, "models", "rogue")
ZIP = os.path.join(REPRO, "models", "rogue_model_bundle.zip")

ROGUE = os.environ.get(
    "SWATGENX_ROGUE_DIR",
    "/data/SWATGenXApp/Users/admin/SWATplus_by_VPUID/0405/usgs_station/04118500",
)
CAL = f"{ROGUE}/MODFLOW_sfr_cal"           # calibrated GWF flow (PEST++ posterior)
PFAS = f"{ROGUE}/MODFLOW_rogue_pfas"       # GWT PFAS transport
SRC = f"{ROGUE}/MODFLOW_sfr"               # as-built GWF (MODGenX output, pre-calibration)
WA = f"{ROGUE}/SWAT_MODEL_Web_Application"
TXTINOUT = f"{WA}/Scenarios/Default/TxtInOut"

# Output extensions / names we must NEVER copy (they are model OUTPUTS, regenerable).
OUT_EXT = {".hds", ".ucn", ".cbc", ".grb", ".lst", ".chk", ".rei", ".rec", ".rmr"}
OUT_NAME = {"mfsim.lst"}

# MODFLOW 6 GWF input extensions (a flow deck). .sfr.stage is an input ref file.
GWF_IN = {".nam", ".tdis", ".ims", ".dis", ".npf", ".sto", ".ic", ".chd", ".cnc",
          ".ghb", ".drn", ".rch", ".rcha", ".wel", ".sfr", ".oc"}
# GWT transport input extensions.
GWT_IN = {".gwt", ".gwfgwt", ".adv", ".dsp", ".mst", ".ssm", ".cnc", ".sft",
          ".ic", ".oc", ".ims", ".dis", ".nam", ".ats"}


def _is_output(path):
    b = os.path.basename(path)
    if b in OUT_NAME:
        return True
    # strip the longest known extension (handles .sfr.cbc)
    low = b.lower()
    for e in OUT_EXT:
        if low.endswith(e):
            return True
    return False


def copy_inputs(src_dir, dst_dir, label):
    """Copy every NON-output file from a MODFLOW deck directory."""
    if not os.path.isdir(src_dir):
        print(f"  [skip] {label}: source missing ({src_dir})")
        return 0, 0
    os.makedirs(dst_dir, exist_ok=True)
    n = 0
    nbytes = 0
    for f in sorted(os.listdir(src_dir)):
        sp = os.path.join(src_dir, f)
        if os.path.isdir(sp):
            continue
        if _is_output(sp):
            continue
        shutil.copy2(sp, os.path.join(dst_dir, f))
        n += 1
        nbytes += os.path.getsize(sp)
    print(f"  [{label}] {n} input files, {nbytes/1e6:.1f} MB -> {os.path.relpath(dst_dir, REPRO)}")
    return n, nbytes


def copy_glob(patterns, dst_dir, label):
    os.makedirs(dst_dir, exist_ok=True)
    n = 0
    nbytes = 0
    for pat in patterns:
        for sp in glob.glob(pat):
            if os.path.isfile(sp):
                shutil.copy2(sp, os.path.join(dst_dir, os.path.basename(sp)))
                n += 1
                nbytes += os.path.getsize(sp)
    print(f"  [{label}] {n} files, {nbytes/1e6:.1f} MB")
    return n, nbytes


def copy_tree_filtered(src_dir, dst_dir, label, skip_ext=()):
    if not os.path.isdir(src_dir):
        print(f"  [skip] {label}: source missing ({src_dir})")
        return 0, 0
    os.makedirs(dst_dir, exist_ok=True)
    n = 0
    nbytes = 0
    for f in sorted(os.listdir(src_dir)):
        sp = os.path.join(src_dir, f)
        if not os.path.isfile(sp):
            continue
        if any(f.lower().endswith(e) for e in skip_ext):
            continue
        shutil.copy2(sp, os.path.join(dst_dir, f))
        n += 1
        nbytes += os.path.getsize(sp)
    print(f"  [{label}] {n} files, {nbytes/1e6:.1f} MB")
    return n, nbytes


def set_calibrated_run_settings(txtinout):
    """Make the shipped SWAT+ deck run the way the paper's calibration ran (Q645, 2026-09-14).

    time.sim: the 2000-2024 window of the forcing record (every weather file is nbyr 25 from 2000).
    The source workspace carried a single year (1 2024 366 2024).
    codes.bsn: pet=0, cn=2, the switches the calibrator (SWATGenX_SCV) applied on its run host and
    never persisted. The stored build-time pet=1/cn=0 re-runs the calibrated parameters with different
    ET/CN physics (task #27, 2026-08-12: daily NSE 0.61 / PBIAS +7% with 0/2 vs 0.05 / +43% with 1/0).
    Columns are located by header name, and before/after values are printed so the change is visible.
    """
    ts = os.path.join(txtinout, "time.sim")
    lines = open(ts).readlines()
    print(f"  [time.sim] before: {lines[2].strip()}")
    lines[2] = "       1      2000       366      2024         0\n"
    open(ts, "w").writelines(lines)
    print(f"  [time.sim] after:  {lines[2].strip()}")

    cb = os.path.join(txtinout, "codes.bsn")
    lines = open(cb).readlines()
    head, vals = lines[1].split(), lines[2].split()
    if len(head) != len(vals):
        sys.exit(f"ERROR: codes.bsn header/value count mismatch ({len(head)} vs {len(vals)})")
    for name, new in (("pet", "0"), ("cn", "2")):
        i = head.index(name)
        print(f"  [codes.bsn] {name}: {vals[i]} -> {new}")
        vals[i] = new
    lines[2] = "  ".join(vals) + "\n"
    open(cb, "w").writelines(lines)


def main():
    print(f"source workspace: {ROGUE}")
    if not os.path.isdir(ROGUE):
        sys.exit(f"ERROR: workspace not found: {ROGUE}\n"
                 "Set $SWATGENX_ROGUE_DIR to your copy.")
    shutil.rmtree(DST, ignore_errors=True)
    os.makedirs(DST, exist_ok=True)

    total = 0
    # 1. Calibrated GWF flow deck (the flow field the transport runs on).
    _, b = copy_inputs(CAL, os.path.join(DST, "flow"), "flow (MODFLOW_sfr_cal)")
    total += b
    # also carry the calibrated parameter table (an input artefact, not a binary output)
    for extra in ("calibrated_params.csv",):
        sp = os.path.join(CAL, extra)
        if os.path.isfile(sp):
            shutil.copy2(sp, os.path.join(DST, "flow", extra))

    # 2. GWT transport deck (pfas.* + the GWF deck it couples to).
    _, b = copy_inputs(PFAS, os.path.join(DST, "transport"), "transport (MODFLOW_rogue_pfas)")
    total += b

    # 3. SWAT+ side: as-built GWF deck + grid + the SWAT+ TxtInOut.
    _, b = copy_inputs(SRC, os.path.join(DST, "swat", "MODFLOW_sfr"), "swat/MODFLOW_sfr (as-built)")
    total += b
    _, b = copy_glob([f"{SRC}/Grids_MODFLOW_centroids.parquet"],
                     os.path.join(DST, "swat", "MODFLOW_sfr"), "swat grid centroids")
    total += b
    # TxtInOut holds BOTH SWAT+ inputs and last-run diagnostics; keep only inputs.
    # .out/.nc/.fin = SWAT+ run outputs (regenerable). .tmp is NOT skipped: in SWAT+ it is the
    # daily max/min temperature input named by weather-sta.cli. An earlier version skipped it as
    # "MODFLOW grid scratch"; that rule matched the 100 PRISM temperature files and nothing else,
    # and shipped a bundle whose SWAT+ model could not run (Q645, 2026-09-14).
    _, b = copy_tree_filtered(TXTINOUT, os.path.join(DST, "swat", "TxtInOut"),
                              "swat/TxtInOut (SWAT+ engine inputs)",
                              skip_ext=(".txt.bak", ".log", ".out", ".nc", ".fin"))
    total += b
    set_calibrated_run_settings(os.path.join(DST, "swat", "TxtInOut"))

    # 4. Observation + geometry data the calibration/validation scripts read.
    _, b = copy_glob([f"{WA}/pfas_gw_data/pfas_gw_PFOS.csv",
                      f"{WA}/pfas_gw_data/pfas_gw_assignment.csv"],
                     os.path.join(DST, "data"), "groundwater PFOS observations")
    total += b
    # The in-stream network the paper reports as 29 sampled stations on 20 reaches: 31 EGLE
    # surface-water stations snapped to 22 channels, 29 with quantified PFOS on 20 (Q645, 2026-09-14).
    _, b = copy_glob([f"{WA}/pfas_data/pfas_stations_assignment.csv"],
                     os.path.join(DST, "data"), "surface-water station assignment (29 stations / 20 reaches)")
    total += b
    # The SWAT+ streamflow calibration record behind the paper's Methods sentence (calibration 2018-2024, daily
    # NSE 0.67; verification 2003-2017, daily NSE 0.43-0.48). A skill number the deposit cannot reproduce is the
    # same class of defect as the lost depth grid (Q645, 2026-09-14).
    _, b = copy_glob([f"{ROGUE}/CentralPerformance.txt", f"{ROGUE}/calval_settings_snapshot.json"],
                     os.path.join(DST, "data"), "SWAT+ streamflow calibration record")
    total += b
    _, b = copy_glob([f"{WA}/Watershed/Shapes/rivs1.*"],
                     os.path.join(DST, "data", "rivs1"), "channel network shapefile (rivs1)")
    total += b
    # The watershed outline the coupling paper's Fig. 3 (paper/make_fig3_instream_map.py, ROGUE_SHAPES=<dir>) draws
    # under the channel network. Without it the figure cannot be regenerated from the deposit (Q645, 2026-09-14).
    _, b = copy_glob([f"{WA}/Watershed/Shapes/watershed_boundary.*"],
                     os.path.join(DST, "data", "watershed_boundary"), "watershed boundary shapefile")
    total += b
    _, b = copy_glob([f"{SRC}/Grids_MODFLOW_centroids.parquet"],
                     os.path.join(DST, "data"), "grid centroids (georeference)")
    total += b
    # head-observation table used by the PEST++ forward run (from the repo's pest/rogue)
    pest_obs = os.path.join(REPRO, "..", "pest", "rogue", "obs_wells.csv")
    if os.path.isfile(pest_obs):
        shutil.copy2(pest_obs, os.path.join(DST, "data", "obs_wells.csv"))
        print("  [data] obs_wells.csv (head observations) copied")

    # 5. MANIFEST
    manifest = os.path.join(DST, "MANIFEST.txt")
    with open(manifest, "w") as fh:
        fh.write("Rogue (USGS 04118500) SWAT+ <-> MODFLOW 6 reproducibility model bundle\n")
        fh.write("=" * 70 + "\n\n")
        fh.write("Contents (MODEL INPUTS ONLY; outputs are regenerated by the run scripts):\n\n")
        for root, _, files in os.walk(DST):
            rel = os.path.relpath(root, DST)
            for f in sorted(files):
                if f == "MANIFEST.txt":
                    continue
                p = os.path.join(root, f)
                fh.write(f"  {os.path.join(rel, f):60s} {os.path.getsize(p)/1e6:8.3f} MB\n")
    print(f"\nwrote {os.path.relpath(manifest, REPRO)}")

    # 6. Zip it.
    print(f"\nzipping -> {os.path.relpath(ZIP, REPRO)} ...")
    if os.path.exists(ZIP):
        os.remove(ZIP)
    with zipfile.ZipFile(ZIP, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as zf:
        for root, _, files in os.walk(DST):
            for f in files:
                p = os.path.join(root, f)
                zf.write(p, os.path.relpath(p, os.path.dirname(DST)))
    print(f"bundle (unzipped) inputs: {total/1e6:.1f} MB")
    print(f"bundle zip size:          {os.path.getsize(ZIP)/1e6:.1f} MB")
    print("done.")


if __name__ == "__main__":
    main()
