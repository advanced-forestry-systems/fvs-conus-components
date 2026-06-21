#!/usr/bin/env Rscript
# build_sf_coeffs.R
# Arm 4 species-free coefficient extractor. Pulls posterior-mean coefficients and
# residual sigma for a species-free component fit from its summary.csv (no need to
# load the multi-GB fit object). Writes a coefficient bundle RDS the standalone
# projector consumes. Parameterized by component and fit basename so it works for
# DG (Kuehne), HG, and mortality once the canonical fit version is confirmed.
#
# Locked DG (Kuehne species-free, dg_kuehne2022_speciesfree.stan) linear predictor:
#   ln(dDBH_annual) = b0 + trait_effect[sp] + z_L1 + z_L2 + z_L3
#     + b1 ln(DBH) + b2 DBH + b3 ln((CR+0.2)/1.2)
#     + b4 ln(BAL_SW+0.01) + b5 BAL_HW + b6 ln(CSI) + b7 (BA*RD) + b8 (BAL*RD)
#   dDBH_annual ~ lognormal(eta, sigma / sqrt(YEARS))
#   PREDICTION CONVENTION (point) is a decision: median exp(eta) vs
#   mean exp(eta + sigma_eff^2/2). With sigma ~ 1.84 this is a ~5x lever; must be
#   confirmed against the DG benchmark before final numbers.
#
# CLI: --summary=PATH --meta=PATH --component=dg|hg|mort --out=PATH
suppressPackageStartupMessages(library(data.table))
`%||%` <- function(a,b) if (is.null(a) || length(a)==0) b else a
args <- commandArgs(trailingOnly=TRUE)
ga <- function(n,d=NULL){m=grep(paste0("^--",n,"="),args,value=TRUE);if(!length(m))return(d);sub(paste0("^--",n,"="),"",m[1])}
SUMMARY <- ga("summary"); META <- ga("meta"); COMP <- ga("component","dg"); OUT <- ga("out")
stopifnot(file.exists(SUMMARY))
S <- fread(SUMMARY); setnames(S, names(S)[1], "var")
gv <- function(p){ x <- S[var==p, mean]; if(length(x)) x[1] else NA_real_ }
meta <- if(!is.null(META) && file.exists(META)) readRDS(META) else NULL
sp_levels <- meta$prep_meta$sp %||% meta$sp_levels %||% NA

bundle <- list(component=COMP, summary_path=SUMMARY,
               b = setNames(sapply(0:8, function(i) gv(paste0("b",i))), paste0("b",0:8)),
               gamma = S[grepl("^gamma\\[",var), mean],
               trait_effect = S[grepl("^trait_effect\\[",var), mean],
               sigma = gv("sigma"),
               sigma_L1 = gv("sigma_L1"), sigma_L2 = gv("sigma_L2"), sigma_L3 = gv("sigma_L3"),
               sp_levels = sp_levels,
               cspi_shift = meta$prep_meta$cspi_shift %||% 1.0,
               note = "z_L1/L2/L3 per-ecoregion REs NOT in summary; extract from fit object or set 0 (population mean). Prediction convention (median vs mean) UNCONFIRMED.")
if(!is.null(OUT)) saveRDS(bundle, OUT)
cat("component:", COMP, "| b0..b8:", paste(round(bundle$b,4),collapse=", "),
    "\nsigma:", round(bundle$sigma,4), "| n trait_effect:", length(bundle$trait_effect),
    "| n species:", length(sp_levels), "\n")
if(!is.null(OUT)) cat("saved:", OUT, "\n")
