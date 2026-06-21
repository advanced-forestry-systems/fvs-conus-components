suppressPackageStartupMessages({library(data.table); library(mgcv)})
v <- fread("data/VAR_SDIMAX.csv"); setattr(v,"names",make.unique(names(v)))
v <- v[is.finite(FVS_SDIMAX)&is.finite(FIA)]
vmap <- unique(v[, .(SPCD=FIA, variant=VARIANT, fvs_sdi=as.numeric(FVS_SDIMAX))])
vmap <- vmap[, .(fvs_sdi=mean(fvs_sdi)), by=.(SPCD,variant)]
d <- as.data.table(readRDS("data/conus_remeasurement_pairs_metric_cond_v2.rds")); nm<-names(d)
cat("our variants:", paste(head(sort(unique(d$fvs_variant)),20),collapse=","), "\n")
cat("FVS variants:", paste(sort(unique(v$VARIANT)),collapse=","), "\n")
d <- d[is.finite(DBH1)&DBH1>=2.54 & is.finite(TPH_UNADJ1)&TPH_UNADJ1>0 & is.finite(SDImax_brms)]
d[, tba := TPH_UNADJ1 * pi*(DBH1/200)^2]; d[, variant := fvs_variant]
d <- merge(d, vmap, by=c("SPCD","variant"), all.x=TRUE)
cat("trees matched to variant-specific FVS SDImax:", round(100*mean(!is.na(d$fvs_sdi)),1), "%\n")
agg <- d[!is.na(fvs_sdi), .(fvs_wtd=sum(tba*fvs_sdi,na.rm=TRUE)/sum(tba,na.rm=TRUE)*2.4710538,
   brms=as.numeric(SDImax_brms)[1], FORTYP=if("FORTYPCD_cond1"%in%nm) FORTYPCD_cond1[1] else FORTYPCD[1],
   LAT=LAT[1], LON=LON[1]), by=plot_key]
agg <- agg[is.finite(fvs_wtd)&is.finite(brms)&brms>50&brms<2500&fvs_wtd>50&fvs_wtd<2500]
r2<-function(p,o) 1-sum((o-p)^2)/sum((o-mean(o))^2)
cat(sprintf("plots %d | brms mean %.0f  FVS variant-specific weighted mean %.0f  bias %+.0f%%\n",
  nrow(agg), mean(agg$brms), mean(agg$fvs_wtd), 100*mean(agg$fvs_wtd-agg$brms)/mean(agg$brms)))
cat(sprintf("FVS variant-specific species-weighted R2 vs brms: %.3f (RMSE %.0f)\n", r2(agg$fvs_wtd,agg$brms), sqrt(mean((agg$brms-agg$fvs_wtd)^2))))
# bias-corrected FVS (remove mean bias) to isolate the structural skill
bc <- agg$fvs_wtd * mean(agg$brms)/mean(agg$fvs_wtd)
cat(sprintf("FVS variant-specific, bias-corrected R2:           %.3f\n", r2(bc,agg$brms)))
gg<-agg[is.finite(LAT)&is.finite(LON)&is.finite(FORTYP)]; if(nrow(gg)>80000) gg<-gg[sample(.N,80000)]
cat(sprintf("localized (forest type + geography) R2:            %.3f\n", summary(bam(brms~factor(FORTYP)+s(LON,LAT,k=200),data=gg))$r.sq))
cat("DONE_CMP2\n")
