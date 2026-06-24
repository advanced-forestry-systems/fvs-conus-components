# Modifier landing manifest (62m inputs) and validation

**Date:** 2026-06-22
**Status:** landing writer validated by dry-run; production write not yet done (gated on the base
species-free landing and the engine hook, see below).

## Validation

Ran `scripts/62m_modifier_to_variant_json.R` as a dry-run for the hardest case (HCB,
trait-mediated) on variant ne. It produced a correct `categories_conus_sf_modifier.height_crown_base`
block: form traitmed, alpha_0 = 0.011, the eight disturbance alphas (fire +0.28, plant -0.16,
wind +0.11, cutting +0.06, the rest near zero), trait_mediated_types = plant, insect, harvest,
cutting, P_trait = 8, and the trait_gamma_alpha matrix, with the base-gamma standardization copied
in. Output written to fvs-modern/config/calibrated/ne.sf_preview.json. The writer works end to end.

## Production input paths on Cardinal (scratch: fvs-conus_output_conus/)

The authoritative decision is HCB trait-mediated, all others common. Exact summaries:

| component | form | summary file(s) |
|---|---|---|
| HCB | traitmed | hcb/modifier_traitmed/hcb_speciesfree_traitmed_lambda10_global_summary.csv + _gamma_summary.csv; base_gamma sf_integration/hcb_v2split_sf_gamma.csv |
| CR | common | cr/modifier_common_prod/cr_speciesfree_modifier_lambda10_summary.csv |
| DG | common | dg/modifier_common_v8_for_loo/dg_kuehne_v8_modifier_lambda10_summary.csv |
| HG | common | hg/modifier_common_v5_prod/hg_organon_v5_modifier_lambda10_summary.csv |
| mortality | common | mort/modifier_common_prod/mort_speciesfree_plotlevel_modifier_lambda10_summary.csv |
| ingrowth | common | ingrowth/modifier_common_prod/ingrowth_v4_plotlevel_modifier_lambda10_summary.csv |

(Trait-mediated _prod summaries also exist for every component for reference, but the decision
selects them only for HCB.)

## Why production landing is not done yet

A grep of fvs-modern/config/calibrated/ne.json shows no `categories_conus_sf` block, so the base
species-free equations are not landed in the configs either. Landing a modifier block onto a config
that lacks the base block, served to an engine that has no modifier hook, would be inert. The three
must land together:

1. Land the base species-free block per component into each variant config (62c), production write.
2. Land the modifier block per component (62m), production write (HCB traitmed, others common). 62m
   backs up each config to .json.pre_mod_<ts>; run dry-run preview per variant first.
3. Add the engine modifier hook in fvs-modern so it applies
   mult = exp(alpha_0 + alpha[type] + (traitmed ? W . gamma[type] : 0)) to the base prediction when
   a disturbance or treatment is active, and confirm it reads the base block.
4. Validate base x modifier on held-out disturbed and treated plots, by component and type.

## Remaining modifier fitting items

- Refresh Manuscript Table 1 to the production paired-LOO decision (corrects the smoke-era CR
  result, which the authoritative table resolves to common).
- Matched-N mortality refit (the common-vs-traitmed mortality comparison had a huge se_diff;
  confirm on matched N).
- A multi-component dry-run that chains all six blocks into one preview per variant currently needs
  62m to read the preview when present (it reads the base config each call), a small writer tweak.
