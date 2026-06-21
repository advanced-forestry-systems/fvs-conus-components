# Deep scan: what is actually wired into FVS and currently running

**Date:** 2026-06-21
**Question:** confirm what was actually wired into FVS and is currently running, with specific
refinement recommendations.

## The central finding: two distinct things are both called "the engine"

The word "engine" is being used for two different systems, and separating them answers the
question.

**1. The FVS Fortran engine (holoros/fvs-modern).** What is actually compiled into and wired
through the real FVS engine is narrow: the localized maximum-SDI keyword module
(`calibration/sdimax/localized_sdimax.py`, emits the SDIMAX keyword block) plus the multiplier
hooks (MORTMULT, BAIMULT, SDIMAX). The trait-driven species-free growth, mortality, crown, and
ingrowth equations are NOT compiled into the Fortran engine. This confirms the candid note in the
component assessment: the engine is calibrated through multipliers and the SDIMAX keyword, not by
the fitted equations themselves.

**2. The R equation projector (`fvs_stress/conus_eq_proj/conus_eq_projector_v2.R`).** This is what
is actually running right now (jobs 11897527 conus_eq_array and 11897528 conus_eq_gompit_array, 19
variants by 2 modes plus a gompit mortality arm). It is a pure-R 100-year projector (20 cycles of
5 years) that applies the fitted fvs-conus equations directly to FIA stands seeded identically to
the engine arms. It is the validation harness, not FVS. It implements:

| Component | Form wired into the R projector |
|---|---|
| Diameter growth | `eta_dg_b2` (species-dependent, Kuehne v8) or `eta_dg_b1` (species-free, traits W*gamma); lognormal bias correction, capped at 2.0 in per cycle |
| Height | Wykoff lognormal ht-dbh, anchored to measured HT by a per-tree ratio |
| Crown / HCB | CR recession (`cr_update`): HCB1 = (1-CR)*HT, HCB2 = HCB1 + r*(HT2-HCB1), CR2 recovered |
| Mortality | logit (`eta_mort`, default) or Greg gompit (Greg coefficients + ORGANON CCH port) |
| Competition | dynamic per-cycle BAL, BAL_SW/HW, SDI, relative density RD = SDI/SDImax_brms |
| FIX 1 | identical-stand seeding from standinit + treeinit, covariates joined by nearest pairs plot |
| FIX 2 ingrowth | `add_recruits` adds a per-variant constant empirical rate (ingrowth_lookup.rds), all recruits set to the stand dominant species at a fixed DBH |
| FIX 3 self-thinning | ad hoc multiplier `st_mult = min(1 + max(RD-0.55,0)/0.45 * 2, 8)`, ramping mortality up as RD exceeds 0.55 |

So "currently running" is the R projector exercising the fitted equations across all variants in
both species-dependent and species-free modes. The DG species-free fit itself (`dg_sf_v8`) and the
three ingrowth fits launched today are also running. 36 of the projector's metrics files are
already written.

## Diagnostic on the running projector (run today)

A one-way stand-level diagnostic on the completed projector metrics, testing whether the realized
density trajectory follows Reineke self-thinning (expected size-density slope d ln(N) / d ln(QMD)
near -1.605):

| variant | mode | n stands | % self-thinning | median Reineke slope | median peak SDI |
|---|---|---:|---:|---:|---:|
| NE | b1 free | 90,937 | 69 | -0.54 | 1894 |
| NE | b2 dep | 90,937 | 69 | -0.60 | 1669 |
| PN | b1 | 5,705 | 73 | -0.68 | 1725 |
| PN | b2 | 5,705 | 72 | -0.85 | 1577 |
| CR | b1 | 51,256 | 78 | -0.82 | 618 |
| CR | b2 | 51,256 | 78 | -0.86 | 595 |
| LS | b1 | 138,147 | 50 | -0.51 | 1699 |
| LS | b2 | 138,147 | 51 | -0.57 | 1507 |
| AK | b1 | 97 | 98 | -0.86 | 2262 |
| AK | b2 | 97 | 99 | -1.10 | 1742 |

The realized self-thinning slope is -0.5 to -0.9 across variants, materially shallower than the
Reineke -1.605, worst in the dense Eastern variants (NE, LS at about -0.5). The projector is
under-thinning: stems are not removed fast enough as mean size grows. (Caveat: the slope is taken
over the whole trajectory including the pre-peak building phase, so it is a conservative,
shallow-biased estimate; the direction is clear, the magnitude is approximate.) This is direct
evidence that the ad hoc FIX 3 ramp does not reproduce self-thinning, and it is exactly what the
fitted density curve fixes.

## Specific refinement recommendations

Prioritized, grounded in the code above and the diagnostic.

1. **Replace FIX 3 with the fitted stand-level self-thinning (high priority, evidence above).**
   Swap the hand-tuned `st_mult = min(1 + max(RD-0.55,0)/0.45 * 2, 8)` for the fitted García curve
   from today's production fit: per-cycle self-thinning survival = exp(-0.4525 * RD^2.73 * CYCLEN),
   RD = SDI / SDImax_brms. This recovers the correct acceleration onto the Reineke line by
   construction (1.7% per year at RD 0.3, 45% per year at RD 1.0) and ties the projector's density
   limit to the same SDImax surface the engine uses. It should steepen the realized slope toward
   -1.605 and lower the implausible peak SDI tail.

2. **Wire the fitted ingrowth into FIX 2 (after the running fits land).** Today FIX 2 is a constant
   per-variant empirical rate with all recruits assigned the dominant species at a fixed DBH.
   Replace with the negative binomial count model (recruitment responding to BA, RD, HT40, CSPI,
   EPA region) for how many, and the trait-driven composition model (`compos_v2_prod`, running) for
   which species. Then net density becomes fitted ingrowth minus fitted self-thinning, internally
   consistent rather than two unrelated constants.

3. **Add the relative-size senescence term to mortality.** `eta_mort` uses DBH, DBH^2, BAL/BA, CR,
   sqrt(BA*RD), and site, but no relative-size (DBH / Dq or DBH / DBHmax) senescence term. This is
   one of the three validated tree-level fixes and is not in the projector. Add it so large-tree
   senescence is represented by the fitted term rather than absorbed into the ad hoc density ramp.

4. **Verify path invariance in the projector.** Growth is applied as dg per cycle and survival as
   (1-p)^CYCLEN, mixing per-cycle and annual logic. Confirm 10 one-year steps equal one ten-year
   step (the same test the stand-level layer passed) so the 5-year projector and any annual call
   agree.

5. **Treat the R projector as the executable specification for the Fortran injection.** The
   projector already implements the full fitted equation set and is validated stand-by-stand
   against the engine arms. The make-or-break step 5 (inject the species-free equations into FVS)
   should port these exact kernels (eta_dg_b1/b2, eta_mort with the senescence term, cr_update, the
   fitted self-thinning) into the Fortran engine, not design anew. This de-risks the injection by
   giving it a reference implementation and a per-stand check.

6. **Cache the assembled stan_data for the ingrowth runs.** The hurdle smoke timed out in data prep
   (16M GRM rows plus a 448M pairs load) before sampling. Persist the prepared stan_data once so
   the hurdle, negbinom, and composition runs skip the rebuild.

## What was addressed now

- Ran the self-thinning diagnostic above on the completed projector output (real result, no
  disturbance to the running jobs). Script committed as `R/selfthin_diagnostic.R`.
- Did not edit the live `conus_eq_projector_v2.R`: 38 array tasks are running, and refinements 2
  and 3 depend on the ingrowth and senescence fits that are still running. Refinement 1 is the
  drop-in change to stage next; the exact replacement is specified above.

## Run footer

```
[DATA_STATE]: projector output scanned; self-thinning slope -0.5 to -0.9 vs Reineke -1.605
[OUTCOME_VERIFICATION]: confirmed FVS Fortran wiring = SDIMAX keyword + multipliers only; species-free equations live only in the R projector, which is what is running
[IMPACT_UTILITY]: refinement 1 (fitted self-thinning into FIX 3) is the next staged change; refinements 2,3 queued behind the running ingrowth and senescence fits; refinement 5 reframes the Fortran injection as a port of the R kernels
[NEXT_AUTONOMOUS_STEP]: on array completion, stage conus_eq_projector_v3 with the fitted self-thinning replacing FIX 3, rerun NE and LS, recheck the slope
```
