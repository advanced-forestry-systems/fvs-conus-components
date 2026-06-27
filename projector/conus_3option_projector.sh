#!/bin/bash
# conus_3option_projector.sh
# Single entry point for the three user-selectable CONUS equation sets, dispatching
# to the two validated R projectors. Gives the user one command with a 3-way switch:
#
#   --equations=greg        Greg Johnson's equations (his DG/HG + cch-gompit mortality;
#                           emergent density, no Garcia stand-level constraint)
#   --equations=conus_dep   our species-DEPENDENT (b2) equations + the Garcia stand-level
#                           layer (self-thinning + BA carrying capacity + SDImax_brms)
#   --equations=conus_free  our species-FREE (b1) equations + the SAME Garcia stand-level layer
#
# All other flags (--variant, --nstands, --horizon, --cyclelen, --outdir, ...) pass through
# to the underlying projector. The species-dependent and species-free options share the
# stand-level constraint by construction (they are two modes of conus_eq_projector_v4.R).
#
# Usage:
#   bash conus_3option_projector.sh --equations=conus_dep --variant=NE --nstands=100 --outdir=...
set -uo pipefail
PROJ=/fs/scratch/PUOM0008/crsfaaron/fvs_stress/conus_eq_proj

EQ=""; PASS=()
for a in "$@"; do
  case "$a" in
    --equations=*) EQ="${a#--equations=}";;
    *) PASS+=("$a");;
  esac
done

case "$EQ" in
  greg)
    echo "[3option] Greg Johnson equations -> conus_eq_projector_greg.R"
    exec Rscript --vanilla "$PROJ/conus_eq_projector_greg.R" "${PASS[@]}"
    ;;
  conus_dep|dependent|b2)
    echo "[3option] our species-DEPENDENT (b2) + Garcia stand-level -> conus_eq_projector_v4.R --mode=dependent"
    exec Rscript --vanilla "$PROJ/conus_eq_projector_v4.R" --mode=dependent "${PASS[@]}"
    ;;
  conus_free|free|b1)
    echo "[3option] our species-FREE (b1) + Garcia stand-level -> conus_eq_projector_v4.R --mode=free"
    exec Rscript --vanilla "$PROJ/conus_eq_projector_v4.R" --mode=free "${PASS[@]}"
    ;;
  *)
    echo "ERROR: --equations must be one of: greg | conus_dep | conus_free (got '$EQ')" >&2
    exit 2
    ;;
esac
