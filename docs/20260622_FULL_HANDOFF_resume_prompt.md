# Full handoff: CONUS-unified FVS variant program (resume point 2026-06-22)

Copy the prompt in the first section into a new task to resume. Everything below it is the
reference state the prompt relies on.

---

## PASTE THIS PROMPT TO START THE NEW TASK

```
Resume the CONUS-unified FVS variant program on OSC Cardinal. Read the reference state in
~/Documents/Claude/fvs-conus/20260622_FULL_HANDOFF_resume_prompt.md first, then load the
crsf-workspace, hpc-cardinal, and github-manager skills.

Context in one line: one CONUS FVS variant whose tree- and stand-level fitted equations beat the
20 regional variants and Greg Johnson's CONUS equations, with a disturbance/treatment modifier
layer and calibrated uncertainty. Code lives in holoros/fvs-conus-components (mirror at
~/Documents/Claude/CRSF-Cowork/repos/fvs-conus-components); the Cardinal working tree ~/fvs-conus
is NOT a git repo, so commit changes through the mirror.

First, check job state on Cardinal (crsfaaron, account PUOM0008):
  - Ingrowth fits: ingrowth_hurdle_mid (11903567), ingrowth_negbinom_base (11903569),
    compos_v2_prod (11903568). When hurdle_mid and negbinom_base are both COMPLETED, run
    cd ~/fvs-conus && Rscript --vanilla R/elpd_compare_ingrowth.R <hurdle _fit.rds>
    <negbinom _fit.rds> /fs/scratch/PUOM0008/crsfaaron/fvs-conus/output/conus/ingrowth/elpd_compare
    and report which form wins by held-out ELPD (prefer the simpler negbinom unless elpd_diff
    exceeds about 2x its SE). Report compos_v2_prod convergence.
  - v3 constrained projector array: conus_eq_v3_array (original 11909922; OOM resubmit 11913643 at
    160G for CR/CS/LS/NE/SN/UT). Confirm all 38 (variant,mode) metrics land in
    /fs/scratch/PUOM0008/crsfaaron/fvs_stress/conus_eq_proj/out_conus_eq_v3/. If LS still OOMs,
    the fix is incremental treelist writing in conus_eq_projector_v3.R, not just more memory.

Then push these in order (autopilot is fine; do not cancel Aaron's other running jobs, and submit
analyses as sbatch to scratch):
  1. Swap the projector's FIX 2 ingrowth from the empirical per-variant lookup to the now-fitted
     negbinom count + trait composition models (net density = fitted ingrowth minus fitted
     self-thinning). Re-smoke on NE, then rerun the v3 array.
  2. Land the equation modifiers into the variant configs: run scripts/62m_modifier_to_variant_json.R
     (dry-run, then production write) with HCB trait-mediated and CR/DG/HG/mortality/ingrowth
     common, per modifiers/MODIFIER_STATUS_20260622.md. Refresh Manuscript Table 1 to that
     authoritative decision and finish the matched-N mortality refit.
  3. Add the engine modifier hook + inject the species-free equations into the fvs-modern Fortran
     engine (the make-or-break; today the engine runs on multipliers + SDIMAX, the fitted equations
     live only in the R projector). Use conus_eq_projector_v3.R as the executable specification.
  4. Confirm the localized max-SDI fix on a Western variant (PN or CR) density benchmark.
  5. Finalize kappa per component (species blend), then uncertainty + release (posterior + CSPI QRF
     draws, production config, merge, Zenodo deposit per docs/ZENODO_DEPOSIT_MANIFEST.md, DOI).

Keep the daily ingrowth-jobs-monitor scheduled task current and append results to the handoff memo
~/Documents/Claude/fvs-conus/20260621_session_handoff_review_and_preservation.md.
```

---

## Reference state

### Goal
One CONUS-unified FVS variant. Two design axes per component: tree-level vs stand-level, and
species-dependent (per-species) vs species-independent (trait-driven, "species-free"), combined by
a shrinkage blend w = n/(n+kappa). A Layer-2 disturbance/treatment modifier multiplies the base.

### Repositories (GitHub account holoros)
- `holoros/fvs-conus-components` (private) — the analysis code preserved this week: full R/ pipeline
  (170 scripts), stand_level/ (Garcia state-space), standlevel_drivers/, greg_comparison/,
  acadian_gy/, projector/ (v2 + v3 + calibration note), modifiers/, docs/, results/. Local mirror:
  `~/Documents/Claude/CRSF-Cowork/repos/fvs-conus-components`. Commit through the mirror
  (user.name holoros, email aaron.weiskittel@maine.edu).
- `holoros/fvs-calibration` — renamed from fvs-conus this week; the FVS Bayesian calibration
  pipeline. Local clone still in CRSF-Cowork/repos/fvs-conus (remote updated).
- `holoros/fvs-modern` (branch conus-sf-integration-2026-05-21) — the Fortran engine and the
  committed localized max-SDI module (calibration/sdimax/). No modifier hook yet; species-free
  equations not injected.
- `holoros/cspi-conus` — the Composite Site Productivity Index (the site driver).
- GitHub token: CRSF-Cowork/_context/.gh-holoros/token (gh auth login --with-token each session).

### Cardinal (OSC, user crsfaaron, account PUOM0008)
- SSH key under ~/Documents/Claude/.ssh-cardinal (discover via find; re-run the SSH setup block in
  every bash call, no carryover). scratch-first: /fs/scratch/PUOM0008/crsfaaron/. Home was at the
  500G cap; the 144G geotessera cache was relocated to scratch and symlinked, so home is clear.
- Working tree ~/fvs-conus (data/, R/, stan/, traits/, stand_level/, output/, scripts/). Ingrowth
  layout: ~/fvs-conus/{R,stan,traits,data}; the scripts hardcode a calibration/ prefix, resolved by
  symlinks ~/fvs-conus/calibration/{data,stan,traits,R} -> ../*.
- The equation projector is /fs/scratch/PUOM0008/crsfaaron/fvs_stress/conus_eq_proj/. NOTE: this is
  a pure-R reimplementation that applies the fitted equations directly; it is NOT the FVS Fortran
  engine. The Fortran engine receives only SDIMAX + multipliers.

### What is done
- Tree level built: DG (Kuehne v8, species-dependent b2 and species-free b1), HG (ORGANON v8rd),
  HT-DBH (Wykoff), HCB, CR recession, survival (logit + Greg gompit). Three validated fixes
  (survival senescence, CR2 + HCB annualization) pending production refit.
- Stand level (Garcia) production fit (stand_state_v3_production.R): density self-thinning
  rate = 0.4525*RD^2.73/yr, R^2(lnN)=0.60; basal area Gmax = 0.036*SDImax, k=0.0529/yr, with N and
  height-increment rate drivers raising increment R^2 from 0.13 to 0.18. Top height is carried from
  the tree HG model, not fit (FIA top-height increment is measurement-noise limited).
- v3 projector (projector/conus_eq_projector_v3.R): annualized (cyclelen is a plain multiplier over
  a fixed horizon) with the stand-level equations wired in to constrain the tree sum. Validated on
  NE: the fitted density constraint steepened the self-thinning slope from -1.12 (old ad hoc ramp)
  to about -1.87 (near Reineke -1.605) and capped the BA runaway (239 to ~85 ft2/ac); path
  invariance strong on density (1.4%) and QMD (3.6%), BA within ~10%. Cross-variant check confirmed
  the same pattern on every completed variant. Calibration sweep showed the slope is insensitive to
  ST_RATE, so the FIA-fitted coefficients are retained.
- Max-SDI: localized module finalized and committed to fvs-modern.
- Modifiers (Layer 2): fitting and the authoritative LOO form decision done. Only HCB is
  trait-mediated; CR, DG, HG, mortality, ingrowth are common. This corrects the smoke-era result
  that showed CR strongly trait-mediated. See modifiers/MODIFIER_STATUS_20260622.md.
- Code preserved, home freed, Zenodo deposit staged (not minted), repo renamed.

### Running on Cardinal (as of 2026-06-22, ~15:00)
- ingrowth_hurdle_mid 11903567, ingrowth_negbinom_base 11903569, compos_v2_prod 11903568: RUNNING
  ~14.7 h, no _fit.rds yet. (24-48 h walltime.)
- conus_eq_v3_array 11909922: 26/38 metrics done. OOM resubmit 11913643 (CR, CS, LS, NE, SN, UT both
  modes) RUNNING at 160G, throttle %4, idempotent skip.
- Aaron's own conus_eq_array 11909910 and conus_eq_gompit_array 11909911 RUNNING. Do NOT cancel.
- Scheduled task ingrowth-jobs-monitor (daily 07:32) reports the ELPD verdict, composition
  convergence, the v3 array progress, and the v3-vs-v2 cross-variant constraint check.

### Open items (priority order)
1. ELPD verdict (hurdle vs negbinom) when the fits land; finalize the trait composition fit.
2. Swap projector FIX 2 to the fitted ingrowth count + composition (currently an empirical lookup).
3. Land the modifiers into variant configs (62m, never run in production); refresh Manuscript Table
   1; matched-N mortality refit.
4. Add the engine modifier hook and inject the species-free equations into the Fortran engine
   (make-or-break); use the v3 projector as the executable spec.
5. Confirm max-SDI on a Western variant; finalize kappa; uncertainty + release (Zenodo DOI).

### Known risks
- v3 projector holds per-tree treelists for every stand and year in memory; LS (~138k stands) may
  exceed 160G. Fix: incremental treelist writing to disk, not just more memory.
- The CR modifier decision is borderline (2.0 SE); revisit if the production refit shifts it.
- Ingrowth Stan fits show frequent informational gamma_lpdf=0 rejections (mild ill-conditioning,
  non-fatal); check Rhat/ESS on completion.
