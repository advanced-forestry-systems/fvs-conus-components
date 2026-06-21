# fvs-conus-components

Analysis code for the CONUS-unified FVS variant component equations program: tree-level and
stand-level growth, mortality, crown, ingrowth, and a García-tradition stand-level constraint
layer, plus the localized maximum-SDI work and the head-to-head against Greg Johnson's CONUS
equations.

This repository preserves code that previously existed only as loose, unversioned scripts on
the OSC Cardinal home directory (`crsfaaron@cardinal.osc.edu`). It is code only. The large
inputs and model outputs (remeasurement pairs, residual objects, rasters, FVS runs) stay on
Cardinal scratch and, for deliverables, on Zenodo.

## Goal

One CONUS variant whose tree-level and stand-level component equations predict short- and
long-term stand development for all US species more accurately than the 20 regional FVS
variants and than Greg Johnson's CONUS equations, with calibrated uncertainty. Two design axes
run through every component: tree-level vs stand-level, and species-dependent (per-species) vs
species-independent (trait-driven), combined per species by a shrinkage blend w = n / (n + kappa).

## Layout

| Path | Contents |
|---|---|
| `R/` | The full component pipeline (170 scripts): dataset build, DG, HG, HT-DBH, HCB, CR, survival, ingrowth count and species composition, modifiers, benchmarks. |
| `stand_level/` | García state-space stand-level prototypes: top-height GADA, density self-thinning, basal area, mortality by relative size, measurement-noise diagnostics, `resde` test. |
| `standlevel_drivers/` | Driver and fit scripts run from Cardinal home: joint max-SDI plus mortality, unified joint fit, SDImax comparisons, `resde` API, ingrowth composition recovery. |
| `greg_comparison/` | Head-to-head against Greg Johnson's `fvs_remodeling` (diameter and height growth). |
| `acadian_gy/` | AcadianGY model versions 12.3.6 through 12.5.0 and the ingrowth-fix patch. |
| `docs/` | Strategy memos, the García state-space review, the component-equations assessment, the ingrowth and stand-level strategy, the max-SDI thread, and the June 2026 handoffs. |

## Where the work stands (June 2026)

Tree level is essentially built; three components (survival senescence, CR2 annualization, HCB
annualization) carry a validated improvement awaiting a production refit. Ingrowth count
(negative binomial v4) is done; species composition is smoke-validated and needs its production
fit as a trait-driven compositional model. The stand-level layer is prototyped: density
self-thinning (rate = 0.45 * RD^2.73 per year, R-squared on ln(N) about 0.60) and basal area
(carrying capacity driven by SDImax) are the FIA-fittable states; top height is carried from the
tree-level height-growth model rather than fit separately, because the FIA plot top-height
increment is measurement-noise limited. The localized maximum-SDI result is finalized and lives
in `holoros/fvs-modern` (`calibration/sdimax/`).

See `docs/20260614_HANDOFF_COMPLETE.md` for the single pickup point and
`docs/20260614_CONUS_component_equations_assessment.md` for the full status by component.

## Data and compute

All fitting runs on Cardinal. Inputs and outputs are not in this repository:

- Remeasurement pairs: `~/fvs-conus/data/conus_remeasurement_pairs_metric_cond_v2.rds`
- Max-SDI tables: `~/fvs-conus/data/VAR_SDIMAX.csv`, `~/fvs-conus/data/brms_SDImax.csv`
- DG residuals: `~/fvs-conus/output/conus/dg_kue/v8/dg_kuehne_v8_100k_prod_residuals.rds`
- Stand-level fit objects: `/fs/scratch/PUOM0008/crsfaaron/fvs-conus_output_conus/stand_level/`
- Greg's repo for comparison: `holoros/fvs_remodeling`

## Related repositories

- `holoros/fvs-modern` — the FVS engine and the committed localized max-SDI module.
- `holoros/cspi-conus` — the Composite Site Productivity Index surface used as the site driver.
- `holoros/fvs_remodeling` — Greg Johnson's CONUS equations (comparison baseline).
