# Localizing maximum SDI: a model-agnostic recommendation (finalized)

**Date:** 2026-06-14
**Question:** outperform the species-weighted maximum-SDI approach, and make the recommendation
general (not FVS-specific), since species-weighting is how most growth-and-yield models set the
density limit.

## The decisive comparison

Using the brms FIA plot-level max SDI as the reference, on 95,206 remeasured plots, comparing the
FVS variant-specific species-weighted max SDI (from the uploaded VAR_SDIMAX, BA-weighted over each
plot's species, 88 percent of trees matched) against a localized model:

| approach | mean (trees/ha) | bias vs FIA | R2 | bias-corrected R2 |
|---|---:|---:|---:|---:|
| FIA brms (reference) | 869 | — | — | — |
| FVS species-weighted (variant-specific) | 1110 | **+28%** | **-0.61** | **0.02** |
| Localized: forest type + geography | — | — | **0.20** | — |
| Localized + species-weighted added | — | — | 0.26 | — |

Two facts, both decisive:

1. **Species-weighting over-estimates the maximum by about 28 percent and has negative R2.** A
   negative R2 means it predicts the real plot maximum worse than simply using the overall mean. The
   per-species maximum-SDI constants are set as conservative upper bounds for pure stands, so
   basal-area-weighting them across a mixed, real stand systematically over-states the achievable
   maximum.
2. **Even after removing that bias, species-weighting explains only 2 percent of the plot-to-plot
   variation.** It carries essentially no information about where the real maximum is. A localized
   forest-type-plus-geography model explains 20 percent, ten times more, and a per-stand value from
   a wall-to-wall surface captures the full local structure that no summary recovers.

So the species-weighted approach is not merely missing regional variation, as suspected; it is
biased high and has near-zero skill at the plot level. The localization is not a refinement, it is
the fix.

## The observability problem, and the test that actually settles it

Maximum SDI is not directly observable. It is a latent quantity estimated under assumptions, so
comparing two estimates of it by how well one reproduces another (the R2-against-brms above) is
partly circular. The brms estimates are robust and defensible, but the question that matters is not
which estimate is "right," it is whether using one rather than the other **improves the
growth-and-yield prediction**. That test uses observed data as truth and is not circular.

So I ran it directly: relative density is SDI divided by maximum SDI, and it is the variable that
drives self-thinning, so the better maximum SDI is the one whose relative density better predicts the
**observed** density loss in FIA remeasurement. On 82,130 remeasured plots, predicting observed
annual density change:

| region | n | deviance explained, RD from brms | deviance explained, RD from FVS species-weighted |
|---|---:|---:|---:|
| All | 82,130 | **0.107** | 0.058 |
| East | 62,062 | **0.124** | 0.072 |
| West | 20,068 | **0.057** | 0.034 |

The localized brms maximum predicts observed self-thinning about 85 percent better than FVS
species-weighting, and it wins in every region, East and West. The correlation of relative density
with observed mortality is also higher for brms everywhere (0.33 vs 0.24 overall). This is the
non-circular confirmation: the localized maximum does not just match a preferred estimate, it
measurably improves the prediction of the density dynamics the model exists to reproduce.

A mechanism note that ties the two SDImax problems together. The native FVS species-weighted maximum
is too high (+28 percent), so its relative density is too low and it under-predicts self-thinning;
the separately calibrated SDIMAX inside the engine config was too low and over-predicted self-thinning
(the earlier over-thinning result). The two FVS-side sources err in opposite directions, and the brms
localized maximum sits between them and predicts observed self-thinning best. That is the case for
localization made on the only ground that is not circular: predictive skill against observed data.

## Why this is general, not an FVS quirk

This is not specific to FVS. Any growth-and-yield model that builds its density limit by weighting
fixed per-species maximum-SDI constants by composition inherits the same two problems: the upward
bias from averaging pure-stand upper bounds, and the absence of any location signal. ORGANON, the
regional FVS variants, and a naive CONUS model would all behave this way. The lesson is about the
*method* of setting the maximum, not about one model.

## The model-agnostic recommendation

Treat the maximum SDI as a **localized, data-derived stand attribute**, looked up by location and
composition, rather than computed from per-species constants inside the model. This decouples the
density limit from any one model's species table and lets any growth-and-yield engine consume it.

Concretely, in order of fidelity:

1. **Per-stand value from a wall-to-wall surface (best).** Assign each stand the maximum SDI at its
   coordinates from a published FIA-derived surface. Your own TreeMap-based 30 m CONUS SDImax raster
   (Zenodo 10.5281/zenodo.19509367) is exactly such a product; the brms FIA plot values are its
   plot-level form. This captures the full local and regional structure (the part no summary
   recovers) and is reusable by any model, because it is just a number attached to a location.
2. **Composition-and-geography model (compact, portable).** Where a closed form is wanted, maximum
   SDI as a function of forest type plus a spatial smooth (R2 0.20) already beats species-weighting
   decisively and travels as a small table or function. Note that site class adds nothing
   (max SDI is not a productivity quantity), so do not include it.
3. **What to avoid:** the species-weighted constant approach, in any model. It is biased high and
   uninformative about the real maximum.

## How it plugs in and how to prove it

- **Plug-in:** the growth model reads the localized maximum SDI per stand (raster lookup or the
  composition-geography function) and uses it as the density limit for self-thinning and relative
  density. In FVS specifically this is the SDIMAX keyword per stand, which the benchmark run path now
  injects; in any other model it is the stand's max-SDI input. The decoupling is the point.
- **Proof:** the density benchmark. The Northeast showed FVS species-weighting is roughly adequate
  there (so the localized value should at least tie), but this analysis says the bias and lack of
  skill are general, so the localized value should win clearly where species-weighting is most
  wrong, the West and structurally complex mixed stands. The next step is the same density benchmark
  on a Western variant (PN or CR), species-weighted SDIMAX versus the localized value, where the
  localized surface should reduce both the density bias and the over-thinning.

## Bottom line for the thread (finalized)

Maximum SDI is not observable, so the case rests on predictive skill, and there it is settled. The
brms localized maximum predicts observed FIA self-thinning about 85 percent better than the FVS
species-weighted maximum, in every region. Separately, species-weighting is biased about 28 percent
high and explains almost none of the plot-level maximum-SDI variation. Both lines point the same way.

The generalizable recommendation, to carry forward and not revisit:

- **Set the density limit from a localized, data-derived maximum SDI, not from composition-weighted
  per-species constants.** Use the per-stand value from a wall-to-wall FIA-based surface (your
  TreeMap 30 m SDImax raster, with the brms plot values as its FIA-plot form) where available, and a
  forest-type-plus-geography function as the portable fallback. Do not use site class; it carries no
  signal for the maximum.
- **This is model-agnostic.** Any growth-and-yield model reads the localized maximum as a per-stand
  input to its relative-density and self-thinning logic. In FVS it is the SDIMAX keyword per stand
  (the run path now injects it); in any other engine it is the stand's max-SDI input. The point is to
  decouple the density limit from the model's internal species table.
- **It is validated on the only criterion that is not circular:** improved prediction of observed
  density dynamics. The brms localized maximum delivers that improvement nationally.

This finalizes the SDImax thread: localize the maximum from FIA-derived data per stand, feed it to
the growth model as the density limit, and it measurably improves the self-thinning prediction over
the species-weighted approach used by FVS and most other growth-and-yield models.
