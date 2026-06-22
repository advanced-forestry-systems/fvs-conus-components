#!/usr/bin/env Rscript
# =============================================================================
# 62m_modifier_to_variant_json.R   (v2, 2026-06-05)
#
# Layer-2 companion to 62c (which lands the base species-free equations). Adds a
# `categories_conus_sf_modifier.{component}` block to each variant config
# carrying the chosen disturbance/treatment modifier form for that component.
#
# Per-component form is fixed by the verified decision table (paired LOO):
#   trait-mediated: hcb (3.8 SE), cr (borderline 2.0 SE)
#   common:         dg, hg, ingrowth, mortality
#
# SCHEMA (verified against the production modifier summaries 2026-06-05):
#   common  : one file, variables alpha_0 + alpha_{plant,fire,insect,disease,
#             wind,harvest,cutting,siteprep}.
#   traitmed: TWO files. The *global* summary holds alpha_0 + the same eight
#             alpha_{type}. The *gamma* summary holds gamma_alpha_{type}[1..P]
#             but ONLY for the disturbance types the fit made trait-mediated
#             (e.g. hcb: plant, insect, harvest, cutting). The remaining types
#             stay species-independent (alpha only). P_trait is inferred from
#             the gamma file. The engine forms, per tree:
#               mult = exp(alpha_0 + alpha[type]
#                          + (type has gamma ? W_species . gamma_alpha[type] : 0))
#             W standardized exactly as in the base bundle's gamma.csv
#             (scale_mean/scale_sd columns) -> pass --base_gamma to copy that
#             standardization into the block for the engine.
#
# SAFETY: defaults to --dry_run=TRUE -> writes {variant}.sf_preview.json. The
# production write (--dry_run=FALSE) backs up to {variant}.json.pre_mod_<ts>.
# Reads JSON via readLines wrapper (62c's fromJSON-path fix).
#
# Usage (note: ALL args use the =form):
#   common:
#     Rscript 62m_modifier_to_variant_json.R --component=dg --form=common \
#       --modifier_summary=output/conus/dg/modifier_v8_prod/dg_kuehne_v8_modifier_lambda10_summary.csv \
#       --config_dir=/.../fvs-modern/config/calibrated --variant=ne --dry_run=TRUE
#   traitmed:
#     Rscript 62m_modifier_to_variant_json.R --component=hcb --form=traitmed \
#       --modifier_summary=.../hcb_speciesfree_traitmed_lambda10_global_summary.csv \
#       --modifier_gamma=.../hcb_speciesfree_traitmed_lambda10_gamma_summary.csv \
#       --base_gamma=output/conus/sf_integration/hcb_v2split_sf_gamma.csv \
#       --config_dir=/.../fvs-modern/config/calibrated --variant=ne --dry_run=TRUE
# =============================================================================
suppressPackageStartupMessages({ library(data.table); library(jsonlite) })
`%||%` <- function(a,b) if(is.null(a)) b else a

args <- commandArgs(trailingOnly = TRUE)
ga <- function(n, d=NULL){ m<-grep(paste0("^--",n,"="),args,value=TRUE)
  if(length(m)) sub(paste0("^--",n,"="),"",m[1]) else d }

COMP   <- ga("component")
FORM   <- ga("form","common")
MSUM   <- ga("modifier_summary")
MGAMMA <- ga("modifier_gamma")                 # required for traitmed
BGAMMA <- ga("base_gamma")                     # base bundle gamma.csv (standardization)
CONFIG_DIR <- ga("config_dir","config/calibrated")
VARIANT <- ga("variant", NULL)
DRY <- toupper(ga("dry_run","TRUE")) %in% c("TRUE","T","1","YES")
stopifnot(!is.null(COMP), !is.null(MSUM), file.exists(MSUM))
if (FORM=="traitmed") stopifnot(!is.null(MGAMMA), file.exists(MGAMMA))

KEY <- c(dg="diameter_growth", hg="height_growth", htdbh="height_diameter",
         hcb="height_crown_base", mort="mortality", cr="crown_recession",
         ingrowth="ingrowth")[[COMP]]
DTYPES <- c("plant","fire","insect","disease","wind","harvest","cutting","siteprep")

rdcsv <- function(p){ x<-fread(p); setNames(as.list(x), names(x)); x }
s  <- fread(MSUM)
gm <- function(tab,v){ x<-tab[variable==v]; if(nrow(x)) as.numeric(x$mean[1]) else NA_real_ }

block <- list(component=COMP, form=FORM, disturbance_types=as.list(DTYPES))
block$alpha_0 <- gm(s,"alpha_0")
block$alpha   <- setNames(lapply(DTYPES, function(t) gm(s, paste0("alpha_",t))), DTYPES)

if (FORM == "traitmed") {
  g <- fread(MGAMMA)
  gvars <- unique(sub("\\[[0-9]+\\]$","", g$variable))
  tm_types <- sub("^gamma_alpha_","", grep("^gamma_alpha_", gvars, value=TRUE))
  tm_types <- intersect(DTYPES, tm_types)            # types that ARE trait-mediated
  P <- length(grep(paste0("^gamma_alpha_", tm_types[1], "\\["), g$variable))
  gmat <- setNames(lapply(tm_types, function(t)
            sapply(seq_len(P), function(i) gm(g, sprintf("gamma_alpha_%s[%d]", t, i)))), tm_types)
  block$trait_mediated_types <- as.list(tm_types)
  block$P_trait <- P
  block$trait_gamma_alpha <- gmat
  if (!is.null(BGAMMA) && file.exists(BGAMMA)) {
    bg <- fread(BGAMMA)
    if (all(c("scale_mean","scale_sd") %in% names(bg))) {
      block$trait_standardization <- list(
        trait = as.list(bg$variable %||% bg$trait %||% seq_len(nrow(bg))),
        scale_mean = as.list(bg$scale_mean), scale_sd = as.list(bg$scale_sd))
    }
  }
  block$note <- paste("engine multiplier = exp(alpha_0 + alpha[type] +",
    "(type in trait_mediated_types ? W_std . trait_gamma_alpha[type] : 0));",
    "W standardized as in base bundle gamma.csv")
} else {
  block$note <- "engine multiplier = exp(alpha_0 + alpha[type]); species-independent"
}

# --- variant loop ------------------------------------------------------------
vfiles <- if (!is.null(VARIANT)) file.path(CONFIG_DIR, paste0(VARIANT, ".json")) else
  grep("_draws\\.json$|\\.pre_|\\.sf_preview\\.json$",
       list.files(CONFIG_DIR, "\\.json$", full.names=TRUE), invert=TRUE, value=TRUE)

for (vf in vfiles) {
  prev <- sub("\\.json$",".sf_preview.json",vf)
  base <- if (DRY && file.exists(prev)) prev else vf
  d <- fromJSON(paste(readLines(base), collapse="\n"), simplifyVector = FALSE)
  if (is.null(d$categories_conus_sf_modifier)) d$categories_conus_sf_modifier <- list()
  d$categories_conus_sf_modifier[[KEY]] <- block
  out <- if (DRY) prev else {
    file.copy(vf, sub("\\.json$",paste0(".json.pre_mod_",format(Sys.time(),"%Y%m%d_%H%M%S")),vf)); vf }
  write_json(d, out, auto_unbox=TRUE, pretty=TRUE, digits=10, null="null")
  cat(sprintf("%s  %s  modifier.%s (%s)\n", ifelse(DRY,"preview","LANDED"),
              basename(out), KEY, FORM))
}
cat("Done.\n")
