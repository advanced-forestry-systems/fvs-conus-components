#!/usr/bin/env Rscript
# topht_ht40.R -- lower-noise dominant height (HT40: largest 100 trees/ha by expansion) and
# re-test increment reliability + GADA skill vs the noisy top-DBH-quintile definition.
suppressPackageStartupMessages({ library(data.table) })
set.seed(1)
d <- as.data.table(readRDS("data/conus_remeasurement_pairs_metric_cond_v2.rds")); nm<-names(d)
expcol <- intersect(c("TPH_UNADJ1","EXPAN1","TPA_UNADJ1"), nm)[1]
cat("per-tree expansion column:", expcol, "\n")
d[, exp_tph := get(expcol)]; if(expcol %in% c("EXPAN1","TPA_UNADJ1")) d[, exp_tph := exp_tph*2.47105]
d <- d[is.finite(YEARS)&YEARS>=1&YEARS<=20&is.finite(HT1)&is.finite(HT2)&is.finite(DBH1)&is.finite(exp_tph)&exp_tph>0]
# dominant height = expansion-weighted mean HT of the largest trees up to 100 trees/ha
domht <- function(ht,dbh,e,target=100){ o<-order(-dbh); ht<-ht[o]; e<-e[o]; cw<-cumsum(e)
  k<-which(cw>=target)[1]; if(is.na(k)) k<-length(e); w<-e[1:k]; w[k]<-w[k]-(cw[k]-target)
  list(H=sum(ht[1:k]*w)/sum(w), SE=sqrt(sum(w^2)/sum(w)^2)*sd(ht[1:k]), k=k) }
pl <- d[, { a<-domht(HT1,DBH1,exp_tph); b<-domht(HT2,DBH2,exp_tph)
            .(H1=a$H, SE1=a$SE, k=a$k, H2=b$H, dt=YEARS[1], cspi=cspi[1]) }, by=plot_key]
pl <- pl[is.finite(H1)&is.finite(H2)&H1>1.5&H2>1.5&H1<95&is.finite(cspi)]
pl[, inc:=H2-H1]; pl <- pl[inc> -2 & inc < 16]
pl[, cspi_z:=as.numeric(scale(cspi))]
cat("plots:", nrow(pl), " mean k(trees in HT40):", round(mean(pl$k),1), "\n")
cat(sprintf("HT40: mean increment %.2f m (sd %.2f) ; mean estimator SE %.2f m\n", mean(pl$inc),sd(pl$inc),mean(pl$SE1,na.rm=TRUE)))
mv <- 2*mean(pl$SE1^2,na.rm=TRUE)
cat(sprintf("measurement var on difference=%.2f ; var(increment)=%.2f ; reliability=%.2f (quintile was -0.22)\n", mv, var(pl$inc), 1-mv/var(pl$inc)))
# GADA fit on HT40, CSPI asymptote
pg<-function(H,dt,A,b1,b2){r<-pmin(pmax(H/A,1e-6),0.999);A*(1-(1-r^(1/b2))*exp(-b1*dt))^b2}
sse<-function(p){A<-p[1]+p[2]*pl$cspi_z;pr<-pg(pl$H1,pl$dt,A,p[3],p[4]);if(any(!is.finite(pr))||any(A<=pl$H1*0.5))return(1e12);sum((pl$H2-pr)^2)}
f<-nlminb(c(42,1,0.04,3),sse,lower=c(25,-15,0.001,0.3),upper=c(140,30,0.6,6))
A<-f$par[1]+f$par[2]*pl$cspi_z; pr<-pg(pl$H1,pl$dt,A,f$par[3],f$par[4])
r2<-function(o,p)1-sum((o-p)^2)/sum((o-mean(o))^2)
cat(sprintf("GADA on HT40: a1(cspi)=%.2f RMSE=%.3f R2_increment=%.3f (quintile was -0.11)\n",
            f$par[2], sqrt(mean((pl$H2-pr)^2)), r2(pl$inc, pr-pl$H1)))
cat("DONE_HT40\n")
