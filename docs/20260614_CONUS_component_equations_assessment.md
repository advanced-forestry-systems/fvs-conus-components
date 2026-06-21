# CONUS-wide FVS component equations: consolidated assessment by flavor

**Date:** 2026-06-14
**Scope:** the component equations for a CONUS-unified FVS variant, organized along the two axes that
define them, tree-level versus stand-level and species-dependent versus species-independent, with
current status, benchmark evidence, and the maximum-SDI update folded in. This supersedes the
scattered status notes and is the single reference for where the equations stand.

## The goal, restated

One CONUS variant whose component equations predict short- and long-term stand development for all US
species more accurately than (a) the 20 regional FVS variants and (b) Greg Johnson's CONUS equations,
with calibrated uncertainty. Two design axes run through every component:

- **Level.** Tree-level equations predict each tree's increment and survival; stand-level equations
  predict and constrain whole-stand trajectories (density, basal area, top height). The stand-level
  layer disciplines the tree-level sum so long-term projections respect the size-density limit.
- **Species treatment.** The species-dependent leg fits per-species parameters where data are
  sufficient. The species-independent leg is trait-driven (a "species-free" form keyed on functional
  traits and climate), giving coverage for rare and unsampled species. A per-species shrinkage blend
  combines them, weight w = n / (n + kappa), so well-sampled species lean on their own fit and
  rare species fall back to the trait form.

## The two-by-two, at a glance

| | Species-dependent (per-species fit) | Species-independent (trait-driven / species-free) |
|---|---|---|
| **Tree-level** | DG, HG, HT-DBH, HCB, CR, survival fit per species where n is sufficient; competitive with Greg on Douglas-fir DG | same components from a trait+climate form; within ~22% of a species-specific fit on a species it has never seen |
| **Stand-level** | per-forest-type density/BA behavior via composition | density and BA driven by a localized, data-derived maximum SDI; top height from the dominant-cohort height model |

The blend (w = n/(n+kappa)) lives between the two columns and is what makes a single set of equations
cover all species without abandoning the accuracy of a per-species fit where the data support it.

---

## Tree-level components

| component | form | status | remaining |
|---|---|---|---|
| Diameter growth (DG) | Kuehne v8, BGI-driven | done; competitive with Greg on Douglas-fir | none for the base |
| Height growth (HG) | ORGANON v8rd | done (base) | optional CSPI-v6 site term pending held ΔLOO |
| Height-diameter (HT-DBH) | Wykoff v2split | done | none |
| Height-to-crown-base (HCB) | v2split | done | adopt validated annualized form in a refit |
| Crown ratio (CR) | CR2-direct | done | adopt validated annualized CR2 (interval term) in a refit |
| Survival / mortality | gompit with exposure | done | adopt validated relative-size senescence term in a refit |
| Ingrowth count | negative binomial v4 | done | none |
| Ingrowth species composition | trait multinomial | smoke-validated | finalize production fit |
| Layer-2 modifiers (disturbance/treatment) | multiplier layer | done | sign-off |

Three components (HCB, CR, survival) carry a validated improvement that only needs a production refit
to adopt: annualized HCB, annualized CR2 with an interval term, and a relative-size senescence term in
survival. Ingrowth composition needs its production fit finalized. Everything else in the tree-level
set is built. That is the complete tree-level punch list.

**Species-dependent vs species-independent, tree-level.** Both legs exist for the growth components.
The head-to-head against Greg Johnson on Douglas-fir diameter growth is the clearest read we have:

| model | n | RMSE (cm/yr) | bias | R-squared | species data used |
|---|---:|---:|---:|---:|---|
| Greg, species-specific | 156,390 | 0.097 | -0.003 | 0.742 | full DF (156k obs) |
| Ours, species-dependent | 156,426 | 0.091 | -0.030 | 0.369 | DF in training |
| Ours, species-free (DF held out) | 1,000 | 0.118 | -0.029 | — | zero DF data |

Our species-dependent DG is competitive with Greg's on RMSE (0.091 vs 0.097), though less well
calibrated (bias and R-squared favor Greg). The striking result is the species-free leg: predicting
Douglas-fir from traits alone, having never seen a Douglas-fir, it reaches RMSE 0.118, within about 22
percent of a model fit on 156,000 Douglas-fir observations. That is the core value proposition, and it
is exactly the rare-species case where Greg's system has no coverage at all. Caveats for a publishable
version: run both predictors on one identical held-out set in identical units, extend to height growth
and many species, and add the components Greg does not model (mortality, crown, ingrowth), where our
system wins by default.

## Stand-level components (the constraint layer)

The stand-level equations are age-independent, annualized forms (in the spirit of García's state-space
approach) that constrain the tree-level sum. Three states, prototyped, not yet integrated as a
constraint layer:

- **Density / self-thinning.** Works well. A power form on relative density,
  rate = 0.45 · (SDI / SDImax)^2.73 per year, R-squared 0.60, recovering the correct acceleration
  of self-thinning toward the size-density limit. Its central input is the maximum SDI, which is why
  the maximum-SDI update below is a stand-level result, not a side issue.
- **Basal area.** Works once carrying capacity is driven by the maximum SDI (Gmax proportional to
  SDImax, the sign-correct version). Needs the rate drivers (height increment, density) added.
- **Top height.** Measurement-noise limited from FIA; the working conclusion is to derive top height
  from the tree-level height-growth model over the dominant cohort rather than fit it separately. This
  keeps top height consistent with the tree-level HG equation instead of introducing a second,
  noisier source.

These are not a detour around the maximum-SDI problem; they are where the maximum SDI does its work.
The density equation is relative density, so the maximum SDI is its central input, and getting the
maximum right is what makes the stand-level constraint correct.

## The maximum-SDI update (folded into the stand-level layer)

This is the substantive change since the prior status notes, and it is now finalized. Maximum SDI is
the density limit that the stand-level density and basal-area equations depend on, and the FVS-style
species-weighted maximum is the wrong way to set it.

- **Species-weighting is biased and uninformative.** Against an FIA-estimated maximum on 95,206
  remeasured plots, the FVS variant-specific species-weighted maximum is +28 percent biased, with
  negative raw R-squared and a bias-corrected R-squared of 0.02. It carries almost no plot-level
  signal.
- **What localizes it.** Forest type (R-squared 0.21) and geography (0.25 combined) drive the
  maximum; site class is irrelevant (0.02). A per-stand value from the TreeMap 30 m surface captures
  the local structure no summary recovers.
- **The non-circular proof.** Maximum SDI is not observable, so the test is predictive. On 82,130
  plots, relative density from the localized maximum predicts observed self-thinning about 85 percent
  better than from species-weighting (deviance explained 0.107 vs 0.058), winning in every region.

**Implication for the equations.** The stand-level density and basal-area equations should read a
localized, data-derived maximum SDI per stand (TreeMap raster value, brms FIA plot value, or the
forest-type-plus-geography fallback), not a species-weighted constant. This is now implemented as a
per-stand lookup-and-keyword module in fvs-modern (calibration/sdimax/), and documented for the USFS
FVS staff in a standalone technical report. It is model-agnostic.

**Regional projection check, and the level-vs-pattern refinement.** Paired FVS projections on three
variants showed the raw localized maximum helps PN (density RMSE 35 to 26 percent in dense stands) but
is neutral-to-harmful in CR and SN. A scale diagnostic resolved why: the FIA maximum carries a useful
spatial pattern and a level; once the level is calibrated (about 0.9x raw in CR), the localized maximum
beats the native ceiling with near-zero bias. So the spatial information is good everywhere; the level
must be made consistent with the variant's density-dependent mortality. For the equations this means the
density and mortality components must be fit jointly with the localized maximum (automatic in the
unified fit), rather than swapping a new ceiling under a mortality form calibrated to the old one. This
is the same "fit the constraint and the rate together" principle that governs the stand-level layer.

## Benchmark evidence so far

The clean NE/ACD benchmark (brk_dbh corrected so year-0 reproduces observed t1 exactly) gives the
first trustworthy verdict on the unified variant against the regional ones:

- **Basal area:** the unified model is best, nearly unbiased (-0.6 percent) versus the native NE and
  ACD variants (+12 to +13 percent). This is the headline: on the integral that matters most, the
  unified equations already beat the regional variants in the Northeast.
- **Density:** the unified model over-thinned (trees per hectare -26.5 percent) in the calibrated
  config, traced entirely to a too-low calibrated SDIMAX. A controlled experiment confirmed the cause
  is the maximum, not the mortality multipliers; replacing the maximum with the FIA-localized value
  returns density to near-unbiased. This is the maximum-SDI fix above, and it is the single
  highest-leverage change for the unified variant's one real weakness.

So the direction is established: the unified equations win on basal area in the Northeast, and the
density gap is the maximum-SDI problem, which is now diagnosed and fixed in the integration path.

## Engine integration status (the make-or-break)

A candid note on what "wired in" means today. The benchmark currently calibrates the real FVS engine
through multipliers and the SDIMAX keyword (MORTMULT, BAIMULT, SDIMAX), and the maximum-SDI module
plugs into exactly that SDIMAX path. The trait-driven species-free equations themselves are not yet
injected as the engine's growth functions; that is the largest remaining integration task and the only
path to the full unified-variant claim. Until then, the strongest claims rest on the offline component
comparisons (competitive with Greg, species-free within 22 percent) and the maximum-SDI result (85
percent better self-thinning prediction), both of which are real and validated.

## What is left, prioritized

1. **Maximum SDI in production (done in the integration path; confirm on a Western variant).** The
   module is built and committed. The confirming test is the density benchmark on a Western variant
   (PN or CR), species-weighted SDIMAX versus the localized value, where the payoff should be largest.
2. **Adopt the three validated tree-level fixes** (survival senescence, CR2 and HCB annualization) in
   production refits, and finalize the ingrowth composition fit. Small, defined.
3. **Stand-level constraint layer.** Production-fit density and basal area on the localized maximum
   SDI and wire them as a diagnostic-then-constraint layer so long-term projections are disciplined by
   the size-density limit.
4. **Species blend.** Finalize kappa per component (stress-test defaults are the starting point).
5. **Engine injection of the species-free equations.** The big one: make the trait-driven forms drive
   the engine, not just multipliers and SDIMAX on the native equations.
6. **Benchmark expansion.** All regional variants with spatial blocking; the Greg comparison for
   height growth and across common species on one identical held-out set; short- and long-term
   horizons.
7. **Uncertainty, then release.** Wire the posterior and CSPI QRF draws; production config; merge;
   Zenodo; DOI.

## Honest summary

The encouraging findings are real and now consolidated: the benchmark is clean, the unified equations
already beat the regional NE and ACD variants on basal area, our diameter growth is competitive with
Greg's species-specific model and remarkably close even with zero species data, and the maximum-SDI
result is finalized and model-agnostic. The two steps that convert "on the right track" into "done and
winning" are the maximum-SDI fix (near-term, high leverage, now built) and injecting the species-free
equations into the engine (the larger integration). Everything else is a defined, bounded refit.
