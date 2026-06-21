suppressPackageStartupMessages({library(terra); library(data.table); library(foreign)})
base <- "/fs/scratch/PUOM0008/crsfaaron/TREEMAP_restore"

cat("=== Loading TM2016 raster ===\n")
r <- rast(file.path(base,"TM2016/TreeMap2016.tif"))
cat("Band:", names(r)[1], "factor:", is.factor(r), "\n")
# Apply fix
if (is.factor(r)) {
  levels(r) <- NULL
  names(r) <- "tm_id"
  cat("Categorical levels stripped.\n")
}

cat("\n=== Crop to small test extent (one Idaho-ish window, ~50km square) ===\n")
e <- ext(-1700000, -1650000, 2700000, 2750000)
r_small <- crop(r, e)
cat("Small raster cells:", ncell(r_small), "\n")

cat("\n=== Load lookup table ===\n")
tt <- as.data.table(read.dbf(file.path(base,"TM2016/TreeMap2016.tif.vat.dbf"), as.is=TRUE))
cat("Table rows:", nrow(tt), "\n")

# Reclassify TOPHT (STANDHT)
lut <- tt[, .(from=Value, to=STANDHT)]
lut <- lut[complete.cases(lut)]
lut <- unique(lut)
lut$from2 <- lut$from
rcl_mat <- as.matrix(lut[, .(from, from2, to)])

cat("\n=== Reclassify to STANDHT ===\n")
topht_r <- classify(r_small, rcl_mat, right=NA)
rng <- global(topht_r, c("min","max"), na.rm=TRUE)
cat("STANDHT (TOPHT) range:", rng[1,1], "to", rng[1,2], "ft\n")
cat("Non-NA cells:", global(topht_r, "notNA")[1,1], "of", ncell(topht_r), "\n")

# Sample histogram
samp <- spatSample(topht_r, 1000, "random", na.rm=TRUE)
cat("Sample mean:", mean(samp[[1]], na.rm=TRUE), "median:", median(samp[[1]], na.rm=TRUE), "\n")
cat("Quartiles:", quantile(samp[[1]], c(.25, .5, .75), na.rm=TRUE), "\n")
