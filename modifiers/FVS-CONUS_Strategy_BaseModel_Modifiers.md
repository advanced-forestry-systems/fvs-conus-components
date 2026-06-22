# FVS-CONUS: Strategy for Site Productivity, Base Models, and Condition Modifiers

**Date:** April 20, 2026 (revised)
**Author:** A. Weiskittel

## 1. Site Productivity: CSPI as the Primary Variable

### 1.1 Available Measures

The remeasurement dataset (8.2M rows) includes five site productivity measures:

| Measure | Description | Missing (%) | Notes |
|---------|-------------|-------------|-------|
| **CSPI** | Composite z-score (BGI 0.40, Asym 0.35, ClimateSI 0.25) | ~0% | Species-agnostic, complete coverage |
| **climate_si** | Climate-based site index | 0% | Climate envelope only |
| **bgi** | Biomass Growth Index | 7.1% | Remote sensing derived |
| **SICOND** | FIA field site index (feet, base age varies by species) | 18.7% | Species-specific, inconsistent base ages |
| **SICOND_FVS** | FVS-computed site index | 30.8% | Legacy FVS variant dependent |

### 1.2 Empirical Comparison

We compared all three candidate variables (CSPI, BGI, climate_si) as covariates in simple linear models of DG and HG using a 100K-row subsample. Results:

**Height Growth (log scale):**

| Covariate | delta R-squared | Coefficient sign |
|-----------|----------------|-----------------|
| CSPI | +0.037 | Positive (correct) |
| BGI | +0.024 | Positive |
| climate_si | +0.019 | Positive |
| All three | +0.046 | All positive |

**Diameter Growth (log scale):**

| Covariate | delta R-squared | Coefficient sign |
|-----------|----------------|-----------------|
| BGI | +0.020 | Positive (correct) |
| CSPI | +0.014 | Positive |
| climate_si | +0.009 | Positive |
| All three | +0.027 | All positive |

CSPI is the strongest single predictor for HG and second strongest for DG. BGI adds the most for DG but has 7.1% missingness, making it impractical as a standalone variable. CSPI has near-zero missingness and captures a balanced signal across multiple productivity dimensions.

### 1.3 Decision: Retain CSPI

**CSPI will remain the primary site productivity variable for all FVS-CONUS base models.** The rationale:

1. Near-complete coverage (~0% missing), critical for a CONUS-wide model with 8.2M observations.
2. Strongest single predictor for HG, competitive for DG.
3. Species-agnostic design avoids the base-age and species-group inconsistencies inherent in SICOND.
4. SICOND has 18.7% missingness, requires species-specific base ages, and its FIA measurement protocols vary across inventory cycles and regions. Imputation would introduce additional model uncertainty without clear benefit.
5. The composite z-score construction (BGI, asymptotic height, climate SI) captures complementary signals from remote sensing, stand structure, and climate.

CSPI enters the Stan models as `ln_cspi_shift = log(cspi - min(cspi) + 1)`, which provides a log-transformed, strictly positive covariate.

### 1.4 Future Refinement

After base models converge, we may consider adding BGI as a secondary covariate in the DG model specifically, since it was the strongest DG predictor (+0.020 R-squared). This would require handling the 7.1% missingness, likely by imputing from CSPI and ecoregion. This is a post-production enhancement, not a blocking issue.


## 2. Base Model Architecture

### 2.1 Philosophy

The core idea: **fit the base model using all available data under "average" conditions, then develop condition-specific modifiers as post-hoc adjustments.** This follows the classic ORGANON/FVS design pattern (Hann 2011; Weiskittel et al. 2011, Ch. 6).

On the response scale, the modifier is multiplicative:

```
Growth = f(size, competition, site, crown) × M_origin × M_disturbance × M_management
```

On the log or logit linear predictor scale (where all our Bayesian models operate), modifiers are additive:

```
eta_modified = eta_base + delta_origin + delta_disturbance(t) + delta_management(t)
```

The correspondence is `M = exp(delta)` on the log scale and `M = invlogit(delta) / invlogit(0)` on the logit scale. For small delta, `exp(delta) ≈ 1 + delta`, so additive adjustments on the linear predictor are approximately multiplicative on the response scale.

### 2.2 Why Fit the Base Model on All Data

1. **Sample size preservation.** Filtering to undisturbed natural stands would discard a substantial fraction of FIA plots, particularly in the Southeast (plantations) and West (fire disturbance), reducing statistical power for species and ecoregion random effects.

2. **Representative average.** The "average" FIA plot reflects the actual forest landscape. Base model predictions represent expected growth for a randomly selected plot, the appropriate reference for forest inventory updates.

3. **Modifier interpretation.** Modifiers quantify the departure from average conditions. If the base model were fit only to undisturbed stands, modifiers would need to account for the difference between average and undisturbed conditions, complicating interpretation.

4. **Bayesian posterior stability.** More data yields better-estimated random effects. The species and ecoregion random effects absorb some condition-related variation, but this is acceptable because it provides a robust prediction surface.

### 2.3 Base Model Production Status (April 20, 2026)

| Component | Base Model Form | Likelihood | Production Status |
|-----------|----------------|------------|-------------------|
| Diameter Growth (DG) | ORGANON / Kuehne 2022 | Log-normal | Running (2 chains each, ~38h in) |
| Height Growth (HG) | ORGANON fixedK | Log-normal | Running (4 chains, 38h in, slow) |
| HT-DBH | Wykoff (1986) | Log-normal | Preflight submitted (job 8645430) |
| HCB | ORGANON | Beta | Running (2 chains, 22h in) |
| Crown Recession | Hasenauer-Hradetzky | Beta | Running (2 chains, 22h in) |
| Mortality | Logit link, L1+sp | Bernoulli-logit | Running (2 chains, 11h in) |
| Site Productivity | CSPI composite | N/A | Complete |


## 3. Condition Modifier Strategy

### 3.1 FIA Condition-Level Variables

The current remeasurement pairs dataset includes **AGENTCD** (cause of death agent codes at the tree level) but does **not** yet include the condition-level variables needed for modifiers. These must be joined from the FIA COND table via PLT_CN + CONDID.

**Required data enrichment:**

| FIA Variable | Description | Key for |
|-------------|-------------|---------|
| STDORGCD | Stand origin code | Origin modifier |
| DSTRBCD1/2/3 | Disturbance agent code (up to 3 per condition) | Disturbance modifiers |
| DSTRBYR1/2/3 | Year of disturbance | Time-since-disturbance decay |
| TRTCD1/2/3 | Treatment code (up to 3 per condition) | Management modifiers |
| TRTYR1/2/3 | Year of treatment | Time-since-treatment decay |
| OWNGRPCD | Ownership group | Potential stratification variable |

### 3.2 Specific FIA Code Tables

#### 3.2.1 Stand Origin (STDORGCD)

| Code | Description | Expected Prevalence |
|------|-------------|-------------------|
| 0 | Natural stand | ~75% of FIA conditions nationally |
| 1 | Planted (artificial regeneration) | ~25%, concentrated in SE US (loblolly, slash pine) |

#### 3.2.2 Disturbance Codes (DSTRBCD)

| Code | Description | Aggregation Group |
|------|-------------|-------------------|
| 10 | Insect damage | **Insect** |
| 11 | Insect damage to understory | Insect |
| 12 | Insect damage to overstory | Insect |
| 20 | Disease damage | **Disease** |
| 21 | Disease damage to understory | Disease |
| 22 | Disease damage to overstory | Disease |
| 30 | Fire damage (general) | **Fire** |
| 31 | Ground fire | Fire |
| 32 | Crown fire | Fire |
| 40 | Animal damage | **Animal** |
| 41 | Animal damage to understory | Animal |
| 42 | Animal damage to overstory | Animal |
| 50 | Weather damage (general) | **Weather** |
| 51 | Ice/frost | Weather |
| 52 | Wind/tornado/hurricane | Weather |
| 53 | Flooding | Weather |
| 54 | Drought | Weather |
| 60 | Vegetation/competition | **Vegetation** |
| 70 | Unknown/not specified | Exclude or "other" |
| 80 | Human-caused (non-silvicultural) | **Human** |
| 90 | Geologic (landslide, volcanic) | **Geologic** |

For modifier development, we will aggregate to 5-6 groups: **Insect** (10-12), **Disease** (20-22), **Fire** (30-32), **Weather** (50-54), and **Human/Other** (60, 80, 90). Animal damage (40-42) is typically rare and may be pooled with "Other" unless sample sizes permit separation.

#### 3.2.3 Treatment Codes (TRTCD)

| Code | Description | Aggregation Group |
|------|-------------|-------------------|
| 10 | Cutting (harvest/thinning) | **Cutting** |
| 20 | Site preparation | **Site prep** |
| 30 | Artificial regeneration (planting/seeding) | **Planting** |
| 40 | Natural regeneration enhancement | Regen |
| 50 | Other silvicultural treatment | Other |

The primary management modifier will focus on **TRTCD = 10 (cutting)**, which encompasses both commercial thinning and partial harvest. TRTCD = 20 and 30 are usually associated with regeneration and overlap with STDORGCD = 1 (planted stands), so they are better captured by the origin modifier than a separate treatment modifier.

#### 3.2.4 Cause-of-Death Agent Codes (AGENTCD, tree level)

Already present in the dataset (21.5% non-NA). Can serve as a tree-level proxy for plot-level disturbance:

| Code | Description |
|------|-------------|
| 10 | Insect |
| 20 | Disease |
| 30 | Fire |
| 40 | Animal |
| 50 | Weather/physical |
| 60 | Vegetation/competition/suppression |
| 70 | Unknown/not specified |
| 80 | Human/land clearing |

### 3.3 Modifier Model Forms: Additive vs. Multiplicative

#### 3.3.1 On the Linear Predictor (Additive)

Because all base models operate on a log or logit linear predictor, modifiers enter as additive terms. For a growth model with log-normal likelihood:

```
eta_modified = eta_base + delta_k * I(condition_k)
```

where `I(condition_k)` is an indicator for condition k (e.g., planted, fire-disturbed). On the natural response scale, this translates to a multiplicative modifier:

```
Growth_modified = Growth_base * exp(delta_k)
```

For the mortality model (logit link):

```
logit(p_mort)_modified = logit(p_mort)_base + delta_k
```

which changes the odds ratio by `exp(delta_k)`.

#### 3.3.2 Transient Modifiers with Time-Since Decay

Disturbance and management effects are transient. The standard form includes an exponential decay:

**Additive on the linear predictor:**

```
delta_disturbance(t) = beta_dist * exp(-lambda * t)
```

where `t` = years since disturbance and `lambda` controls the decay rate. The half-life is `ln(2) / lambda`. On the response scale, this becomes:

**Multiplicative on the response:**

```
M_disturbance(t) = exp(beta_dist * exp(-lambda * t))
```

At `t = 0` (year of disturbance), the modifier is `exp(beta_dist)`. As `t -> infinity`, the modifier returns to 1.0 (no effect).

#### 3.3.3 Management Modifier with Intensity

Following the ORGANON pattern (Hann 2011), the thinning modifier includes both intensity and decay:

**Additive:**

```
delta_thin(t) = beta_thin * intensity * exp(-lambda_thin * t)
```

where `intensity = BA_removed / BA_before` (proportion of basal area removed). On the response scale:

**Multiplicative:**

```
M_thin(t) = exp(beta_thin * intensity * exp(-lambda_thin * t))
```

FIA does not directly record thinning intensity, but `intensity` can be approximated from the change in basal area between measurement cycles for plots with TRTCD = 10.

#### 3.3.4 Stand Origin Modifier (Time-Invariant)

The origin modifier is a simple shift with no decay (the distinction between natural and planted does not diminish over time):

**Additive:**

```
delta_planted = beta_planted * I(STDORGCD == 1)
```

**Multiplicative:**

```
M_planted = exp(beta_planted) when planted, 1.0 when natural
```

#### 3.3.5 Expected Modifier Signs

| Component | Planted (beta_planted) | Fire (beta_fire) | Insect (beta_insect) | Thinning (beta_thin) |
|-----------|----------------------|-------------------|---------------------|---------------------|
| DG | + (faster diameter growth) | - short-term, + long-term (release) | - (defoliation, girdling) | + (competition release) |
| HG | + (faster height growth) | - short-term | - | +/0 (small for dominants) |
| HT-DBH | - (stockier form, wider spacing) | 0/+ | 0 | - (stockier after release) |
| HCB | 0/- (lower crown base in open) | + (crown scorch raises HCB) | 0 | - (crown expansion lowers HCB) |
| CR | + (fuller crowns, less competition) | - (crown damage) | - (defoliation) | + (crown expansion) |
| Mortality | - (lower, managed spacing) | + short-term (strongly) | + (strongly) | - (reduced competition) |

### 3.4 Bayesian Implementation Options

**Option A: Embedded in the linear predictor (integrated estimation)**

Add modifier terms directly to the Stan model. Provides full uncertainty propagation but requires re-fitting all models:

```stan
// Additional parameters
real beta_planted;
real beta_fire;
real<upper=0> lambda_fire;  // decay rate

// In model block, add to eta:
+ beta_planted * planted_indicator
+ beta_fire * fire_indicator .* exp(-lambda_fire * years_since_fire)
```

**Option B: Two-stage residual modeling (recommended for Phase 2)**

After base model production, extract posterior-mean predictions, compute residuals, and model the residual pattern:

```r
# After base model production:
resid <- observed - predicted_base

# Model residuals as function of conditions
mod <- lmer(resid ~ I(STDORGCD == 1) +
              I(has_fire) * exp_decay(years_since_fire) +
              I(has_insect) * exp_decay(years_since_insect) +
              I(TRTCD == 10) * intensity * exp_decay(years_since_trt) +
              (1 + I(STDORGCD == 1) | species_group),
            data = d_with_cond)
```

This is computationally much simpler, allows rapid iteration, and lets us assess estimability before committing to a full re-fit. The trade-off is that uncertainty in the base model is not propagated through the modifiers.

**Option C: Hybrid (pragmatic)**

Use two-stage (Option B) for initial development and validation, then embed the most important modifiers (planted, fire, thinning) into the Stan models for a final production re-fit. This gives the best of both worlds: fast development with eventual full uncertainty propagation.

### 3.5 Implementation Roadmap

**Phase 1: Data enrichment (prerequisite for all modifier work)**

1. Join COND-level variables (STDORGCD, DSTRBCD1/2/3, DSTRBYR1/2/3, TRTCD1/2/3, TRTYR1/2/3) to the remeasurement pairs dataset via PLT_CN + CONDID from the FIA COND table.
2. Compute `years_since_disturbance = MEASYEAR - DSTRBYR` and `years_since_treatment = MEASYEAR - TRTYR` for each observation.
3. Create binary indicators: `has_fire = (DSTRBCD %in% 30:32)`, `has_insect = (DSTRBCD %in% 10:12)`, `planted = (STDORGCD == 1)`, `has_cutting = (TRTCD == 10)`.
4. Tabulate sample sizes per disturbance type and ecoregion to assess estimability. Aggregation decisions depend on these counts.

**Phase 2: Base model production (current work, April 2026)**

Complete production fits of all 7 base model components using the full dataset. These base models are the foundation on which modifiers are built.

**Phase 3: Two-stage modifier development**

1. Extract posterior-mean predictions from each converged base model.
2. Compute residuals: `observed - predicted_base`.
3. Fit mixed-effects modifier models on residuals, starting with stand origin (simplest, time-invariant) and working toward disturbance and management (time-varying).
4. Validate modifiers using cross-validation or held-out FIA cycles.
5. Assess whether modifiers improve prediction on independent data.

**Phase 4: Integrated re-fit (optional, longer-term)**

Embed validated modifiers into the Stan linear predictors and re-fit. This is worthwhile only for modifiers with large, well-estimated effects (likely planted and fire).

### 3.6 Practical Considerations

**Sample sizes.** Some disturbance types may have too few observations for reliable estimation. The aggregation scheme in Section 3.2.2 pools codes into 5-6 groups. If any group has fewer than ~5,000 observations nationally, consider pooling further or treating as a single "disturbed" indicator.

**Confounding with geography.** Fire is more common in the West, plantations in the Southeast, insect outbreaks concentrated in specific ecoregions and time periods (e.g., mountain pine beetle in the Northern Rockies, 2000-2015). The EPA L1 random effects in the base model partially control for geographic confounding, but modifiers should still be interpreted cautiously. Including an ecoregion random slope on the modifier coefficient can help.

**Temporal resolution.** FIA remeasurement intervals are typically 5-10 years. Short-duration effects (first 1-2 years post-fire) are poorly captured. The exponential decay model smooths over this gap, but the estimated immediate effect `beta_dist` may be attenuated relative to the true peak effect.

**Thinning intensity.** FIA does not record BA removed directly. For plots with TRTCD = 10, approximate intensity as `(BA_time1 - BA_time2) / BA_time1` where `BA_time1 > BA_time2`. This is noisy because it conflates ingrowth and mortality with harvest removal. Supplement with CFRU and CAFS permanent plot networks where prescriptions are documented.


## 4. HT-DBH Model: Resolution via Log-Normal Likelihood

### 4.1 Problem

The HT-DBH Wykoff simple preflight (job 8640879) completed with zero exceptions (the eta cap eliminated all overflow), but convergence remained poor: rhat ~1.53, ESS ~7 across all parameters. The root cause is the heteroscedastic variance model `sigma_i = s0 * (DBH+1)^s1`, which creates a posterior ridge. The parameter `s0` showed extreme bimodality (median 3.37 vs mean 19,892), meaning the sampler alternated between two modes: one reasonable (s0 ≈ 3) and one degenerate (s0 → infinity with compensating s1), where enormous noise variance flattens the likelihood and allows other parameters to wander.

This is a structural issue with the normal-likelihood formulation, not a hierarchy depth problem. Simplifying from L1/L2/L3 to L1-only did not help.

### 4.2 Solution: Log-Normal Likelihood

The fix mirrors the approach that resolved HG convergence (from rhat=Inf to rhat=1.01). Instead of modeling height on the natural scale with heteroscedastic variance:

```
HT ~ Normal(1.37 + exp(eta), s0 * (DBH+1)^s1)
```

We model log-transformed height-above-breast-height with a single sigma:

```
log(HT - 1.37) ~ Normal(eta, sigma)
```

This eliminates both the `exp(eta)` overflow risk AND the bimodal variance problem, since sigma is a single scalar on the log scale. The Wykoff form becomes linear on the log scale:

```
log(HT - 1.37) = b0 + z_sp + z_L1 + a_bal*BAL + a_ba*sqrt(BA) + a_cspi*ln_cspi_shift
                  + a_bard*BA_x_RD + a_blrd*BAL_x_RD + b1/(DBH + 1) + epsilon
```

Back-transform with log-normal bias correction: `HT_pred = 1.37 + exp(eta + 0.5 * sigma^2)`.

### 4.3 Status

The log-normal Stan model (`ht_dbh_wykoff_simple_lognormal.stan`), R driver (`36d_preflight_htdbh_wykoff_lognormal.R`), and SLURM submit script have been created and submitted as job **8645430** on Cardinal (60K-row preflight, 4 chains, 1000 warmup + 1000 sampling, 12h wall time). Based on the HG precedent, we expect rhat ≈ 1.00-1.02 and ESS > 500.


## 5. Summary of Decisions and Next Steps

1. **Site productivity:** Retain CSPI as the primary site variable. It is the strongest single predictor for HG, competitive for DG, and has near-zero missingness. SICOND is not used due to 18.7% missingness, species-specific base ages, and inconsistent measurement protocols.

2. **Base models:** Continue current production fits using all data with CSPI. Six of seven models are running on Cardinal; the seventh (HT-DBH log-normal) was just submitted.

3. **HT-DBH:** Log-normal preflight (job 8645430) submitted. If convergence is clean, proceed directly to production fit.

4. **Modifiers (Phase 2):** After base models converge, develop condition modifiers using the two-stage residual approach:
   - Stand origin (STDORGCD: 0=natural, 1=planted) as a time-invariant additive shift
   - Disturbance (DSTRBCD aggregated to insect/disease/fire/weather/other) with exponential time-since decay
   - Management (TRTCD=10, cutting) with intensity and decay terms

5. **Data enrichment (prerequisite for Phase 2):** Join STDORGCD, DSTRBCD1-3, DSTRBYR1-3, TRTCD1-3, TRTYR1-3 from the FIA COND table to the remeasurement pairs dataset.

6. **Production wall times:** All production jobs need 4+ day wall times. Current 2-day walls are marginal for the full 3M+ observation dataset.
