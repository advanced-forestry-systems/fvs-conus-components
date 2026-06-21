#!/usr/bin/env Rscript
# fit_topheight_gada.R -- Stand-level top-height prototype (Garcia tradition), robust optimizer.
# H2 = A*(1 - (1-(H1/A)^(1/b2))*exp(-b1*dt))^b2 ; A = a0 + a1*bgi_z (GADA on asymptote).
# Age-independent, annualized, path-invariant. nlminb with a clamped ratio for stability.
suppressPackageStartupMessages({ library(data.table) })
set.seed(1)
d <- as.data.table(readRDS("data/conus_remeasurement_pairs_metric_cond_v2.rds"))
cat("tree rows:", nrow(d), "\n")
need <- c("plot_key","DBH1","HT1","DBH2","HT2","YEARS","bgi","EPA_L1_CODE")
d <- d[complete.cases(d[, ..need])]
d <- d[HT1>1.5 & HT2>1.5 & DBH1>=2.54 & YEARS>=1 & YEARS<=20]
topht <- function(ht,dbh){ thr<-quantile(dbh,0.8,na.rm=TRUE); mean(ht[dbh>=thr],na.rm=TRUE) }
pl <- d[, .(H1=topht(HT1,DBH1), H2=topht(HT2,DBH2), dt=mean(YEARS), bgi=mean(bgi),
            ntree=.N, L1=EPA_L1_CODE[1]), by=plot_key]
pl <- pl[ntree>=5 & is.finite(H1)&is.finite(H2)&H1>1.5&H2>1.5]
pl[, hinc:=(H2-H1)/dt]; pl <- pl[hinc> -0.25 & hinc<2.0]
pl[, bgi_z:=as.numeric(scale(bgi))]
cat("plot pairs:", nrow(pl)," H1 mean/max:",round(mean(pl$H1),1),"/",round(max(pl$H1),1),
    " mean inc:",round(mean(pl$hinc),3),"\n\n")

pred_gada <- function(H1,dt,A,b1,b2){ r<-pmin(pmax(H1/A,1e-6),0.999); A*(1-(1-r^(1/b2))*exp(-b1*dt))^b2 }
rmse<-function(o,p)sqrt(mean((o-p)^2)); bias<-function(o,p)mean(p-o); r2<-function(o,p)1-sum((o-p)^2)/sum((o-mean(o))^2)
H1<-pl$H1; H2<-pl$H2; DT<-pl$dt; Z<-pl$bgi_z

sse1<-function(p){ pr<-pred_gada(H1,DT,p[1],p[2],p[3]); if(any(!is.finite(pr)))return(1e12); sum((H2-pr)^2) }
f1<-nlminb(c(45,0.04,1.6), sse1, lower=c(25,0.001,0.2), upper=c(130,0.6,6))
p1<-pred_gada(H1,DT,f1$par[1],f1$par[2],f1$par[3])
cat(sprintf("[M1 fixed A]  A=%.2f b1=%.4f b2=%.3f | RMSE=%.3f bias=%.3f R2=%.3f conv=%d\n",
            f1$par[1],f1$par[2],f1$par[3],rmse(H2,p1),bias(H2,p1),r2(H2,p1),f1$convergence))

sse2<-function(p){ A<-p[1]+p[2]*Z; pr<-pred_gada(H1,DT,A,p[3],p[4]); if(any(!is.finite(pr)))return(1e12); sum((H2-pr)^2) }
f2<-nlminb(c(45,3,0.04,1.6), sse2, lower=c(25,-20,0.001,0.2), upper=c(130,40,0.6,6))
A2<-f2$par[1]+f2$par[2]*Z; p2<-pred_gada(H1,DT,A2,f2$par[3],f2$par[4])
n<-nrow(pl); aic<-function(ss,k)n*log(ss/n)+2*k
cat(sprintf("[M2 GADA bgi] a0=%.2f a1=%.2f b1=%.4f b2=%.3f | RMSE=%.3f bias=%.3f R2=%.3f dAIC=%.1f conv=%d\n",
            f2$par[1],f2$par[2],f2$par[3],f2$par[4],rmse(H2,p2),bias(H2,p2),r2(H2,p2),
            aic(sum((H2-p2)^2),4)-aic(sum((H2-p1)^2),3), f2$convergence))

cat("\n[path-invariance check, M2]\n")
b1<-f2$par[3]; b2<-f2$par[4]; s<-sample(n,6)
for(i in s){ A<-f2$par[1]+f2$par[2]*Z[i]; H<-H1[i]
  Ha<-H; for(k in 1:10) Ha<-pred_gada(Ha,1,A,b1,b2)
  H10<-pred_gada(H,10,A,b1,b2)
  cat(sprintf("  H1=%.1f bgi_z=%+.2f  10x1yr=%.4f  1x10yr=%.4f  |diff|=%.2e\n",H,Z[i],Ha,H10,abs(Ha-H10))) }

saveRDS(list(f1=f1,f2=f2,n=n), "output/conus/stand_level/topheight_gada_fit.rds")
fwrite(data.table(model=c("fixedA","gada_bgi"),
  a0_A=c(f1$par[1],f2$par[1]), a1=c(NA,f2$par[2]), b1=c(f1$par[2],f2$par[3]), b2=c(f1$par[3],f2$par[4]),
  RMSE=c(rmse(H2,p1),rmse(H2,p2)), bias=c(bias(H2,p1),bias(H2,p2)), R2=c(r2(H2,p1),r2(H2,p2))),
  "output/conus/stand_level/topheight_gada_summary.csv")
cat("\nDONE_TOPHT_GADA\n")
