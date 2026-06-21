# Ingrowth, species composition, and a stand level constraint layer: suggestions

**Date:** 2026-06-11
**Prompted by Aaron:** v8 status, the ingrowth and species composition work, and whether to
build simple age independent yet annualized stand level equations (Garcia tradition) for
basal area, stem density, and top height to constrain the tree level growth and mortality.

## 1. CSPI v8: yes it exists, and v7 should still win

v8 is built (v7 stack plus five Sentinel 2 bands plus four MOD17 GPP/NPP layers). It buys
almost nothing over v7: OOB R2 0.702 vs 0.700, plot blocked CV 0.688 vs 0.686, and v8 is
still carried by v6_distill, elevation, and soil while the spectral terms sit low in
importance. The v7 distillation screen (job 11505475) then showed the v7 surface already
explains more component residual variance than observed site index. Recommendation stands:
lock v7 as the deployable 30 m production surface, keep v6 (1 km) as the accuracy reference,
and retire the v8 remote sensing branch unless a specific application needs sub stand
spectral detail. The cost of the v8 data pipeline is not justified by 0.001 R2.

## 2. Ingrowth and species composition

What exists: a plot level negative binomial recruitment count model (`35_fit_ingrowth_negbinom`
through v4) with EPA L1 to L3 hierarchical random effects, where v4 added top height (HT40)
and rd_sdimax and found top height far more predictive than stand age; a hurdle variant
(`35b`); and a first species composition model (`36_fit_ingrowth_species_composition`). The
manuscript treats ingrowth as the stand level seventh component and the modifier table keeps
it on the common (not trait mediated) form.

Refinements worth making:

- **Make composition a compositional model, trait driven.** The count needs no traits, but
  *which* species recruit is silvically driven, so this is where the trait block earns its
  place for ingrowth. Predict species or group shares with a hierarchical multinomial logit
  or Dirichlet multinomial conditioned on the standing overstory composition (the seed
  source), site and climate (BGI or CSPI), disturbance state, and shade tolerance and seed
  dispersal traits. The count model says how many; the composition model says who; their
  product gives recruits by species.
- **Keep the hurdle / zero handling.** Many FIA plots have zero recruits over a short
  interval. The plain negbinom can under handle excess zeros at annual resolution; the
  hurdle (35b) or a zero inflated negbinom is the safer base. Compare by held out ELPD.
- **Top height as the recruitment clock is correct and points straight at section 3.**
  Recruitment falling as the stand grows in height and closes is exactly the age independent
  behavior Garcia models capture, so the ingrowth driver and the stand level density
  equation below should share the same top height and self thinning logic rather than be
  fit in isolation.

## 3. A stand level constraint layer, Garcia tradition (the main suggestion)

**Worth doing. It is a real gap and a high value one.** The system today is six individual
tree components plus a plot level ingrowth count. Summed over a long projection, small
biases in DG, HG, mortality, and ingrowth compound, and the aggregate stand trajectory
(total basal area, density, top height) can drift away from what stands actually do. A small
stand level model gives an independent, robust prediction of that aggregate trajectory that
you can use to discipline the tree level engine. This matters most for the carbon and yield
applications (PERSEUS, the CBM intercomparisons) where the stand aggregate, not the
individual tree, is the quantity of interest.

### 3.1 A minimal state vector and three transition functions

Follow Garcia's state space view: describe the stand by a small state vector and evolve each
element with an autonomous transition function `y2 = G(y1, t2 - t1, site)` that is age
independent and, because it is a transition on the interval, annualized and path invariant by
construction. Three states:

- **Top height H** (use the HT40 you already compute). A Chapman Richards GADA in algebraic
  difference form, `H2 = f(H1, t2 - t1)`, which removes age by letting H reference itself
  (Garcia 1983 for the stochastic height SDE, the GADA for the difference form). This is also
  the canonical site reading and ties directly to the CSPI and HG work: top height growth is
  the height based site signal, so H and the site surface should be mutually consistent.
- **Density N** (stems per ha above the merch threshold). A mortality and self thinning
  transition driven by H increment rather than age, bounded by the maximum size density line
  you already estimate (SDImax_brms, Reineke). N is the net of two processes the tree model
  handles separately: ingrowth adds from below, self thinning removes near the boundary, so
  the stand level N equation is the natural place to reconcile the negbinom recruitment with
  the tree level mortality.
- **Basal area G**. A growth transition driven by H (the clock), N, and the productivity
  index (BGI or CSPI), age independent, `G2 = f(G1, H, N, t2 - t1, site)`.

Fit all three to the same FIA remeasurement pairs aggregated to the plot, with the same
ecoregion and forest type random effects and the same productivity driver as the tree level
system, so the two levels are consistent rather than two separate stories.

### 3.2 How it constrains the tree level model

Start one way, move to two way once validated:

1. **Diagnostic (one way, low risk, do first).** Run the stand level equations alongside the
   tree level projection and flag where the summed tree predictions diverge from the stand
   trajectory. You already have `36_conus_benchmark.R` as a stand level FIA benchmark engine,
   so this is mostly wiring, and it immediately tells you where the individual tree model
   drifts.
2. **Constrained disaggregation (two way, higher value).** Use the stand level BA growth and
   density trajectory as the envelope, then disaggregate to trees with a proportional
   allocation that preserves the tree level distribution shape while scaling the sum to the
   stand total (Ritchie and Hann style disaggregation). The individual tree competition
   dynamics still set who grows and who dies; the stand equation sets the total. This is the
   classic way whole stand and individual tree models are reconciled and it stabilizes long
   horizon behavior without discarding tree level detail.

### 3.3 Refinements and cautions to build in from the start

- **Path invariance is the annualization guarantee. Test it explicitly:** ten one year steps
  must equal one ten year step. Garcia transition functions satisfy this by design; verify it
  numerically as a unit test so the annual engine and any multi year call agree.
- **Compatibility (Clutter 1963).** If you fit both a BA growth and a BA yield surface, make
  the growth equation the derivative of the yield equation so the two are mathematically
  consistent. The state space form gives this for free because it is one dynamical system;
  keep it that way rather than fitting growth and yield independently.
- **Self thinning consistency.** The stand level N trajectory must not cross the SDImax
  boundary, and the tree level mortality should agree with the stand level self thinning at
  that boundary. Tie the density transition to the existing SDImax_brms surface so both
  levels share one carrying capacity.
- **Reconcile ingrowth at the stand level.** The recruitment term in dN/dt is exactly the
  negbinom count, and the species composition model allocates it. Fit them to be consistent
  rather than letting plot level ingrowth and stand level density imply different recruitment.
- **Keep it small.** Three states, a handful of parameters each, nonlinear forms that
  extrapolate sensibly. Resist adding covariates the tree level model already carries; the
  stand layer earns its keep by being simple, robust, and hard to break, not by matching the
  tree model's resolution.

### 3.4 Is it worth it

Yes. The data, the productivity driver, the SDImax surface, the stand benchmark engine, and
the Bakuzis stand level uncertainty harness already exist, so the marginal cost is three
compatible equations fit to data in hand. The payoff is disciplined long horizon projection,
a principled home for self thinning and site limits, a natural reconciliation point for
ingrowth and mortality, and exactly the aggregate quantities the carbon and yield
applications consume. It also strengthens the manuscript narrative: a unified tree level
calibration constrained by a compact, age independent, annualized stand level model is a
cleaner and more defensible system than tree equations alone.

## 3.5 Top height GADA prototype result (job 11511695, 2026-06-11)

Ran the first stand state on 101,599 plot level top height pairs (top height as the mean
height of the top DBH quintile per plot, mean 19.9 m, max 84.6 m, mean increment 0.187 m/yr).
The Chapman Richards GADA difference form fit cleanly with a bounded optimizer.

- **Path invariance is exact.** Ten one year steps equal one ten year step to machine
  precision (|diff| ~1e-14). The annualization property the whole approach depends on holds
  by construction. This is the key proof of concept.
- **Fit:** RMSE 1.41 m, bias -0.05 m. The level R2 of 0.974 is inflated and should not be
  quoted as skill: top height changes slowly, so predicting H2 from H1 is largely
  autocorrelation. The honest metric is increment skill, and an RMSE of 1.41 m against a mean
  periodic increment near 1.3 m says the global prototype predicts the increment only
  modestly. Expected for a single global form; the refinements below are what earn real skill.

Two findings that should shape the production version:

1. **Drive the asymptote with a height site index, not BGI.** The BGI term on the asymptote
   came out the wrong sign (a1 = -2.3; higher productivity should raise asymptotic height).
   This echoes the CSPI screens: BGI is a biomass and asymptote signal, not a height site
   signal. For top height the asymptote should be driven by CSPI (the height based surface),
   which also ties the stand layer to the site work cleanly.
2. **The asymptote needs structure.** Top height asymptote ranges from roughly 15 m to 85 m
   across CONUS, so a single global A is too crude (b2 also pinned at its bound, a sign of
   misspecification). Add ecoregion or forest type random effects on the asymptote, fit
   Bayesian alongside the other components so it carries posterior draws.

Net: the form and the annualization work; the next pass swaps BGI for CSPI on the asymptote
and adds ecoregion structure, then density (tied to SDImax) and basal area follow the same
pattern.

## 3.6 Refined top height (v2): sign fixed, but increment skill is the real challenge (job 11511803)

Reran with the asymptote driven by CSPI (the height site index) plus L1 ecoregion offsets, on
102,505 plot pairs across 11 ecoregions.

- **The sign is fixed.** a1 on CSPI is +0.86 (positive, as it must be), and b2 = 3.36 is now
  well identified rather than pinned at a bound. Per-L1 asymptote offsets span roughly -17 to
  +18 m, the expected large regional spread in attainable top height. Path invariance is again
  exact. So CSPI is the right asymptote driver, confirming the BGI sign problem was real.
- **But the honest metric says the global form does not predict top height growth.** R2 on the
  level is 0.971 and meaningless (top height barely moves year to year), while R2 on the
  increment is -0.11, worse than predicting the mean increment. Two causes: the plot level top
  height computed from the top DBH quintile is a noisy estimator over a 7 year interval, and a
  pure height only transition lacks the drivers of increment.

Refinement path before this can constrain HG: (1) a cleaner top height definition (consistent
dominant cohort or HT40 via expansion factors, restricted to plots with a stable top cohort),
(2) a random rate effect (b1) by ecoregion or species group, fit Bayesian so it carries
posterior draws, and (3) test density dependence in the rate. The level fit and path
invariance are sound; the increment is where the work is. This is itself a useful finding: a
naive whole stand top height GADA is not enough, the rate needs structure.

## 3.7 Additional stand-level models: density and basal area (job 11553453)

Prototyped the other two states on 107,450 plot pairs across 11 ecoregions, plus a
top-height v3 with ecoregion rate structure. The three differentiate sharply, which is itself
the useful result: the stand layer is not uniformly easy, and the order of difficulty points
straight at how to build it.

- **Density self-thinning works well, and is the strongest stand-level result so far.** Model
  N2 = N1 * exp((a0 + a1*RD)*dt) with relative density RD = SDI/SDImax. Fitted rate
  r = 0.107 - 0.437*RD per year (a1 negative, self-thinning as expected), RMSE on ln(N) 0.63,
  R2 0.60. The crossover is at RD about 0.245: below it the stand gains stems (ingrowth wins),
  above it the stand loses them, reaching roughly -33%/yr near the size-density boundary
  (RD = 1). That is textbook self-thinning, recovered age-independent and annualized from FIA
  pairs. This is a usable density constraint and the natural reconciliation point for the
  ingrowth count and tree-level mortality.
- **Basal area: the form is sound but the driver is wrong.** The monomolecular approach
  BA2 = BA1 + (Gmax - BA1)*(1 - exp(-k*dt)) is path-invariant to machine precision, but
  driving Gmax with CSPI gave the wrong sign and pinned at its bound (Gmax fell with site,
  which is backwards), and increment R2 was only 0.09. The lesson mirrors the height result in
  reverse: top height is driven by site index, but stand carrying capacity (max basal area,
  max density) is driven by SDImax, not by a height site index. Refit Gmax as a function of
  SDImax and add N and H as drivers of the rate.
- **Top-height v3 (ecoregion rate) needs a numerical guard.** The asymptote-plus-rate-by-L1
  version returned NaN on the final evaluation (an unguarded prediction outside the optimizer
  bound check). A minor fix, but the increment-skill problem from v2 is the real issue and is
  not solved by ecoregion rate structure alone.

Net read for the stand layer: lead with the density self-thinning constraint, which works and
is well understood; build basal area next with SDImax as the carrying-capacity driver and N
and H in the rate; and treat top-height growth as the hard case that needs a cleaner top
height definition and likely a Bayesian random-rate fit. The annualization and path-invariance
hold throughout, so the dynamical-system foundation is sound; the work is in the right drivers.

## 3.8 Garcia-grounded refits (job 11553467): basal area and density fixed

Applied two of García's principles (see the separate Garcia review memo). Both improved:

- **Basal area driver fixed.** Driving the carrying capacity by SDImax instead of CSPI gave
  Gmax = 0.036 * SDImax (g1 positive, the wrong-sign/pinned problem resolved), k = 0.053/yr,
  increment R2 up to 0.13. Stand size dynamics are governed by the stand's own carrying
  capacity, exactly García's coupling, not by a height site index.
- **Density self-thinning sharpened.** A power form on relative density,
  rate = 0.45 * RD^2.73 per year, R2 on ln(N) 0.60, gives gentle loss below the boundary
  (1.7%/yr at RD 0.3) accelerating onto the Reineke line (45%/yr at RD 1). This is the
  self-thinning limb; net density is the negbinom ingrowth minus this term.

The remaining hard case, top-height increment skill, is now understood as a measurement-error
problem and the fix is García's reducible-SDE estimator (`resde`, now installed): refit top
height with observation error and a local site parameter rather than least squares on noisy
top height. See `20260611_garcia_statespace_review_and_refinements.md`.

## 3.9 The top-height puzzle is solved: it was measurement noise (jobs 11553482, 11553497)

Two results close this out. First, García's own reducible-SDE estimator (`resde`) does not transfer
directly: it anchors the SDE at a known age origin (height zero at age zero), but our top height is
deliberately age free, so the default initial condition is wrong and the fit returns NaN. Age-free
data needs an errors-in-variables form of the GADA difference equation, not the age-anchored SDE.

Second, and decisively, I quantified the noise. The plot-level top-height estimator (mean height of
the top DBH quintile) has a standard error of about 0.89 m on a single occasion. Differenced across
two occasions that is about 1.26 m of noise on the increment, while the mean periodic increment is
only 1.18 m. The measurement variance on the difference (2.64) actually exceeds the total observed
increment variance (2.16), so the reliability of the observed increment is near zero (about -0.22).

That fully explains the negative increment R2 of the earlier GADA fits. It was never model failure;
the top-height increment signal is simply buried under estimator noise. This is exactly García's
measurement-error point, demonstrated for our data. The fix is twofold and clear:

1. **Reduce the estimator noise.** The SE scales as sd over sqrt(k); use a more stable top-height
   definition (HT40 via expansion factors, or restrict to plots with more top trees, or track a
   consistent dominant cohort) so a single occasion is less noisy.
2. **Fit with an explicit measurement-error term** (sigma_meas about 0.9 m) in an errors-in-variables
   GADA, so the deterministic trajectory is recovered despite the noise.

The same caution applies at the tree level: HG sits on individual tree height, which is also measured
or imputed with error, so the reliability problem likely affects it too, reinforcing the case for the
measurement-error refit of the height components.

## 3.10 Top height cannot be fit as a growth equation from FIA pairs (job 11553502)

Tested the standard dominant height (HT40, expansion-weighted largest 100 trees/ha) as the
lower-noise definition. It was worse, not better. On a small FIA plot the HT40 is defined by
about 7 trees, so its estimator SE rose to 1.12 m (the top-quintile mean used more trees and
had SE 0.89 m), the measurement variance on the difference climbed to 4.50, and reliability
fell to -0.99. The GADA increment R2 stayed at zero and the CSPI asymptote sign flipped again
under the noise.

Two definitions now agree: **the stand-level top-height growth increment cannot be reliably
estimated from FIA remeasurement pairs**, because the plot is too small to pin top height to
better than about 1 m while the periodic increment is only about 1.2 m. This is a property of
the data, not of the model form, and no definition or optimizer fixes it.

The consequence is a clean design decision, not a dead end:

- **Density and basal area are the FIA-fittable stand states.** Stem counts and basal-area
  sums are estimated precisely on FIA plots, which is why density self-thinning (R2 0.60) and
  the SDImax-driven basal area both worked. These two carry the stand-level constraint.
- **Top height should not be fit as a separate stand equation from FIA pairs.** Derive the
  top-height trajectory instead by applying the tree-level height-growth model to the dominant
  cohort and aggregating, since the tree-level HG model has the data volume, is annualized, and
  (with the measurement-error refit) is the better-identified path. Alternatively anchor top
  height with external site-index curves fit to precise dominant-height data (stem analysis or
  research plots), not FIA remeasurement.

So the stand layer settles as: density and basal area fit directly from FIA and provide the
constraint; top height is carried from the tree-level HG model rather than fit separately.

## 4. Suggested sequencing

1. Finish what is running (the two ΔLOO jobs, the v7 QRF merge) and lock v7. No new launches
   until those land.
2. Ingrowth: switch composition to the trait driven compositional model and settle the
   hurdle vs negbinom base by held out ELPD. Small, self contained.
3. Stand level: fit top height (GADA difference form) first, since it is the cleanest and
   anchors the other two and the site work. Then density (tied to SDImax) and basal area.
   Wire as a one way diagnostic against `36_conus_benchmark.R` before any constrained
   disaggregation.
4. Carry all three stand states through the same posterior draw uncertainty path as the tree
   components so the aggregate trajectory has credible bands.

## Key references

Garcia 1983 (stochastic differential equation height growth), Garcia 1994 and the GADA
(age independent, self referencing site equations), Clutter 1963 (growth yield
compatibility), Reineke 1933 and the size density boundary, Ritchie and Hann (disaggregation
of stand to tree).
