# Ingrowth species composition fit: results and a fixed summary

**Date:** 2026-06-22
**Fit:** compos_v2_prod (trait-driven multinomial, ingrowth_species_composition_v2.stan), 20,000
plots, 42 species (top 40 + OTHER + DF/LP variety splits), 4 chains x 1000 iter.

## Convergence
Converged: max Rhat 1.009, min ESS_bulk about 1100 across alpha_0, b, gamma_int, gamma_cov,
sigma_alpha. This finalizes the ingrowth composition production fit (previously only smoke-validated).

## Gap fixed: the saved summary was missing gamma_cov
The production summary CSV held only alpha_0 (42), b (4), gamma_int (9), sigma_alpha (1) = 56 rows.
It omitted gamma_cov, the trait-by-covariate matrix (P_trait 9 x P_cov 4) that is the entire
composition-gradient mechanism: in the model, covariates shift species shares only through species
traits (eta[s] = alpha_0[s] + (X . gamma_cov') . W_sp[s]; the species-independent X.b term cancels
in the softmax). Without gamma_cov the summary predicts constant shares. I extracted the full
coefficient set from the fit object and saved `compos_v2_prod_gamma_cov_summary.csv` (here in
results/ and on Cardinal alongside the fit). This is needed for both the manuscript and the FIX2
projector swap.

## Composition gradient (strongest trait x covariate interactions, |z| > 5)
Covariates: ln_ba, ln_bal, RD, ln_csi (ht40 and clim_pca1 were dropped as zero-variance after
imputation). Signs are on the multinomial linear predictor (relative, via the softmax), so read
them as "which traits are favored as this covariate rises."

| trait | covariate | mean | z |
|---|---|---:|---:|
| max_dbh_cm | ln_ba | -0.46 | -40 |
| softwood | ln_csi | +0.20 | +38 |
| climate_exposure | ln_csi | +0.19 | +37 |
| wood_specific_gravity | ln_bal | -0.39 | -36 |
| wood_specific_gravity | ln_csi | +0.17 | +34 |
| sensitivity | ln_ba | -0.37 | -32 |
| max_ht_m | ln_bal | +0.50 | +31 |
| low_adaptive_cap | ln_bal | -0.31 | -30 |
| shade_tolerance_num | ln_ba | -0.37 | -28 |
| wood_specific_gravity | RD | +0.15 | +23 |
| max_ht_m | RD | -0.23 | -22 |

The gradient is strong and well-identified, confirming recruitment composition responds to stand
density (BA, BAL, RD) and site (CSPI) through functional traits, the trait-driven story the
manuscript needs. The full 9x4 matrix is in the CSV.

## Next
This is the composition half of the projector FIX 2 swap. To predict recruits-by-species for a
stand: standardize its (ln_ba, ln_bal, RD, ln_csi) with the training means/sds, compute
eta[s] = alpha_0[s] + (X . gamma_cov') . W_sp[s], softmax to shares, multiply by the fitted negbinom
recruit count (the negbinom_elpd job, in progress). Reproduce the training standardization by
replaying 36's seed-42 subsample, or save scale_mean/scale_sd alongside the next fit to avoid it.
A held-out predictive calibration of the composition fit is still open (the production fit used all
20k plots with no test split).
