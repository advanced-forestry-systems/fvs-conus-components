# Ingrowth count predictor: built, validated, and a model issue found (2026-06-22)

`R/predict_ingrowth.R` implements the FIX 2 recruitment predictor: a self-contained negative-binomial
count predictor (transcribed from ingrowth_negbinom_v2.stan; trait standardization recomputed from
the full species_traits file) and a trait-driven multinomial composition predictor (needs the
scale_mean/scale_sd that the patched 36 saves on its next refit).

## Validation caught a collinearity problem in the count fit
The negbinom count fit (negbinom_elpd, 150k-plot subsample) converged well: all Rhat about 1.00,
ESS in the thousands. But the coefficients are pathological:

| coef | predictor | mean | sd | prior mean |
|---|---|---:|---:|---:|
| b1 | ln(BA+1) | +4.81 | 0.04 | -0.3 |
| b2 | ln(BAL_mean+1) | -4.39 | 0.04 | -0.2 |
| b3 | rd_sdimax | +0.82 | 0.05 | -1.0 |

b1 and b2 are large, tightly estimated, and nearly cancel: ln(BA) and ln(BAL_mean) are strongly
collinear, so the model uses their difference. The net stand-density response (b1+b2+b3 as BA, BAL,
RD rise together) is positive, i.e. denser stands predicted to recruit MORE, which is backwards and
contradicts the model's own priors. A representative NE stand predicts only about 0.2 to 0.34
recruits/yr, rising with RD.

## Conclusion and recommended fix
The predictor code is correct (parses, runs, reads coefs/traits properly), but the count fit must
not be wired into the projector as-is. Refit the count model with the BA/BAL collinearity removed:
drop ln_bal, or replace the (ln_ba, ln_bal) pair with ln_ba plus a BAL/BA ratio, so the density
terms are identifiable and the net response is negative as expected. Quick refit (edit 35_v4
predictors, rerun on the 150k subsample). The composition predictor and the stand-level constraint
are unaffected and ready.
