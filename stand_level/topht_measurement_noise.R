#!/usr/bin/env Rscript
# topht_measurement_noise.R -- quantify the top-height measurement/sampling noise to test the
# Garcia point: is the negative increment skill explained by observation error? Compares the
# per-plot top-height estimator SE to the mean periodic increment (the real signal).
suppressPackageStartupMessages({ library(data.table) })
d <- as.data.table(readRDS("data/conus_remeasurement_pairs_metric_cond_v2.rds"))
d <- d[is.finite(YEARS)&YEARS>=1&YEARS<=20&is.finite(HT1)&is.finite(HT2)&is.finite(DBH1)]
# per plot: top height = mean HT of top DBH quintile at t1; SE = sd/sqrt(k) of those heights
f <- function(ht,dbh){ thr<-quantile(dbh,0.8,na.rm=TRUE); v<-ht[dbh>=thr]; v<-v[is.finite(v)]
  list(H=mean(v), SE=if(length(v)>1) sd(v)/sqrt(length(v)) else NA_real_, k=length(v)) }
pl <- d[, { a<-f(HT1,DBH1); b<-f(HT2,DBH2); .(H1=a$H, SE1=a$SE, k=a$k, H2=b$H, dt=YEARS[1]) }, by=plot_key]
pl <- pl[is.finite(H1)&is.finite(H2)&is.finite(SE1)&H1>1.5&H2>1.5&k>=3]
pl[, inc:=H2-H1]
cat("plots:", nrow(pl), "\n")
cat(sprintf("mean periodic increment (signal): %.2f m  (sd %.2f)\n", mean(pl$inc), sd(pl$inc)))
cat(sprintf("mean top-height estimator SE (noise, one occasion): %.2f m  median %.2f\n", mean(pl$SE1), median(pl$SE1)))
cat(sprintf("noise on the DIFFERENCE ~ sqrt(2)*SE = %.2f m\n", sqrt(2)*mean(pl$SE1)))
# variance decomposition: var(observed increment) vs measurement variance on the difference
meas_var_diff <- 2*mean(pl$SE1^2)
cat(sprintf("var(observed increment)=%.2f ; measurement var on difference=%.2f ; share=%.0f%%\n",
            var(pl$inc), meas_var_diff, 100*meas_var_diff/var(pl$inc)))
cat(sprintf("=> reliability (signal share) of the observed increment ~ %.2f\n", 1-meas_var_diff/var(pl$inc)))
cat("DONE_NOISE\n")
