# Verify John's specific plot/trees pattern (FIA growth calcs, 2026-05-26).
# Plot: 786779864290487; 7 TRE_CNs without PREV_TRE_CN.
# First 6 are >=30 in (annular macroplot, DIST>24); last is 5.0 in (subplot).
# Expected: 5 in tree in BEGIN/MIDPT/COMPONENT/ESTN but NOT THRESHOLD.
#           6 trees in COMPONENT only, with mostly null fields.
suppressPackageStartupMessages(library(data.table))
DD <- path.expand("~/FIA"); FD <- path.expand("~/fia_data")
pick <- function(n){for(d in c(DD,FD)){p<-file.path(d,n);if(file.exists(p))return(p)};NA_character_}

target_pltcn <- bit64::as.integer64("786779864290487")
target_trecn <- bit64::as.integer64(c(
  "1127638844290487","1127638843290487","1127638788290487",
  "1127638826290487","1127638789290487","1127638845290487",
  "1127638842290487"))

# TREE table for the plot
tree_f <- pick("OR_TREE.csv")
cat("OR_TREE:", tree_f, "\n")
have_cols <- names(fread(tree_f, nrows=0))
sel <- intersect(c("CN","PLT_CN","PREV_TRE_CN","STATECD","SUBP","TREE",
                   "DIA","DIST","AZIMUTH","TPA_UNADJ","STATUSCD","VOLCFGRS"), have_cols)
tr <- fread(tree_f, integer64="integer64", select=sel)
cat("TREE cols available:", paste(sel, collapse=", "), "\n")
if (!"DIST" %in% sel) tr[, DIST := NA_real_]
if (!"AZIMUTH" %in% sel) tr[, AZIMUTH := NA_real_]
plt <- tr[PLT_CN == target_pltcn]
cat("Trees on PLT_CN", as.character(target_pltcn), ":", nrow(plt), "  STATECD:",
    paste(unique(plt$STATECD), collapse=","), "\n\n")

cat("=== John's 7 TRE_CNs in OR_TREE ===\n")
m <- tr[CN %in% target_trecn,
        .(CN, PLT_CN, DIA, DIST, SUBP, PREV_TRE_CN_isNA = is.na(PREV_TRE_CN),
          STATUSCD, VOLCFGRS, TPA_UNADJ)]
print(m)

# Now check presence in each GRM table
check_in <- function(file_name, label){
  f <- pick(file_name); if(is.na(f)){cat(label,": file missing\n"); return(NULL)}
  hdr <- names(fread(f, nrows=0))
  key <- if("TRE_CN" %in% hdr) "TRE_CN" else NA
  if(is.na(key)){cat(label,": no TRE_CN col\n"); return(NULL)}
  d <- fread(f, integer64="integer64", select=key)
  hit <- target_trecn %in% d[[key]]
  cat(sprintf("%-25s present: %s\n", label, paste(hit, collapse=" ")))
  invisible(hit)
}
cat("\n=== TRE_CN presence in GRM tables (TRUE/FALSE for each of the 7 in order) ===\n")
check_in("OR_TREE_GRM_COMPONENT.csv", "OR_TREE_GRM_COMPONENT")
check_in("ENTIRE_TREE_GRM_BEGIN.csv", "ENTIRE_TREE_GRM_BEGIN")
check_in("OR_TREE_GRM_MIDPT.csv",     "OR_TREE_GRM_MIDPT")
check_in("ENTIRE_TREE_GRM_THRESHOLD.csv","ENTIRE_TREE_GRM_THRESHOLD")
check_in("ENTIRE_TREE_GRM_ESTN.csv",  "ENTIRE_TREE_GRM_ESTN")

# For the 6 >=30in trees: how many fields are non-null in COMPONENT?
comp_f <- pick("OR_TREE_GRM_COMPONENT.csv")
co <- fread(comp_f, integer64="integer64")
big6 <- target_trecn[1:6]; small1 <- target_trecn[7]
cat("\n=== Non-null field counts in COMPONENT for the 6 macroplot 'appearing' trees ===\n")
hit <- co[TRE_CN %in% big6]
cat("matched rows:", nrow(hit), "\n")
if(nrow(hit)>0){
  nn <- hit[, .(TRE_CN, n_nonnull = rowSums(!is.na(.SD))), .SDcols = setdiff(names(hit),"TRE_CN")]
  print(nn); cat("(total columns in COMPONENT:", ncol(co), ")\n")
}
cat("\n=== Same for the 5 in 'appearing' subplot tree ===\n")
hit1 <- co[TRE_CN %in% small1]
cat("matched rows:", nrow(hit1), "\n")
if(nrow(hit1)>0){
  cat("non-null cols:", sum(!is.na(hit1[1])), "/", ncol(co), "\n")
}

# STATEWIDE quantification: trees with DIA>=30 & DIST>24 & PREV_TRE_CN NA in OR
cat("\n=== Statewide OR pattern: DIA>=30 in annular macroplot, no PREV_TRE_CN ===\n")
# DIST may be unavailable in this extract; use DIA>=30 + no PREV_TRE_CN as proxy for "appearing macroplot"
has_dist <- !all(is.na(tr$DIST))
ann <- tr[!is.na(DIA) & DIA>=30 & is.na(PREV_TRE_CN) & STATUSCD==1 &
          (if (has_dist) (!is.na(DIST) & DIST>24) else TRUE)]
cat("(filter uses DIST>24:", has_dist, ")\n")
cat("count:", nrow(ann), "  sum VOLCFGRS:", round(sum(ann$VOLCFGRS, na.rm=TRUE),0), "\n")
cat("How many of these are in COMPONENT at all:",
    sum(ann$CN %in% co$TRE_CN), "\n")
# of those in COMPONENT, how many have a non-null GROWCFAL_FOREST
if ("GROWCFAL_FOREST" %in% names(co)) {
  sub <- co[TRE_CN %in% ann$CN]
  cat("of those in COMPONENT, GROWCFAL_FOREST nonNA:",
      sum(!is.na(sub$GROWCFAL_FOREST)), "/", nrow(sub), "\n")
}
