suppressPackageStartupMessages({ library(data.table) })
set.seed(1)
d <- as.data.table(readRDS("data/conus_remeasurement_pairs_metric_cond_v2.rds"))
d <- d[is.finite(CR1)&CR1>0.02&CR1<0.98 & is.finite(CR2)&CR2>0.02&CR2<0.98 &
       is.finite(YEARS)&YEARS>=1&YEARS<=20 & is.finite(DBH1)&is.finite(BA1)&is.finite(BAL_SW1)&is.finite(BAL_HW1)&is.finite(cspi)]
if(nrow(d)>200000) d <- d[sample(.N,200000)]
y <- qlogis(d$CR2); x1 <- qlogis(d$CR1); dbh<-d$DBH1; ba<-d$BA1; bal<-d$BAL_SW1+d$BAL_HW1; lcsi<-log(pmax(d$cspi,0.1)); Tn<-d$YEARS
r2<-function(o,p)1-sum((o-p)^2)/sum((o-mean(o))^2); n<-length(y)
cat("CR2 obs:", n, " mean interval:", round(mean(Tn),1), "yr\n\n")
# (A) current non-annualized: y = a0 + bc*x1 + b1*dbh + b3*ba + b4*bal + b6*lcsi
A<-lm(y ~ x1 + dbh + ba + bal + lcsi); pA<-fitted(A)
cat(sprintf("(A) non-annualized: R2=%.3f  AIC=%.0f  (no interval term)\n", r2(y,pA), AIC(A)))
# (B) annualized: y = E + (x1 - E)*exp(-k*T); E = a0+b1*dbh+b3*ba+b4*bal+b6*lcsi
sse<-function(p){E<-p[1]+p[2]*dbh+p[3]*ba+p[4]*bal+p[5]*lcsi; k<-p[6]; mu<-E+(x1-E)*exp(-k*Tn); sum((y-mu)^2)}
f<-nlminb(c(0,0,0,0,0,0.05),sse,lower=c(-5,-.1,-.1,-.1,-1,0.001),upper=c(5,.1,.1,.1,1,1))
E<-f$par[1]+f$par[2]*dbh+f$par[3]*ba+f$par[4]*bal+f$par[5]*lcsi; muB<-E+(x1-E)*exp(-f$par[6]*Tn)
aicB<-n*log(sum((y-muB)^2)/n)+2*7
cat(sprintf("(B) annualized:     R2=%.3f  AIC=%.0f  k=%.4f/yr (annual approach rate)\n", r2(y,muB), aicB, f$par[6]))
# path-invariance of B
i<-sample(n,1); E1<-E[i]; x<-x1[i]; xa<-x; for(j in 1:10) xa<-E1+(xa-E1)*exp(-f$par[6]*1); x10<-E1+(x-E1)*exp(-f$par[6]*10)
cat(sprintf("\npath-invariance (B): 10x1yr=%.4f 1x10yr=%.4f |diff|=%.1e\n", xa, x10, abs(xa-x10)))
cat("DONE_CR2_ANN\n")
