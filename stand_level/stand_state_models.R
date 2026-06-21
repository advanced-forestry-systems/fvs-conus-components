#!/usr/bin/env Rscript
# stand_state_models.R -- additional Garcia-tradition stand-level transitions, all
# age-independent, annualized, path-invariant. Three models, each wrapped so one failure
# does not stop the others:
#   (A) top-height v3: asymptote AND rate vary by L1 ecoregion (addresses v2 increment skill)
#   (B) density N: self-thinning net-rate driven by relative density SDI/SDImax
#   (C) basal area G: monomolecular approach to a site-driven maximum
suppressPackageStartupMessages({ library(data.table) })
set.seed(1)
d <- as.data.table(readRDS("data/conus_remeasurement_pairs_metric_cond_v2.rds"))
cat("tree rows:", nrow(d), "\n"); nm <- names(d)
hasc <- function(x) all(x %in% nm)
# density column: prefer TPH (metric), else TPA*2.47105
if(!("TPH1" %in% nm) && "TPA1" %in% nm){ d[, TPH1:=TPA1*2.47105]; d[, TPH2:=TPA2*2.47105] }
need <- c("plot_key","DBH1","HT1","DBH2","HT2","YEARS","cspi","EPA_L1_CODE",
          "BA1","BA2","SDI1","TPH1","TPH2")
miss <- setdiff(need, names(d)); if(length(miss)) cat("MISSING cols:", paste(miss,collapse=","), "\n")
sdimax_col <- intersect(c("SDImax_brms","SDImax","sdimax"), nm)[1]
d <- d[is.finite(YEARS)&YEARS>=1&YEARS<=20 & is.finite(HT1)&is.finite(HT2)&is.finite(DBH1)]
topht <- function(ht,dbh){ thr<-quantile(dbh,0.8,na.rm=TRUE); mean(ht[dbh>=thr],na.rm=TRUE) }
pl <- d[, .(H1=topht(HT1,DBH1), H2=topht(HT2,DBH2), dt=YEARS[1],
            N1=TPH1[1], N2=TPH2[1], BA1=BA1[1], BA2=BA2[1], SDI1=SDI1[1],
            SDImax=if(length(sdimax_col)) get(sdimax_col)[1] else NA_real_,
            cspi=cspi[1], L1=EPA_L1_CODE[1], ntree=.N), by=plot_key]
pl <- pl[ntree>=5 & is.finite(cspi)]
pl[, cspi_z:=as.numeric(scale(cspi))]
pl[, L1:=as.factor(L1)]; L1lev<-levels(pl$L1); pl[, L1i:=as.integer(L1)]; K<-length(L1lev)
cat("plot pairs:", nrow(pl), " nL1:", K, "\n\n")
r2<-function(o,p)1-sum((o-p)^2)/sum((o-mean(o))^2); rmse<-function(o,p)sqrt(mean((o-p)^2))

## ---- (A) top-height v3: asymptote + rate by ecoregion ----
tryCatch({
  s<-pl[is.finite(H1)&is.finite(H2)&H1>1.5&H2>1.5]; s[,hinc:=(H2-H1)/dt]; s<-s[hinc> -0.25&hinc<2]
  H1<-s$H1;H2<-s$H2;DT<-s$dt;CZ<-s$cspi_z;Li<-s$L1i
  pg<-function(H,dt,A,b1,b2){r<-pmin(pmax(H/A,1e-6),0.999);A*(1-(1-r^(1/b2))*exp(-b1*dt))^b2}
  # params: a0,a1,b2,lb0, offA[2..K], lbo[2..K]
  np<-4+2*(K-1)
  sse<-function(p){A<-p[1]+p[2]*CZ+c(0,p[5:(3+K)])[Li]; b1<-exp(p[4]+c(0,p[(4+K):(2+2*K)])[Li])
    pr<-pg(H1,DT,A,b2=p[3],b1=b1); if(any(!is.finite(pr))||any(A<=H1*0.5))return(1e12); sum((H2-pr)^2)}
  st<-c(42,1,3,log(0.01),rep(0,K-1),rep(0,K-1))
  lo<-c(25,-15,0.3,log(1e-4),rep(-25,K-1),rep(-3,K-1)); hi<-c(140,30,6,log(0.3),rep(35,K-1),rep(3,K-1))
  f<-nlminb(st,sse,lower=lo,upper=hi,control=list(iter.max=800,eval.max=1000))
  A<-f$par[1]+f$par[2]*CZ+c(0,f$par[5:(3+K)])[Li]; b1<-exp(f$par[4]+c(0,f$par[(4+K):(2+2*K)])[Li])
  pr<-pg(H1,DT,A,b2=f$par[3],b1=b1); inc_o<-H2-H1; inc_p<-pr-H1
  cat(sprintf("(A) TOPHT v3: a0=%.1f a1=%.2f b2=%.2f | RMSE=%.3f R2_inc=%.3f (v2 was -0.11) conv=%d\n",
      f$par[1],f$par[2],f$par[3],rmse(H2,pr),r2(inc_o,inc_p),f$convergence))
}, error=function(e) cat("(A) topht v3 FAILED:", conditionMessage(e), "\n"))

## ---- (B) density self-thinning: N2 = N1*exp((a0+a1*RD1)*dt), RD1=SDI1/SDImax ----
tryCatch({
  s<-pl[is.finite(N1)&is.finite(N2)&N1>0&N2>0&is.finite(SDI1)&is.finite(SDImax)&SDImax>0]
  s[,RD1:=SDI1/SDImax]; s<-s[RD1>0&RD1<1.5]
  cat(sprintf("(B) density n=%d  mean RD1=%.2f  mean N1=%.0f N2=%.0f /ha\n",nrow(s),mean(s$RD1),mean(s$N1),mean(s$N2)))
  lnN2<-log(s$N2); RD<-s$RD1; DT<-s$dt; lnN1<-log(s$N1)
  sse<-function(p){ pr<-lnN1+(p[1]+p[2]*RD)*DT; sum((lnN2-pr)^2) }
  f<-nlminb(c(0.005,-0.02),sse)
  pr<-lnN1+(f$par[1]+f$par[2]*RD)*DT
  cat(sprintf("    rate r = %.4f + %.4f*RD per yr  | a1 sign %s | RMSE(lnN)=%.3f R2=%.3f\n",
      f$par[1],f$par[2], ifelse(f$par[2]<0,"NEGATIVE (self-thinning, expected)","POSITIVE (flag)"),
      rmse(lnN2,pr), r2(lnN2,pr)))
  cat(sprintf("    => at RD=0.3 net %.2f%%/yr ; at RD=1.0 net %.2f%%/yr\n",
      100*(f$par[1]+f$par[2]*0.3), 100*(f$par[1]+f$par[2]*1.0)))
}, error=function(e) cat("(B) density FAILED:", conditionMessage(e), "\n"))

## ---- (C) basal area: BA2 = BA1 + (Gmax-BA1)*(1-exp(-k*dt)), Gmax=g0+g1*cspi_z ----
tryCatch({
  s<-pl[is.finite(BA1)&is.finite(BA2)&BA1>0&BA2>0]
  BA1<-s$BA1;BA2<-s$BA2;DT<-s$dt;CZ<-s$cspi_z
  sse<-function(p){Gmax<-p[1]+p[2]*CZ; k<-p[3]; pr<-BA1+(Gmax-BA1)*(1-exp(-k*DT)); if(any(!is.finite(pr)))return(1e12); sum((BA2-pr)^2)}
  f<-nlminb(c(45,8,0.05),sse,lower=c(15,-20,0.001),upper=c(150,40,0.6))
  Gmax<-f$par[1]+f$par[2]*CZ; pr<-BA1+(Gmax-BA1)*(1-exp(-f$par[3]*DT)); inc_o<-BA2-BA1; inc_p<-pr-BA1
  cat(sprintf("(C) BASAL AREA: Gmax=%.1f%+.2f*cspi_z  k=%.4f/yr | RMSE=%.3f m2/ha  R2_inc=%.3f conv=%d\n",
      f$par[1],f$par[2],f$par[3],rmse(BA2,pr),r2(inc_o,inc_p),f$convergence))
  # path-invariance (monomolecular is autonomous)
  i<-sample(nrow(s),1); G<-BA1[i]; Gm<-Gmax[i]; k<-f$par[3]; Ga<-G; for(j in 1:10) Ga<-Ga+(Gm-Ga)*(1-exp(-k*1))
  G10<-G+(Gm-G)*(1-exp(-k*10)); cat(sprintf("    path-invariance |10x1 - 1x10|=%.2e\n",abs(Ga-G10)))
}, error=function(e) cat("(C) basal area FAILED:", conditionMessage(e), "\n"))
cat("\nDONE_STAND_STATE_MODELS\n")
