suppressPackageStartupMessages({library(cmdstanr); library(data.table); library(posterior)})
F <- "/fs/scratch/PUOM0008/crsfaaron/fvs-conus/output/conus/ingrowth/compos_prod/ingrowth_compos_prod_11256847_fit.rds"
OUT <- "/fs/scratch/PUOM0008/crsfaaron/fvs-conus/output/conus/ingrowth/compos_prod"
cat("loading saved fit...\n"); fit <- readRDS(F)
sv <- fit$metadata()$stan_variables
cat("stan_variables:", paste(sv, collapse=", "), "\n")
want <- intersect(c("alpha_0","b","gamma_int","sigma_alpha"), sv)
cat("summarizing only:", paste(want, collapse=", "), "\n")
summ <- fit$summary(variables = want, "mean","median","sd",
                    ~quantile(.x, c(0.05,0.95), na.rm=TRUE), "rhat","ess_bulk","ess_tail")
names(summ)[names(summ) %in% c("5%","95%")] <- c("q5","q95")
fwrite(summ, file.path(OUT, "ingrowth_compos_prod_11256847_summary.csv"))
saveRDS(list(form="multinomial_v1", summary=summ, recovered=TRUE), file.path(OUT, "ingrowth_compos_prod_11256847_meta.rds"))
cat(sprintf("\nRECOVERED. n_param_rows=%d  max rhat=%.4f  min ess=%.0f\n",
            nrow(summ), max(summ$rhat, na.rm=TRUE), min(summ$ess_bulk, na.rm=TRUE)))
