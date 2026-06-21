#!/usr/bin/env Rscript
# selfthin_diagnostic.R
# One-way stand-level diagnostic against the running equation projector (conus_eq_projector_v2.R).
# Reads the projector's stand-level metrics (BA, QMD, TPH by projection year) and checks whether
# the realized density trajectory follows Reineke self-thinning. The size-density self-thinning
# slope d ln(N) / d ln(QMD) should approach -1.605 on stands at the size-density limit. A slope
# materially shallower than that indicates under-thinning (the ad hoc SDImax mortality ramp, FIX 3,
# is not reproducing self-thinning), which is the case for replacing it with the fitted stand-level
# density curve (rate = 0.4525 * RD^2.73 per year).
#
# Note: the slope is taken over the full projection on stands that lose stems, so it includes the
# pre-peak building phase and is a rough, conservative (shallow-biased) estimate. Treat it as a
# direction-of-travel diagnostic, not a clean self-thinning-line fit.
suppressPackageStartupMessages(library(data.table))
D <- "/fs/scratch/PUOM0008/crsfaaron/fvs_stress/conus_eq_proj/out_conus_eq"
vars <- c("ne","pn","cr","sn","ls","ak")
out <- list()
for (v in vars) for (cfg in c("conus_b1","conus_b2")) {
  f <- file.path(D, sprintf("conus_eq_%s_%s_metrics.csv", v, cfg)); if (!file.exists(f)) next
  m <- fread(f); if (!all(c("STAND_CN","PROJ_YEAR","BA_FT2AC","QMD_IN","TPH") %in% names(m))) next
  m <- m[is.finite(BA_FT2AC) & is.finite(QMD_IN) & is.finite(TPH) & TPH > 0 & QMD_IN > 0]
  m[, SDI := TPH * (QMD_IN * 2.54 / 25)^1.605]
  setorder(m, STAND_CN, PROJ_YEAR)
  st <- m[, {
    lnN <- log(TPH); lnD <- log(QMD_IN); thin <- last(TPH) < first(TPH) * 0.98
    sl <- if (.N >= 4 && var(lnD) > 0 && thin) as.numeric(cov(lnN, lnD) / var(lnD)) else NA_real_
    .(slope = sl, peakSDI = max(SDI), thinning = thin)
  }, by = STAND_CN]
  out[[paste(v, cfg)]] <- data.table(
    variant = toupper(v), cfg = cfg, n = nrow(st),
    pct_selfthin = round(100 * mean(st$thinning), 0),
    reineke_slope_med = round(median(st$slope, na.rm = TRUE), 2),
    peakSDI_med = round(median(st$peakSDI, na.rm = TRUE), 0),
    peakSDI_p95 = round(quantile(st$peakSDI, 0.95, na.rm = TRUE), 0))
}
print(rbindlist(out))
