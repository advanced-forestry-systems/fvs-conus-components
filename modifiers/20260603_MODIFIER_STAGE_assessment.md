# Modifier stage: status and integration gap

**Date:** 2026-06-03
**Why this matters:** the FVS-CONUS calibration is TWO layers. Layer 1 is the
species-free base component equations (DG, HG, HT-DBH, HCB, survival, CR,
ingrowth) - what we have been finalizing and integrating. Layer 2 is the
disturbance/treatment MODIFIER stage that adjusts the base prediction
(alpha_insect, alpha_disease, alpha_fire, harvest, etc.). The integration is not
complete until BOTH layers land in the variant configs.

## What is computed (Layer 2)

For each component, two modifier forms were fit and LOO-compared:

- **modifier_common** - a single (species-independent) modifier per disturbance
  type.
- **modifier_traitmed** - a trait-mediated modifier (gamma-modulated by species
  traits, like the base trait_effect).

`*_prod` and `*_for_loo` variants exist per component (cr, dg, mort, ingrowth,
crown_recession, and the crown/height components). The
`loo_compare_common_vs_traitmed*` objects hold the per-component decision.

## The decision (computed 2026-06-03, paired LOO with se_diff)

Verified directly from the `loo_compare_common_vs_traitmed*` objects, using the
PAIRED se_diff (the point-estimate elpd alone is misleading - correlated draws
make the paired SE the right yardstick):

| component | elpd_diff (traitmed - common) | se_diff | SEs | decision |
|---|---:|---:|---:|---|
| HCB (crown base) | +68.0 | 17.8 | 3.8 | **trait-mediated** |
| CR (crown recession) | +24.4 | 12.3 | 2.0 | trait-mediated (borderline) |
| HG (height growth) | +7.5 | 10.0 | 0.7 | common |
| DG (diameter growth) | -11.0 | 8.4 | 1.3 | common |
| ingrowth | +94.8 | 222.5 | 0.4 | common (huge SE -> tie) |
| mortality | +56.2 | 255.0 | 0.2 | common (huge SE -> tie) |

**This confirms the manuscript's central finding:** trait-mediated modifiers ONLY
for the crown components (HCB clearly, CR borderline), common (species-independent)
modifiers for growth, mortality, and ingrowth. The mortality and ingrowth point
estimates favor trait-mediated, but their se_diff is enormous (255, 222), so they
are ties and parsimony selects common - reconciling with the documented
"common is sufficient for mortality." Table saved at
`output/conus/modifier_decision_table.md` on Cardinal.

## The integration GAP

- `62b`/`62c` lands ONLY the base species-free block
  (`categories_conus_sf.{component}`). It does NOT handle modifiers
  (grep for modifier/alpha in 62b = 0 hits).
- So a **modifier landing step is missing**: a `62`-style writer that adds a
  `categories_conus_sf_modifier.{component}` (or similar) block carrying the
  chosen modifier form (common or traitmed) + its coefficients + the disturbance
  type mapping, into each variant config.
- The fvs-modern engine must then apply: base prediction * modifier(disturbance,
  species/traits). Confirm the engine's modifier hook exists (Aaron's recent
  "native per-tree multipliers" Acadian commit suggests the multiplier mechanism
  is being wired).

## Plan to finalize + integrate the modifier stage

1. **Tabulate the common-vs-traitmed LOO decision per component** from the
   `loo_compare_common_vs_traitmed*` objects -> one decision table (which form
   each component uses). Likely: traitmed for crown/recession, common for
   mortality; confirm DG/HG/ingrowth.
2. **Build a modifier bundle** per component (analogous to 61b): the chosen
   modifier's fixed alphas + (if traitmed) trait gammas + disturbance-type map.
3. **Extend the landing writer** (62-style) to add the modifier block to the
   variant configs, dry-run first.
4. **Validate** end to end: base * modifier on held-out disturbed plots.
5. Only then is the integration complete for production.

## Sequencing vs the base equations

The base equations are nearly done (5 of 6 components integration-ready, CR2 and
HG bundle landing). The modifier stage is computed but needs (1) the decision
table, (2) a bundle + landing step. Recommend: finish the base integration first
(it is the foundation), then do the modifier decision table + landing as the
next phase. The deck for Greg/David should show BOTH layers so the modifier
story (the manuscript's central finding) is represented.
