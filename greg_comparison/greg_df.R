suppressPackageStartupMessages(library(data.table))
d<-as.data.table(readRDS("~/fvs_remodeling/rds/df_dg_res.RDS"))
for(c in c("startDIA","endDIA","dg_hat","n")) d[[c]]<-as.numeric(d[[c]])
d<-d[is.finite(startDIA)&is.finite(endDIA)&is.finite(dg_hat)&is.finite(n)&n>=1]
d[, inc_obs:=(endDIA-startDIA)/n*2.54]; d[, inc_pred:=(dg_hat-startDIA)/n*2.54]
d<-d[is.finite(inc_obs)&is.finite(inc_pred)&inc_obs> -0.5&inc_obs<5]
rmse<-sqrt(mean((d$inc_obs-d$inc_pred)^2)); bias<-mean(d$inc_pred-d$inc_obs)
r2<-1-sum((d$inc_obs-d$inc_pred)^2)/sum((d$inc_obs-mean(d$inc_obs))^2)
cat(sprintf("GREG Douglas-fir DG (his data+pred): n=%d  meanObs=%.3f cm/yr  RMSE=%.3f  bias=%+.3f  R2=%.3f\n", nrow(d), mean(d$inc_obs), rmse, bias, r2))
