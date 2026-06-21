suppressPackageStartupMessages({library(data.table); library(mgcv)})
# FVS variant-specific per-species SDImax (trees/acre)
v <- fread("data/VAR_SDIMAX.csv"); setattr(v,"names",make.unique(names(v)))
v <- v[is.finite(FVS_SDIMAX)&is.finite(FIA)]
vmap <- v[, .(fvs_sdi=mean(as.numeric(FVS_SDIMAX))), by=.(SPCD=FIA, variant=VARIANT)]
d <- as.data.table(readRDS("data/conus_remeasurement_pairs_metric_cond_v2.rds")); nm<-names(d)
sdi1c <- intersect(c("SDI1","SDI_1"), nm)[1]
d <- d[is.finite(DBH1)&DBH1>=2.54 & is.finite(TPH_UNADJ1)&TPH_UNADJ1>0 & is.finite(SDImax_brms) &
       is.finite(TPH1)&TPH1>0 & is.finite(TPH2)&TPH2>0 & is.finite(YEARS)&YEARS>=5&YEARS<=15 & is.finite(get(sdi1c))]
d[, tba := TPH_UNADJ1 * pi*(DBH1/200)^2]; d[, variant := fvs_variant]
d <- merge(d, vmap, by=c("SPCD","variant"), all.x=TRUE)
# West/East split via longitude
agg <- d[!is.na(fvs_sdi), .(
  fvs_sdimax = sum(tba*fvs_sdi,na.rm=TRUE)/sum(tba,na.rm=TRUE)*2.4710538,   # trees/ha
  brms_sdimax = as.numeric(SDImax_brms)[1],
  SDI1 = as.numeric(get(sdi1c))[1], TPH1=TPH1[1], TPH2=TPH2[1], YEARS=YEARS[1],
  LON=LON[1], L1=EPA_L1_CODE[1]), by=plot_key]
agg <- agg[is.finite(fvs_sdimax)&is.finite(brms_sdimax)&brms_sdimax>50&fvs_sdimax>50&SDI1>0]
# observed annual density change (negative = self-thinning/loss)
agg[, mort := -log(TPH2/TPH1)/YEARS]            # positive = density loss rate
agg <- agg[is.finite(mort) & mort > -0.15 & mort < 0.30]
agg[, RD_brms := SDI1/brms_sdimax][, RD_fvs := SDI1/fvs_sdimax]
agg[, region := ifelse(LON < -103, "West", "East")]
cat("plots:", nrow(agg), " West:", sum(agg$region=="West"), " East:", sum(agg$region=="East"), "\n")
cat(sprintf("mean RD_brms %.2f  RD_fvs %.2f  (FVS SDImax higher => RD lower)\n", mean(agg$RD_brms), mean(agg$RD_fvs)))
# THE TEST: which RD better predicts OBSERVED density-loss (self-thinning)?
test <- function(sub, lab){
  if(nrow(sub)<500) return()
  g_b <- bam(mort ~ s(RD_brms,k=8), data=sub); g_f <- bam(mort ~ s(RD_fvs,k=8), data=sub)
  # correlation of RD with observed mortality
  cb<-cor(sub$RD_brms, sub$mort); cf<-cor(sub$RD_fvs, sub$mort)
  cat(sprintf("%-6s n=%6d | dev.expl: RD_brms %.3f  RD_fvs %.3f | cor(RD,mort): brms %.3f fvs %.3f\n",
      lab, nrow(sub), summary(g_b)$dev.expl, summary(g_f)$dev.expl, cb, cf))
}
cat("\n== Which relative density better predicts OBSERVED self-thinning (density loss)? ==\n")
test(agg, "ALL"); test(agg[region=="East"], "East"); test(agg[region=="West"], "West")
# Among heavily self-thinning stands (top 10% observed loss), what RD does each SDImax imply?
hi <- agg[mort > quantile(mort, 0.90)]
cat(sprintf("\nHeavily self-thinning stands (top 10%% loss): mean RD_brms %.2f  RD_fvs %.2f\n", mean(hi$RD_brms), mean(hi$RD_fvs)))
cat("  (stands actually self-thinning should be near/above RD=1; the SDImax giving RD closer to 1 is more correct)\n")
cat("DONE_SELFTHIN\n")
