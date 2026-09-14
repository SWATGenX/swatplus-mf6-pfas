# CHANGELOG

## Next version after v1.0 (staged 2026-09-14; uploaded by the author as a new version of 10.5281/zenodo.20838388)

What v1.0 (10.5281/zenodo.20838389, 2026-06-25) lacked or got wrong:

1. **SWAT+ temperature inputs were missing.** The bundler skipped `*.tmp` as "MODFLOW grid scratch"; in SWAT+ they are
   the daily temperature files named by `weather-sta.cli`. v1.0's `TxtInOut` held 0 `.tmp` files, and now holds 100.
2. **The calibration's run settings were not carried.** `codes.bsn` shipped the build-time pet=1/cn=0 while the
   calibration ran pet=0/cn=2; `time.sim` covered 2024 only. Both now match the calibration (pet=0, cn=2, 2000-2024).
3. **The in-stream station assignment was not deposited:** `models/rogue/data/pfas_stations_assignment.csv`
   (31 EGLE stations, 29 with quantified PFOS on 20 reaches).
4. **The depth-to-water grid behind the vadose transit times was not deposited, and its values were feet read as
   metres.** `vadose/make_dtw_grid.py` regenerates it (MODGenX kriging of Wellogic static water level, converted to
   metres). `vadose/dtw_grid_rogue.npz` carries `units` and `provenance` keys. `vadose/vadose_travel_time.py` and
   `vadose_verify_sobol.py` read it; basin median depth to water is 10.4 m, not 31 m.
5. **The SWAT+ streamflow calibration record was not deposited:** `models/rogue/data/CentralPerformance.txt` (114
   calibration/verification evaluations) and `calval_settings_snapshot.json` (calibration 2018-2024, verification
   2003-2017, two warm-up years), behind the paper's reported streamflow skill.

6. **The README's headline table restated the plume comparison as validation ("1.1 dex, 71 % within ×10 against 846
   observations") and the joint fit as a calibration with skill statistics.** The manuscript withdrew both framings on
   2026-09-14: the simulated plume spans the observed range with no cell-level skill (19 of 63 predicted cells observed
   below the lowest simulated value, 9.3 ng/L; two undershoot cells beside the prescribed source disclosed in SI S2.3),
   and the groundwater share of the in-stream signal is a fitted partition, not a model prediction (g = 0.061, L = 0.077;
   8–13 % at the five upstream stations, 53–55 % at the two lowest). The head calibration is stated error-first
   (RMSE 5.6 m, bias +0.9 m over 5,383 observations, NSE 0.91). `README.md` and `scripts/run_transport.sh` now say this.
   Also new in the parent repository since v1.0 and behind the revised manuscript, not archived here: the plume-skill
   census (`research/plume_skill/`, `533b33543`), the source shut-off run (`research/source_off/`, `fb789f22e`; groundwater load to
   the river halves in 5.0 yr and reaches one tenth in 23.1 yr after the source cells are removed) and the SI figures
   regenerated from committed generators with no in-figure titles (`paper/make_si_figures.py`, `16234f384`).
   Commits: `64692adaf` (undershoot disclosure), `b983688c4` and `9b4d5bc42` (fitted partition as a step, Figure 5
   legend), `533b33543` and `645ad059a` (head error-first), `16234f384` (PDFs rebuilt).

Commits (from git log, repository github.com/rafiei-vahid/SWATGenX):
- `4140527ed` 2026-09-14 coupling repro (Q645, Lane P ruling): deposit the SWAT+ streamflow calibration record behind the paper's skill numbers
- `7117f2487` 2026-09-14 coupling paper (Q645 ruling 8): cite the Zenodo concept DOI; depth grid carries its units and provenance
- `dbe0d349c` 2026-09-14 coupling paper (Q645 DTW applied): depth to water 10.4 m, PFOS transit centuries, PFOA decades -- the legacy claim is now a PFOS claim
- `5c2e8a29f` 2026-09-14 coupling paper (Q645 DTW): recompute vadose transit times from the corrected depth; control reproduces the published numbers
- `3b1f7fa98` 2026-09-14 coupling paper (Q645 ruling 7 voided -> fixes): keep 29 stations on 20 reaches; cite the data, say 'sampled', deposit the file
- `7bae2ad68` 2026-09-14 coupling paper (Q645 Q1): reproducible Rogue depth-to-water generator -- and it does not reproduce the paper's 31 m
- `dc748d35b` 2026-09-14 coupling repro (Q645 rulings 9 + 11): ship the SWAT+ deck with the calibration's run settings
- `ef987b607` 2026-09-14 coupling repro (Q645 A1): stop skipping SWAT+ temperature inputs (.tmp) in the Rogue model bundle
