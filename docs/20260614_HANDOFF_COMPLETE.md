# Complete handoff: CONUS-unified FVS component equations

**Date:** 2026-06-14
**Purpose:** single pickup point for the CONUS-variant program. Captures the goal, where every piece
stands, what was decided, where the code and data live, the operational constraints, and the
prioritized next steps. Read this first; the topical memos below carry the detail.

## 1. The goal

One CONUS-unified FVS variant whose tree-level and stand-level component equations predict short- and
long-term stand development for all US species more accurately than the 20 regional FVS variants and
than Greg Johnson's CONUS equations, with calibrated uncertainty. Two flavors run through every
component: tree-level vs stand-level, and species-dependent (per-species) vs species-independent
(trait-driven / species-free), combined per species by a shrinkage blend w = n/(n+kappa).

## 2. State of play, one paragraph

The component equations are essentially built; three tree-level components have a validated
improvement waiting on a production refit; the stand-level constraint layer is prototyped but not yet
integrated. The clean benchmark shows the unified equations already beat the regional NE and ACD
variants on basal area (-0.6% bias vs +12-13%). Our diameter growth is competitive with Greg's
species-specific model on Douglas-fir, and the species-free leg lands within ~22% of it on a species
it has never seen. The maximum-SDI thread is finalized and now wired into the integration path: a
localized, FIA-derived maximum predicts observed self-thinning ~85% better than FVS species-weighting,
and a per-stand lookup-and-keyword module is committed. The two steps that remain to fully win are
confirming the maximum-SDI fix on a Western variant and injecting the species-free equations into the
engine (currently the engine is driven through multipliers + SDIMAX, not the trait forms directly).

## 3. What was delivered this session

1. **Localized max-SDI module, committed.** `calibration/sdimax/localized_sdimax.py` in fvs-modern,
   branch `feat/conus-sf-integration` (PR #70). Resolves a per-stand maximum SDI from the TreeMap 30 m
   raster, the brms FIA plot table, or a forest-type+geography fallback, and emits the FVS SDIMAX
   keyword block. Model-agnostic. With `calibration/sdimax/README.md`.
2. **USFS technical report on maximum SDI.** `20260614_USFS_maxSDI_technical_report.md` (also in the
   repo as `calibration/sdimax/CONUS_MAXSDI_TECHNICAL_REPORT.md`). Background, the +28% bias and
   near-zero plot skill, the non-circular self-thinning validation (85% better), the model-agnostic
   recommendation, FVS implementation, and the proposed Western-variant confirming test. Ready to send
   to the FVS staff.
3. **Consolidated component-equations assessment.** `20260614_CONUS_component_equations_assessment.md`.
   The full two-by-two (tree/stand x dependent/independent) with status, the Greg comparison, the
   benchmark verdict, and the maximum-SDI update folded into the stand-level layer.
4. **This handoff.**

## 4. The maximum-SDI result (finalized)

Maximum SDI is not observable, so the case rests on predictive skill. The FVS species-weighted maximum
is +28% biased with a bias-corrected R-squared of 0.02 (near-zero plot skill). A localized FIA-derived
maximum predicts observed FIA self-thinning ~85% better (deviance explained 0.107 vs 0.058), winning
in every region. Forest type and geography drive the maximum (R-squared 0.25 combined); site class is
irrelevant (0.02).

Regional FVS projection demonstrations (PN, CR, SN) and a scale diagnostic refined the recommendation:
the raw localized maximum helps PN (density RMSE 35->26% in dense stands) but is neutral-to-harmful in
CR and SN, because the FIA maximum's *level* can sit above a native variant's ceiling. The scale
diagnostic showed the FIA *spatial pattern* beats native once the *level* is calibrated (~0.9x raw in
CR: RMSE 47.1 vs 49.0, bias -1.8 vs +9.4). Final recommendation: adopt the localized spatial pattern
and calibrate its level jointly with the density-dependent mortality response (automatic in the unified
fit; a one-parameter regional adjustment for native-variant retrofits). Model-agnostic; in FVS the
value enters via the per-stand SDIMAX keyword. Detail in `20260614_maxSDI_localization_FINAL.md`, the
USFS report, and the FVS-team briefing. Deliverables for the FVS staff:
`20260614_USFS_maxSDI_technical_report.md` and `20260614_FVS_team_briefing_CONUS_equations.md`.

## 5. Benchmark verdict (clean)

The NE/ACD benchmark is trustworthy after the brk_dbh fix (year-0 reproduces observed t1 exactly).
Unified is best on basal area (-0.6% vs native +12-13%); it over-thinned density only because of a
too-low calibrated SDIMAX, confirmed by controlled experiment to be the maximum, not the mortality
multipliers. Replacing the maximum with the localized value returns density to near-unbiased. The
next benchmark step is a Western variant (PN or CR), where the maximum-SDI payoff should be largest.

## 6. Code and data on Cardinal

- `~/fvs-modern/calibration/python/perseus_100yr_projection.py` — benchmark core;
  `run_fvs_projection(..., extra_keywords="")` appends keywords (the SDIMAX injection path).
- `~/fvs-modern/calibration/python/ne_acd_fia_clean.py` — clean NE/ACD benchmark (FIA PREV_PLT_CN
  linkage; `inv_plot_size=1.0`, `brk_dbh=99.0`).
- `~/fvs-modern/calibration/python/ne_brms_sdimax.py` — brms SDIMAX injection.
- `~/fvs-modern/calibration/sdimax/localized_sdimax.py` — the new production module (committed).
- `~/sdimax_selfthin.R` — the definitive non-circular self-thinning test (82,130 plots).
- `~/fvs-conus/data/conus_remeasurement_pairs_metric_cond_v2.rds` — 8.2M rows; has SDImax_brms, SDI1,
  TPH1/TPH2, DBH1, HT1, CR1, SPCD, fvs_variant, BAL, EPA codes, LAT/LON, FORTYPCD, SICOND, YEARS.
- `~/fvs-conus/data/VAR_SDIMAX.csv`, `~/fvs-conus/data/brms_SDImax.csv` (173,740 plot rows).
- `~/fvs-conus/output/conus/dg_kue/v8/dg_kuehne_v8_100k_prod_residuals.rds` — our DG residuals.
- `~/fvs_remodeling/` — Greg Johnson's repo (dg_parms.RDS, df_dg_res.RDS, est_dg).
- TreeMap maximum-SDI surface: Zenodo 10.5281/zenodo.19509367 (the wall-to-wall source for the module).

## 7. Operational constraints (preserve)

- SSH key at `~/Documents/Claude/.ssh-cardinal` (mounted as `.ssh-cardinal`); discover via find, never
  hardcode the session path; re-run the setup block each bash call (no carryover).
- GitHub token at `CRSF-Cowork/_context/.gh-holoros/token`; pipe into `gh auth login --with-token`;
  never in chat or repos. Re-auth each bash session.
- Work on `feat/conus-sf-integration` (PR #70); no commits to main.
- Hard stops: no production config writes, no coefficient changes.
- Do not cancel Aaron's other running Cardinal jobs (v7_qrf, cem2100, cspi_finish). Submitting hits the
  AssocGrpSubmitJobsLimit, so run analyses as background nohup on the login node, not via sbatch.

## 8. Prioritized next steps

1. **Confirm the maximum-SDI fix on a Western variant** (PN or CR): same density benchmark,
   species-weighted SDIMAX vs the localized value. Largest expected payoff; the module is ready.
2. **Adopt the three validated tree-level fixes** (survival senescence, CR2 and HCB annualization) in
   production refits; finalize the ingrowth composition fit.
3. **Wire the stand-level constraint layer** (density + basal area on the localized maximum) as a
   diagnostic-then-constraint.
4. **Finalize kappa per component** for the species blend.
5. **Inject the species-free equations into the engine** (the make-or-break; today the engine runs on
   multipliers + SDIMAX, not the trait forms directly).
6. **Expand the benchmark**: all regional variants with spatial blocking; Greg comparison for height
   growth and across common species on one identical held-out set; short and long horizons.
7. **Uncertainty then release**: posterior + CSPI QRF draws; production config; merge; Zenodo; DOI.

## 9. Key prior memos (detail)

- `20260614_maxSDI_localization_FINAL.md` — the finalized maximum-SDI thread.
- `20260614_CONUS_component_equations_assessment.md` — the two-by-two assessment.
- `20260614_USFS_maxSDI_technical_report.md` — the FVS-staff brief.
- `20260614_vs_greg_johnson_DG_comparison.md` — the Greg head-to-head (Douglas-fir DG).
- `20260611_STRESS_TEST_and_refined_plan.md` — the logic/approach stress test.
- `20260611_CONUS_variant_execution_roadmap.md` — the execution roadmap.
- `20260611_garcia_statespace_review_and_refinements.md` and `20260611_garcia_principles_tree_level.md`
  — García state-space / annualization principles for the stand- and tree-level forms.
- `20260611_ingrowth_and_standlevel_strategy.md` — ingrowth and stand-level strategy.

## 10. Honest bottom line

On the right track, with real wins: clean benchmark, unified beats regional NE/ACD on basal area, DG
competitive with Greg (and species-free remarkably close), maximum-SDI finalized and model-agnostic
with a publishable validation. Two things convert this into "done and winning": confirm the
maximum-SDI fix on the West (near-term, module ready) and inject the species-free equations into the
engine (the larger integration). Everything else is a bounded refit.
