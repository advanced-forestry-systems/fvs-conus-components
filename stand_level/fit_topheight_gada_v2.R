#!/usr/bin/env Rscript
# fit_topheight_gada_v2.R -- refined: asymptote driven by CSPI (height site index) + L1 ecoregion
#   A_i = a0 + a1*cspi_z + offset[L1_i]   (ref L1 offset = 0)
# Reports increment-level skill (honest), asymptote sign, per-region A, path-invariance.
suppressPackageStartupMessages({ library(data.table) })
set.seed(1)
d <- as.data.table(readRDS("data/conus_remeasurement_pairs_metric_cond_v2.rds"))
need <- c("plot_key","DBH1","HT1","DBH2","HT2","YEARS","cspi","EPA_L1_CODE")
d <- d[complete.cases(d[, ..need])]
d <- d[HT1>1.5 & HT2>1.5 & DBH1>=2.54 & YEARS>=1 & YEARS<=20 & is.finite(cspi)]
topht <- function(ht,dbh){ thr<-quantile(dbh,0.8,na.rm=TRUE); mean(ht[dbh>=thr],na.rm=TRUE) }
pl <- d[, .(H1=topht(HT1,DBH1), H2=topht(HT2,DBH2), dt=mean(YEARS),
            cspi=mean(cspi), L1=EPA_L1_CODE[1], ntree=.N), by=plot_key]
pl <- pl[ntree>=5 & is.finite(H1)&is.finite(H2)&H1>1.5&H2>1.5]
pl[, hinc:=(H2-H1)/dt]; pl <- pl[hinc> -0.25 & hinc<2.0]
pl[, cspi_z:=as.numeric(scale(cspi))]
pl[, L1:=as.factor(L1)]; L1lev<-levels(pl$L1); pl[, L1i:=as.integer(L1)]
cat("plot pairs:", nrow(pl), " nL1:", length(L1lev), "\n\n")
H1<-pl$H1; H2<-pl$H2; DT<-pl$dt; CZ<-pl$cspi_z; L1i<-pl$L1i; K<-length(L1lev)
pred_gada <- function(H1,dt,A,b1,b2){ r<-pmin(pmax(H1/A,1e-6),0.999); A*(1-(1-r^(1/b2))*exp(-b1*dt))^b2 }
# params: a0, a1, b1, b2, then (K-1) L1 offsets (level 1 = 0)
sse<-function(p){ off<-c(0,p[5:(4+K-1)]); A<-p[1]+p[2]*CZ+off[L1i]
  pr<-pred_gada(H1,DT,A,p[3],p[4]); if(any(!is.finite(pr))||any(A<=H1*0.5))return(1e12); sum((H2-pr)^2) }
st<-c(45,2,0.02,3, rep(0,K-1)); lo<-c(25,-15,0.001,0.2,rep(-30,K-1)); hi<-c(140,30,0.6,6,rep(40,K-1))
f<-nlminb(st,sse,lower=lo,upper=hi,control=list(iter.max=500,eval.max=700))
off<-c(0,f$par[5:(4+K-1)]); A<-f$par[1]+f$par[2]*CZ+off[L1i]; pr<-pred_gada(H1,DT,A,f$par[3],f$par[4])
inc_o<-H2-H1; inc_p<-pr-H1
r2lvl<-1-sum((H2-pr)^2)/sum((H2-mean(H2))^2); r2inc<-1-sum((inc_o-inc_p)^2)/sum((inc_o-mean(inc_o))^2)
cat(sprintf("a0=%.2f  a1(cspi)=%+.3f  b1=%.4f  b2=%.3f  conv=%d\n",f$par[1],f$par[2],f$par[3],f$par[4],f$convergence))
cat(sprintf("RMSE=%.3f m  bias=%.3f m  R2_level=%.3f  R2_increment=%.3f\n",
            sqrt(mean((H2-pr)^2)),mean(pr-H2),r2lvl,r2inc))
cat("asymptote a1(cspi) sign:", ifelse(f$par[2]>0,"POSITIVE (expected)","NEGATIVE (flag)"),"\n")
cat("per-L1 asymptote offset (m), ref=",L1lev[1],":\n"); print(round(setNames(off,L1lev),2))
cat("\n[path-invariance]\n"); b1<-f$par[3]; b2<-f$par[4]
for(i in sample(nrow(pl),5)){ Ai<-A[i]; H<-H1[i]; Ha<-H; for(k in 1:10) Ha<-pred_gada(Ha,1,Ai,b1,b2)
  cat(sprintf("  H1=%.1f A=%.1f  10x1=%.4f 1x10=%.4f |d|=%.1e\n",H,Ai,Ha,pred_gada(H,10,Ai,b1,b2),abs(Ha-pred_gada(H,10,Ai,b1,b2)))) }
saveRDS(list(fit=f,L1lev=L1lev,n=nrow(pl)),"output/conus/stand_level/topheight_gada_v2_fit.rds")
cat("\nDONE_TOPHT_V2\n")
