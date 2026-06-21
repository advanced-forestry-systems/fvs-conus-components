suppressPackageStartupMessages(library(data.table))
est_dg <- function(n,dbh0,bal0,bal1,cr0,cr1,ht0,ht1,elev,emt,B0,B1,B2,B3,B4,B5,B6){
  dht<-(ht1-ht0)/n; dbal<-(bal1-bal0)/n; dcr<-(cr1-cr0)/n
  cht<-ht0; cdbh<-dbh0; cbal<-bal0; ccr<-cr0; mx<-max(n)
  for(i in 1:mx){
    dg<-exp(B0+B1*log((cdbh+1)^2/(ccr*cht+1)^B3)+B2*cbal^B4/log(cdbh+2.7)+B5*elev+B6*emt)
    cdbh<-cdbh+ifelse(i<=n,dg,0); cbal<-cbal+ifelse(i<=n,dbal,0); cht<-cht+ifelse(i<=n,dht,0); ccr<-ccr+ifelse(i<=n,dcr,0)
  }
  cdbh
}
P<-readRDS("~/fvs_remodeling/rds/dg_parms.RDS")
for(sp in c(131,316,202,12)){
  f<-readRDS(sprintf("~/fvs_remodeling/fits/%d_fit.RDS",sp)); d<-as.data.table(f$data)
  if(sp==131) cat("data cols:", paste(names(d),collapse=","), "\n\n")
  b<-P[P$spcd==sp,]
  # map columns (defensive)
  gv<-function(nm) if(nm %in% names(d)) d[[nm]] else NA
  pred<-est_dg(gv("n"),gv("dbh0"),gv("bal0"),gv("bal1"),gv("cr0"),gv("cr1"),gv("ht0"),gv("ht1"),gv("elev"),gv("emt"),
               b$B0,b$B1,b$B2,b$B3,b$B4,b$B5,b$B6)
  obs_end<-gv("dbh1"); n<-gv("n")
  inc_obs<-(obs_end-gv("dbh0"))/n; inc_pred<-(pred-gv("dbh0"))/n  # in/yr
  ok<-is.finite(inc_obs)&is.finite(inc_pred)
  io<-inc_obs[ok]*2.54; ip<-inc_pred[ok]*2.54  # cm/yr
  rmse<-sqrt(mean((io-ip)^2)); bias<-mean(ip-io); r2<-1-sum((io-ip)^2)/sum((io-mean(io))^2)
  cat(sprintf("Greg DG sp %d (%s): n=%d  meanObs=%.3f cm/yr  RMSE=%.3f  bias=%+.3f  R2=%.3f\n",
      sp, b$Common_Name, sum(ok), mean(io), rmse, bias, r2))
}
