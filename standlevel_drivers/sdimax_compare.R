suppressPackageStartupMessages({library(data.table); library(mgcv)})
v <- fread("data/VAR_SDIMAX.csv")
setattr(v,"names",make.unique(names(v)))
v <- v[is.finite(FVS_SDIMAX) & is.finite(FIA)]
# species x variant -> FVS per-species SDImax (trees/acre). Also a species-mean across variants.
vmap <- v[, .(fvs_sdi=mean(as.numeric(FVS_SDIMAX),na.rm=TRUE)), by=.(SPCD=FIA, VARIANT)]
spmean <- v[, .(fvs_sdi_spmean=mean(as.numeric(FVS_SDIMAX),na.rm=TRUE)), by=.(SPCD=FIA)]
cat("VAR_SDIMAX: variants", uniqueN(v$VARIANT), " species", uniqueN(v$FIA),
    " FVS_SDIMAX range", paste(round(range(v$FVS_SDIMAX,na.rm=TRUE)),collapse="-"), "trees/acre\n")

d <- as.data.table(readRDS("data/conus_remeasurement_pairs_metric_cond_v2.rds")); nm<-names(d)
# per-tree basal area (m2/ha) for BA-weighting; SPCD, variant
d <- d[is.finite(DBH1)&DBH1>=2.54 & is.finite(TPH_UNADJ1)&TPH_UNADJ1>0 & is.finite(SDImax_brms)]
d[, tba := TPH_UNADJ1 * pi*(DBH1/200)^2]
d <- merge(d, spmean, by="SPCD", all.x=TRUE)  # species-mean FVS SDImax (trees/acre)
# BA-weighted FVS species-weighted SDImax per plot (convert acre->ha *2.471)
agg <- d[!is.na(fvs_sdi_spmean), .(
  fvs_wtd_sdi = sum(tba*fvs_sdi_spmean,na.rm=TRUE)/sum(tba,na.rm=TRUE) * 2.4710538,
  brms = as.numeric(SDImax_brms)[1],
  FORTYP = if("FORTYPCD_cond1" %in% nm) FORTYPCD_cond1[1] else FORTYPCD[1],
  L3 = EPA_L3_CODE[1], LAT=LAT[1], LON=LON[1], variant=fvs_variant[1]), by=plot_key]
agg <- agg[is.finite(fvs_wtd_sdi)&is.finite(brms)&brms>50&brms<2500&fvs_wtd_sdi>50&fvs_wtd_sdi<2500]
cat("plots:", nrow(agg), "\n")
cat(sprintf("brms (FIA truth): mean %.0f /ha   FVS species-weighted: mean %.0f /ha   bias(FVS-brms) %.0f  (%+.0f%%)\n",
    mean(agg$brms), mean(agg$fvs_wtd_sdi), mean(agg$fvs_wtd_sdi-agg$brms), 100*mean(agg$fvs_wtd_sdi-agg$brms)/mean(agg$brms)))
r2<-function(p,o) 1-sum((o-p)^2)/sum((o-mean(o))^2)
cat(sprintf("\nHow well each predicts the brms FIA plot max SDI (R2):\n"))
cat(sprintf("  FVS species-weighted:                 %.3f  (RMSE %.0f)\n", r2(agg$fvs_wtd_sdi,agg$brms), sqrt(mean((agg$brms-agg$fvs_wtd_sdi)^2))))
gg<-agg[is.finite(LAT)&is.finite(LON)&is.finite(FORTYP)]; if(nrow(gg)>80000) gg<-gg[sample(.N,80000)]
m1<-bam(brms~factor(FORTYP)+s(LON,LAT,k=200), data=gg)
cat(sprintf("  localized (forest type + geography):  %.3f\n", summary(m1)$r.sq))
# does adding the FVS species-weighted value help beyond geography+forest type?
m2<-bam(brms~factor(FORTYP)+s(LON,LAT,k=200)+fvs_wtd_sdi, data=gg)
cat(sprintf("  localized + FVS species-weighted:     %.3f\n", summary(m2)$r.sq))
cat("\nDONE_CMP\n")
