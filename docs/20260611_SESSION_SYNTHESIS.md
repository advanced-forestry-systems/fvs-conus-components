# FVS-CONUS session synthesis: decisions, state, and open items

**Date:** 2026-06-11
**Scope:** consolidates a multi-thread working session across site productivity, the species
architecture, the fvs-modern integration, ingrowth, the stand-level layer, and a García
state-space review applied to both the stand and tree levels. This is the single state-of-play.

## 1. Decisions made (with evidence)

- **Production site surface: CSPI v7 (30 m).** v7 distills v6 to a deployable 30 m surface; v8
  adds Sentinel-2 and MOD17 for ~0.001 R2 and is not worth its pipeline. The v7 distillation
  screen showed the surface explains as much or more component residual variance than observed
  site index. Keep v6 (1 km, R2 0.75) as the accuracy reference.
- **Species architecture: pure species-free (trait-driven) everywhere, with a per-species
  blend.** The Leg A vs Leg B stress test made species-independent operationally equal or better
  for every component, with a meaningful per-species hybrid only for CR. The engine carries both
  legs and a shrinkage weight w = n/(n+kappa), stress-test defaults for kappa (your call).
- **Stand-level layer: density and basal area are fit from FIA; top height is not.** Stem counts
  and basal-area sums are estimated precisely on FIA plots, so density self-thinning (R2 0.60)
  and SDImax-driven basal area both work. Top-height growth cannot be fit from FIA pairs because
  the plot is too small to pin top height to better than ~1 m while the increment is only ~1.2 m;
  derive top height from the tree-level HG model applied to dominant trees instead.
- **The hierarchical Bayesian calibration already embodies García's global/local GADA structure**
  (trait fixed effects global, species and ecoregion random effects local). No change, just
  recognition.

## 2. García state-space refinements, applied

- **Annualization audit (tree level):** DG, HG, survival, and ingrowth are properly annualized;
  survival is exemplary (an integrated hazard). HCB is static (path invariant but not a rate).
  CR2-direct was the one gap.
- **CR2 annualization fixed and validated.** Replaced the interval-free form with the
  exponential approach `logit(CR2) = E + (logit(CR1) - E) exp(-k T_years)`. Validation: k = 0.064
  per year (adjustment half-life ~11 years), path invariant to machine precision, correct zero
  interval behavior. Stan model committed; production current-vs-annualized ΔLOO is queued.
- **Basal area driver corrected** from CSPI to SDImax carrying capacity (sign fixed, increment
  R2 up to 0.13); **density** sharpened to an accelerating power form on relative density.
- **Measurement error is the top-height lesson, and it generalizes.** The negative top-height
  increment skill was observation noise, not model failure (measurement variance on the
  difference exceeds the increment variance). The same caution applies to the height components
  (HG, HT-DBH), which sit on error-prone FIA height; the reducible-SDE / measurement-error refit
  is the refinement. García's own `resde` needs an age origin and does not transfer to age-free
  data, so an errors-in-variables GADA is the right tool.

## 3. Integration into fvs-modern

Draft PR #70 on `feat/conus-sf-integration` carries: the integration strategy (per-cycle engine
flow with the stand-level constraint layer and disaggregation), the JSON config schema (both
legs, blend, modifier, posterior draws), the exporter and uncertainty skeletons, the stand-state
transition reference forms, the annualized CR2 Stan model, and the García reviews (stand and tree
level). The engine design: a coupled state-space stand layer (density and basal area) sets the
aggregate envelope, the species-free tree components fill it by disaggregation, top height comes
from the tree-level HG, and uncertainty propagates posterior draws plus CSPI v7 QRF site draws.

## 4. Jobs in flight (tracked by the twice-daily watch)

- `hg_v6_loo_fast`, `hcb_v6_loo_fast`: CSPI v6 ΔLOO at 20k rows (the full-data versions all timed
  out). Decide whether HG and HCB adopt the new site term.
- `ingrowth_compos_prod`: trait-driven composition at 10k plots, top 50 species (smoke validated).
- `cr2_ann_loo`: current vs annualized crown-ratio held-out comparison.
- The v7 QRF interval render had a task failure and needs a rerun before it can feed the
  uncertainty path.

## 5. Prioritized open items

1. Read the watch results: HG/HCB site-term decision, the CR2 annualization ΔLOO, the composition
   fit. These gate the next config writes.
2. Rerun the v7 QRF interval render (failed task) so the site-uncertainty surface is complete.
3. Promote the validated pieces into the exporter: density self-thinning, SDImax basal area,
   annualized CR2, the species-free components with the blend, the v7 site term.
4. Measurement-error refit of the height components (HG, HT-DBH) in the errors-in-variables
   spirit; derive stand top height from tree-level HG rather than a separate equation.
5. Build the coupled stand-level state-space module (density and basal area) and wire it as the
   Phase A diagnostic against `36_conus_benchmark.R` before any constrained disaggregation.
6. When the gating results settle: production config write, GitHub merge, Zenodo new version,
   DOI backfill.

## 6. Deliverables produced this session (in this folder)

- `20260611_assessment_cspi_and_model_comparison.md`
- `20260611_site_productivity_reassessment.md`
- `20260611_conus_sf_integration_design.md`
- `20260611_fvs_modern_integration_strategy.md`
- `20260611_ingrowth_and_standlevel_strategy.md`
- `20260611_garcia_statespace_review_and_refinements.md`
- `20260611_garcia_principles_tree_level.md`
- this synthesis

All hard stops respected: no production config writes, no coefficient changes, no merges to main.
Work landed on the draft PR and as dated memos; compute jobs are subsampled prototypes and
confirmatory fits on your allocation, tracked by the watch.
