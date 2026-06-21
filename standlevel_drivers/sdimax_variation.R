suppressPackageStartupMessages({library(data.table); library(mgcv)})
d <- as.data.table(readRDS("data/conus_remeasurement_pairs_metric_cond_v2.rds")); nm<-names(d)
sdic <- intersect(c("SDImax_brms","SDImax"), nm)[1]
ftc  <- intersect(c("FORTYPCD_cond1","FORTYPCD"), nm)[1]
scc  <- intersect(c("SITECLCD_cond1","SITECLCD","SITECL"), nm)
# aggregate to plot
agg <- d[, .(SDImax=as.numeric(get(sdic))[1], FORTYP=get(ftc)[1], L3=EPA_L3_CODE[1], L2=EPA_L2_CODE[1],
             SICOND=SICOND[1], LAT=LAT[1], LON=LON[1]), by=plot_key]
agg <- agg[is.finite(SDImax)&SDImax>50&SDImax<2000]
cat("plots:", nrow(agg), "  SDImax mean", round(mean(agg$SDImax),0), " sd", round(sd(agg$SDImax),0), " CV", round(sd(agg$SDImax)/mean(agg$SDImax),3), "\n\n")
r2 <- function(form, data){ m<-lm(form, data=data); summary(m)$r.squared }
cat("Variance in plot max-SDI explained (lm R2):\n")
cat(sprintf("  by FOREST TYPE:        %.3f\n", tryCatch(r2(SDImax~factor(FORTYP), agg[is.finite(FORTYP)]),error=function(e)NA)))
cat(sprintf("  by EPA L3 ecoregion:   %.3f\n", tryCatch(r2(SDImax~factor(L3), agg[!is.na(L3)&L3!=""]),error=function(e)NA)))
cat(sprintf("  by EPA L2 ecoregion:   %.3f\n", tryCatch(r2(SDImax~factor(L2), agg[!is.na(L2)&L2!=""]),error=function(e)NA)))
cat(sprintf("  by SICOND (site):      %.3f\n", tryCatch(r2(SDImax~SICOND, agg[is.finite(SICOND)]),error=function(e)NA)))
cat(sprintf("  by FOREST TYPE + L3:   %.3f\n", tryCatch(r2(SDImax~factor(FORTYP)+factor(L3), agg[is.finite(FORTYP)&!is.na(L3)&L3!=""]),error=function(e)NA)))
cat(sprintf("  by FOREST TYPE + SICOND:%.3f\n", tryCatch(r2(SDImax~factor(FORTYP)+SICOND, agg[is.finite(FORTYP)&is.finite(SICOND)]),error=function(e)NA)))
# geographically weighted: smooth spatial surface (GAM) + forest type
gg <- agg[is.finite(LAT)&is.finite(LON)&is.finite(FORTYP)]
if(nrow(gg)>5000) gg<-gg[sample(.N,80000)]
m_geo <- bam(SDImax ~ s(LON,LAT,k=200), data=gg)
cat(sprintf("\n  GEOGRAPHIC smooth s(LON,LAT) only:        %.3f\n", summary(m_geo)$r.sq))
m_geoft <- bam(SDImax ~ s(LON,LAT,k=200) + factor(FORTYP), data=gg)
cat(sprintf("  GEOGRAPHIC smooth + forest type:          %.3f\n", summary(m_geoft)$r.sq))
m_full <- bam(SDImax ~ s(LON,LAT,k=200) + factor(FORTYP) + s(SICOND,k=10), data=gg[is.finite(SICOND)])
cat(sprintf("  GEOGRAPHIC + forest type + site (full):   %.3f\n", summary(m_full)$r.sq))
cat("\nDONE_SDIMAX_VAR\n")
