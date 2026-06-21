# Stand-level production fit results

**Run:** 2026-06-21, Cardinal job 11903553, `stand_state_v3_production.R`.
**Data:** `conus_remeasurement_pairs_metric_cond_v2.rds`, 8,221,649 tree rows, 110,494 plot pairs
(ntree >= 5, finite SDImax). Plot key `plot_key`, maximum SDI from `SDImax_brms`.

The two FIA-fittable stand states for the García-tradition constraint layer. Top height is not
fit here; it is carried from the tree-level height-growth model over the dominant cohort, because
the FIA plot top-height increment is measurement-noise limited.

## Density self-thinning (power form on relative density)

`ln(N2) = ln(N1) - rate * RD^p * dt`, RD = SDI / SDImax.

- rate = 0.4525 per year, p = 2.73
- RMSE on ln(N) = 0.643, R-squared = 0.603 (n = 102,055)
- Annual loss: 1.68%/yr at RD 0.3, 11.2%/yr at RD 0.6, 45.2%/yr at RD 1.0

This reproduces the 2026-06-11 prototype and is the strongest stand-level result. It is the
self-thinning limb; net density couples to the ingrowth count (ingrowth adds, this removes).

## Basal area (monomolecular toward an SDImax carrying capacity)

`BA2 = BA1 + (Gmax - BA1)(1 - exp(-k * dt))`, Gmax = g0 + g1 * SDImax.

| model | Gmax | rate k | increment R-squared | RMSE |
|---|---|---|---|---|
| baseline (constant k) | 0.0 + 0.036 * SDImax | 0.0529/yr | 0.132 | 8.17 |
| with rate drivers | 2.2 + 0.036 * SDImax | exp(-3.325 + 0.426 z(dH) + 0.116 z(N1)) | 0.184 | 7.92 |

The carrying-capacity coefficient g1 is positive and stable (0.036), confirming basal-area
dynamics are governed by the stand's own size-density limit, not a height site index. Adding the
top-height increment and stem density as rate drivers (the refinement flagged in the strategy
memo) raises the increment R-squared from 0.132 to 0.184. The height increment is the dominant
positive driver of the basal-area growth rate, density a smaller positive contributor.

## Artifacts

- `stand_state_production_fit.rds` — full coefficient list and fit statistics.
- `stand_state_production_summary.csv` — flat summary table.

## Next (integration)

Wire these two states as a one-way diagnostic against `36_conus_benchmark.R`: run the stand
equations alongside the summed tree-level projection and flag divergence, before any constrained
disaggregation. Carry both states through the same posterior-draw uncertainty path as the tree
components.
