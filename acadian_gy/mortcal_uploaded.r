# =====================================================================
# AcadianGY_12.3.5_mortcal.r
# Calibrated FVS-ACD variant: canonical AcadianGY v12.3.5 PLUS an opt-in
# size-dependent mortality correction (#126). On 200 Maine FIA ACD plots the
# correction roughly halves the basal-area over-projection (+15.4% -> +8.6%) and
# lifts R^2 (0.42 -> 0.48). It is REVERSIBLE: with ops$MORTCAL not TRUE this is
# byte-identical in behaviour to the canonical model.
#
# Mechanism (see SESSION_HANDOFF mortality-refit section): AcadianGY allocates a
# stand-level mortality total whose per-tree stem removal is ~size-neutral, so
# its exposed levers cannot impose the observed size-by-class survival. This
# applies that survival as a post-step EXPF multiplier each annual cycle:
#   EXPF <- EXPF * ratio(DBH_class)^(1/interval)
# where ratio = observed/AcadianGY 5-yr survival by DBH class (FIA v10 diagnostic).
# Calibrate further by editing .mortcal_surv_ratio. NOTE: the residual +8.6% is a
# diameter-growth / ingrowth composition issue, not mortality (task #127).
# =====================================================================

source("/users/PUOM0008/crsfaaron/seven_islands/AcadianGY_12.3.5.r")

# observed/AcadianGY 5-yr survival ratio by initial DBH class (inches), FIA v10
.mortcal_surv_ratio <- function(dbh_in) {
  ifelse(dbh_in < 5,  0.914,
  ifelse(dbh_in < 10, 0.973,
  ifelse(dbh_in < 15, 0.941,
  ifelse(dbh_in < 20, 0.899, 0.846))))
}

# Drop-in replacement for AcadianGYOneStand with the opt-in correction.
# ops$MORTCAL = TRUE  -> apply the size-dependent mortality correction
# ops$MORTCAL_INTERVAL -> remeasurement interval used to annualise (default 5)
AcadianGYOneStandMortCal <- function(trees, stand, ops, ...) {
  out <- AcadianGYOneStand(trees, stand = stand, ops = ops, ...)
  if (isTRUE(ops$MORTCAL) && !is.null(out) && nrow(out) > 0) {
    iv <- if (!is.null(ops$MORTCAL_INTERVAL)) ops$MORTCAL_INTERVAL else 5
    out$EXPF <- out$EXPF * .mortcal_surv_ratio(out$DBH / 2.54)^(1 / iv)
  }
  out
}
