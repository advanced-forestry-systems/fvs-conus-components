# Equation modifier (Layer 2) status and next steps

**Date:** 2026-06-22
**What modifiers are.** The FVS-CONUS calibration is two layers. Layer 1 is the base species-free
component equations (DG, HG, HT-DBH, HCB, CR, survival, ingrowth). Layer 2 is the
disturbance/treatment modifier that multiplies the base prediction when a stand has been disturbed
or treated. Per tree (or plot), the modifier is:

  mult = exp( alpha_0 + alpha[type] + (trait-mediated ? W_species . gamma[type] : 0) )

for type in {plant, fire, insect, disease, wind, harvest, cutting, siteprep}. W is the standardized
species trait vector (same standardization as the base gamma block).

## Status by stage

| stage | state | evidence |
|---|---|---|
| Disturbance condition enrichment | done | R/40,40b,40c_enrich_cond_modifiers |
| Modifier fitting (common + trait-mediated per component) | done; some still smoke, production refits partial | R/51,51b,51c,52,52b,52c; lambda sweep (fit_modifier_common_lambda_sweep_prod.R); lambda10 summaries for DG and ingrowth present |
| Form decision (common vs trait-mediated) | done and authoritative | output/conus/modifier_decision_table.md (paired LOO with se_diff) |
| Manuscript Table 1 | drafted from smoke fits; needs refresh | MANUSCRIPT_TABLE_1_modifier_summary.md |
| Landing writer (configs) | built, never run in production | scripts/62m_modifier_to_variant_json.R (v2, 2026-06-05), dry-run default |
| Engine modifier hook (fvs-modern) | absent | grep modifier/alpha in fvs-modern/calibration = 0 hits |

## The authoritative form decision (paired LOO, traitmed - common)

| component | elpd_diff | se_diff | SEs | decision |
|---|---:|---:|---:|---|
| HCB | +68.0 | 17.8 | 3.8 | trait-mediated |
| CR | +24.4 | 12.3 | 2.0 | tie -> common (parsimony; borderline) |
| HG | +7.5 | 10.0 | 0.7 | common |
| DG | -11.0 | 8.4 | 1.3 | common |
| ingrowth | +94.8 | 222.5 | 0.4 | common (huge SE, tie) |
| mortality | +56.2 | 255.0 | 0.2 | common (huge SE, tie) |

Only HCB earns the trait-mediated modifier. Everything else uses the common (species-independent)
modifier. Important correction: the earlier smoke-fit Manuscript Table 1 reported CR as
overwhelmingly trait-mediated (elpd +558); the production paired-LOO with the correct paired SE
collapsed CR to a tie that parsimony resolves to common. CR is the one borderline case (2.0 SE).
This is the manuscript's central finding, now in its corrected form: trait-mediation matters for
crown base only, not for growth, mortality, or ingrowth.

The alpha signs are sensible where strong: positive growth response to planting and cutting
(release), HCB and CR shifts under planting and cutting; insect/disease/fire/wind/siteprep near
zero on growth.

## Open gaps (the integration is not complete)

1. No modifier block is landed in any variant config. 62m exists but has only ever run dry; no
   `categories_conus_sf_modifier.{component}` block and no `.sf_preview.json` modifier file exists
   in fvs-modern/config.
2. The fvs-modern engine has no modifier hook, so it cannot apply base x modifier. This is the
   Layer-2 analogue of the base species-free engine injection, the same make-or-break.
3. Some modifier fits are still smoke-level; the production refits (and the matched-N mortality
   refit) are not all confirmed complete.
4. Modifiers are not represented in the v2/v3 projector, which projects undisturbed development
   only. A disturbance/treatment scenario path would be needed to exercise them.

## Next steps, ordered

1. Refresh Manuscript Table 1 to the authoritative production paired-LOO decision (HCB
   trait-mediated; CR, DG, HG, mortality, ingrowth common), correcting the smoke-era CR result, and
   complete the matched-N mortality comparison.
2. Confirm or complete the production modifier summaries that 62m consumes: the common alpha
   summary per component, and the HCB trait-mediated global + gamma summaries, at the production
   lambda. Verify they are production, not smoke.
3. Run 62m to land the modifier blocks into the variant configs: HCB as trait-mediated
   (global + gamma + base standardization via --base_gamma), the other five as common. Dry-run
   preview first, then the production write (it backs up each config to .json.pre_mod_<ts>).
4. Add the engine modifier hook in fvs-modern: apply mult = exp(alpha_0 + alpha[type] +
   W . gamma[type] for trait-mediated types) to the relevant base component when a disturbance or
   treatment is active. Parallel to the base injection task.
5. Validate end to end: base x modifier against held-out disturbed and treated plots, by component
   and disturbance type.
6. Optional: add a disturbance/treatment scenario path to the projector so the modifier layer can
   be exercised in projection, not only at the equation level.

## Preservation

Modifier fitting/eval scripts are in this repo under `R/` (40, 51, 52, 60, 62b, 62c, eval_modifier_*).
The single-copy landing writer `scripts/62m_modifier_to_variant_json.R`, the authoritative
`modifier_decision_table.md`, the production lambda summaries, the alpha summary CSVs, and the
strategy and Table 1 docs are preserved here under `modifiers/`.
