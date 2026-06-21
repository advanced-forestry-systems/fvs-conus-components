#!/usr/bin/env Rscript
# stand_state_v3_production.R
# Production Garcia-tradition stand-level fits for the CONUS variant constraint layer.
# Builds on stand_state_v2.R (the fits behind the 2026-06-11 memo): density self-thinning
# (power form on relative density) and basal area (monomolecular toward an SDImax carrying
# capacity). Adds the refinement noted in the strategy memo: N and H increment as drivers of
# the basal area rate. Saves coefficient artifacts to stand_level_production/.
# Top height is deliberately NOT fit here: the FIA plot top-height increment is measurement
# noise limited, so top height is carried from the tree-level HG model over the dominant cohort.
suppressPackageStartupMessages({ library(data.table) })
set.seed(1)
PAIRS <- "data/conus_remeasurement_pairs_metric_cond_v2.rds"
OUT   <- "stand_level_production"; dir.create(OUT, showWarnings = FALSE)

cat("loading pairs...\n"); d <- as.data.table(readRDS(PAIRS)); nm <- names(d)
cat("nrow:", nrow(d), " ncol:", length(nm), "\n")
if (!("TPH1" %in% nm) && "TPA1" %in% nm) { d[, TPH1 := TPA1 * 2.47105]; d[, TPH2 := TPA2 * 2.47105] }
sdimax_col <- intersect(c("SDImax_brms", "SDImax", "sdimax"), nm)[1]
pk <- intersect(c("plot_key", "PLT_CN", "PLT_CN_cond1"), nm)[1]
if (is.na(pk)) stop("no plot key; first names: ", paste(head(nm, 60), collapse = ","))
cat("plot key:", pk, " | sdimax col:", sdimax_col, "\n")
setnames(d, pk, "PKEY")

d <- d[is.finite(YEARS) & YEARS >= 1 & YEARS <= 20]
topht <- function(ht, dbh) { thr <- quantile(dbh, 0.8, na.rm = TRUE); mean(ht[dbh >= thr], na.rm = TRUE) }
pl <- d[, .(H1 = topht(HT1, DBH1), H2 = topht(HT2, DBH2), dt = YEARS[1],
            N1 = TPH1[1], N2 = TPH2[1], BA1 = BA1[1], BA2 = BA2[1], SDI1 = SDI1[1],
            SDImax = if (length(sdimax_col)) get(sdimax_col)[1] else NA_real_,
            cspi = if ("cspi" %in% nm) cspi[1] else NA_real_, ntree = .N), by = PKEY]
pl <- pl[ntree >= 5 & is.finite(SDImax) & SDImax > 0]
r2 <- function(o, p) 1 - sum((o - p)^2) / sum((o - mean(o))^2)
rmse <- function(o, p) sqrt(mean((o - p)^2))
zsc <- function(x) (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
cat("plot pairs:", nrow(pl), "\n\n")
res <- list(n_plot_pairs = nrow(pl), sdimax_col = sdimax_col, fitted = Sys.time())

## (B) DENSITY self-thinning, power form: lnN2 = lnN1 - exp(c0)*RD^c1*dt
s <- pl[is.finite(N1) & is.finite(N2) & N1 > 0 & N2 > 0 & is.finite(SDI1)]
s[, RD := SDI1 / SDImax]; s <- s[RD > 0.02 & RD < 1.5]
lnN1 <- log(s$N1); lnN2 <- log(s$N2); RD <- s$RD; DT <- s$dt
sse <- function(p) { pr <- lnN1 - exp(p[1]) * RD^p[2] * DT; sum((lnN2 - pr)^2) }
fD <- nlminb(c(log(0.02), 1.5), sse, lower = c(log(1e-4), 0.3), upper = c(log(2), 5))
prD <- lnN1 - exp(fD$par[1]) * RD^fD$par[2] * DT
res$density <- list(coef_rate = exp(fD$par[1]), coef_exp = fD$par[2],
                    rmse_lnN = rmse(lnN2, prD), r2_lnN = r2(lnN2, prD), n = nrow(s),
                    loss_pct_yr = sapply(c(0.3, 0.6, 1.0), function(rd) 100 * exp(fD$par[1]) * rd^fD$par[2]))
cat(sprintf("(B) density: rate = %.4f * RD^%.2f /yr | RMSE(lnN)=%.3f R2=%.3f  (n=%d)\n",
            exp(fD$par[1]), fD$par[2], rmse(lnN2, prD), r2(lnN2, prD), nrow(s)))
for (rd in c(0.3, 0.6, 1.0)) cat(sprintf("    RD=%.1f -> %.2f%%/yr loss\n", rd, 100 * exp(fD$par[1]) * rd^fD$par[2]))

## (C0) BASAL AREA baseline: Gmax = g0 + g1*SDImax ; BA2 = BA1 + (Gmax-BA1)(1-exp(-k*dt))
b <- pl[is.finite(BA1) & is.finite(BA2) & BA1 > 0 & BA2 > 0 & is.finite(H1) & is.finite(H2) & is.finite(N1)]
b[, dH := pmax(H2 - H1, 0)]
BA1 <- b$BA1; BA2 <- b$BA2; DT2 <- b$dt; SM <- b$SDImax
sse0 <- function(p) { Gmax <- p[1] + p[2] * SM; pr <- BA1 + (Gmax - BA1) * (1 - exp(-p[3] * DT2)); if (any(!is.finite(pr))) return(1e12); sum((BA2 - pr)^2) }
f0 <- nlminb(c(10, 0.05, 0.05), sse0, lower = c(0, 0, 0.001), upper = c(80, 0.6, 0.6))
Gmax0 <- f0$par[1] + f0$par[2] * SM; pr0 <- BA1 + (Gmax0 - BA1) * (1 - exp(-f0$par[3] * DT2))
res$ba_baseline <- list(g0 = f0$par[1], g1 = f0$par[2], k = f0$par[3],
                        rmse = rmse(BA2, pr0), r2_inc = r2(BA2 - BA1, pr0 - BA1), n = nrow(b))
cat(sprintf("\n(C0) BA baseline: Gmax=%.1f + %.3f*SDImax  k=%.4f/yr | g1 %s | RMSE=%.3f R2_inc=%.3f\n",
            f0$par[1], f0$par[2], f0$par[3], ifelse(f0$par[2] > 0, "POSITIVE", "NEG flag"),
            rmse(BA2, pr0), r2(BA2 - BA1, pr0 - BA1)))

## (C1) BASAL AREA + rate drivers: k = exp(k0 + k1*z(dH) + k2*z(N1))  (the noted refinement)
zdH <- zsc(b$dH); zN <- zsc(b$N1)
sse1 <- function(p) {
  Gmax <- p[1] + p[2] * SM; k <- exp(p[3] + p[4] * zdH + p[5] * zN)
  pr <- BA1 + (Gmax - BA1) * (1 - exp(-k * DT2)); if (any(!is.finite(pr))) return(1e12); sum((BA2 - pr)^2)
}
f1 <- nlminb(c(10, 0.05, log(0.05), 0, 0), sse1,
             lower = c(0, 0, log(1e-3), -2, -2), upper = c(80, 0.6, log(0.6), 2, 2))
k1 <- exp(f1$par[3] + f1$par[4] * zdH + f1$par[5] * zN)
Gmax1 <- f1$par[1] + f1$par[2] * SM; pr1 <- BA1 + (Gmax1 - BA1) * (1 - exp(-k1 * DT2))
res$ba_ratedrivers <- list(g0 = f1$par[1], g1 = f1$par[2], k0 = f1$par[3],
                           k_dH = f1$par[4], k_N = f1$par[5],
                           rmse = rmse(BA2, pr1), r2_inc = r2(BA2 - BA1, pr1 - BA1), n = nrow(b))
cat(sprintf("(C1) BA + rate drivers: Gmax=%.1f + %.3f*SDImax  k=exp(%.3f %+.3f*z(dH) %+.3f*z(N)) | RMSE=%.3f R2_inc=%.3f\n",
            f1$par[1], f1$par[2], f1$par[3], f1$par[4], f1$par[5],
            rmse(BA2, pr1), r2(BA2 - BA1, pr1 - BA1)))
cat(sprintf("    BA increment R2: baseline %.3f -> with rate drivers %.3f (delta %+.3f)\n",
            res$ba_baseline$r2_inc, res$ba_ratedrivers$r2_inc,
            res$ba_ratedrivers$r2_inc - res$ba_baseline$r2_inc))

saveRDS(res, file.path(OUT, "stand_state_production_fit.rds"))
flat <- data.table(
  model = c("density_power", "ba_baseline", "ba_rate_drivers"),
  n = c(res$density$n, res$ba_baseline$n, res$ba_ratedrivers$n),
  key_stat = c(sprintf("rate=%.4f*RD^%.2f", res$density$coef_rate, res$density$coef_exp),
               sprintf("Gmax=%.1f+%.3f*SDImax,k=%.4f", res$ba_baseline$g0, res$ba_baseline$g1, res$ba_baseline$k),
               sprintf("g1=%.3f,k0=%.3f,k_dH=%.3f,k_N=%.3f", res$ba_ratedrivers$g1, res$ba_ratedrivers$k0, res$ba_ratedrivers$k_dH, res$ba_ratedrivers$k_N)),
  r2 = c(res$density$r2_lnN, res$ba_baseline$r2_inc, res$ba_ratedrivers$r2_inc))
fwrite(flat, file.path(OUT, "stand_state_production_summary.csv"))
cat("\nsaved:", file.path(OUT, "stand_state_production_fit.rds"), "\nDONE_STAND_V3\n")
