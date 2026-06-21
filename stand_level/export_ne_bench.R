suppressPackageStartupMessages(library(data.table))
d <- as.data.table(readRDS("data/conus_remeasurement_pairs_metric_cond_v2.rds")); nm<-names(d)
pick <- function(a,b) if(a %in% nm) a else b
fortyp<-pick("FORTYPCD_cond1","FORTYPCD"); stdage<-pick("STDAGE_cond1","STDAGE")
vcol <- if("fvs_variant"%in%nm) d$fvs_variant else NA
d <- d[fvs_variant=="NE" & is.finite(YEARS)&YEARS>=5&YEARS<=15 & is.finite(DBH1)&DBH1>=2.54 &
       is.finite(HT1)&HT1>1.3 & is.finite(CR1)&CR1>0&CR1<=1 & is.finite(TPH_UNADJ1)&TPH_UNADJ1>0 &
       is.finite(BA2)&BA2>0 & is.finite(TPH2)&TPH2>0 & is.finite(QMD2)&QMD2>0]
cnt <- d[, .N, by=plot_key][N>=12 & N<=120]
set.seed(7); keep <- cnt[sample(.N, min(30,.N))]$plot_key
sub <- d[plot_key %in% keep]
trees <- sub[, .(plot_key, SPCD, TPA_UNADJ=TPH_UNADJ1/2.4710538, DIA=DBH1/2.54, HT=HT1/0.3048, CR=pmin(pmax(CR1*100,15),99))]
fwrite(trees, "output/conus/stand_level/ne_bench_trees.csv")
plots <- sub[, .(SICOND=SICOND[1], STDAGE=get(stdage)[1], ASPECT=ASPECT[1], SLOPE=SLOPE[1], ELEV=ELEV[1],
                 STATECD=STATECD[1], COUNTYCD=if("COUNTYCD"%in%names(sub)) COUNTYCD[1] else 0L,
                 FORTYPCD=get(fortyp)[1], YEARS=round(YEARS[1]),
                 BA1=BA1[1], TPH1=TPH1[1], BA2_obs=BA2[1], TPH2_obs=TPH2[1], QMD2_obs=QMD2[1]), by=plot_key]
fwrite(plots, "output/conus/stand_level/ne_bench_plots.csv")
cat("exported plots:", nrow(plots), " tree rows:", nrow(trees), " mean YEARS:", round(mean(plots$YEARS),1), "\n")
cat("obs t2: meanBA", round(mean(plots$BA2_obs),1), "meanTPH", round(mean(plots$TPH2_obs),0), "meanQMD", round(mean(plots$QMD2_obs),1), "\n")
