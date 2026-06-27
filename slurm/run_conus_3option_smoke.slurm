#!/bin/bash
#SBATCH --job-name=conus_3option_smoke
#SBATCH --account=PUOM0008
#SBATCH --time=02:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=4 --mem=24G
#SBATCH --output=/fs/scratch/PUOM0008/crsfaaron/fvs-conus/logs/conus_3option_smoke_%j.out
#SBATCH --error=/fs/scratch/PUOM0008/crsfaaron/fvs-conus/logs/conus_3option_smoke_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=aaron.weiskittel@maine.edu

set -uo pipefail
module load gcc/12.3.0 R/4.4.0 >/dev/null 2>&1
export FVS_PROJECT_ROOT=/users/PUOM0008/crsfaaron/fvs-modern
export NSBE_ROOT=/users/PUOM0008/crsfaaron/fvs-modern/data/NSBE
export FIA_DATA_DIR=/fs/scratch/PUOM0008/crsfaaron/FIA
cd /fs/scratch/PUOM0008/crsfaaron/fvs_stress
DISP=/users/PUOM0008/crsfaaron/fvs-conus/scripts/conus_3option_projector.sh
OUT=/fs/scratch/PUOM0008/crsfaaron/fvs_stress/out_3opt
mkdir -p "$OUT" /fs/scratch/PUOM0008/crsfaaron/fvs-conus/logs

VARIANT=${VARIANT:-NE}; NST=${NST:-100}; CL=${CL:-5}

for EQ in greg conus_dep conus_free; do
  echo "################## OPTION: $EQ ##################"
  bash "$DISP" --equations=$EQ --variant=$VARIANT --nstands=$NST --cyclelen=$CL \
    --outdir="$OUT/$EQ" 2>&1 | tail -20
  echo
done

echo "################## 3-OPTION SUMMARY (year 0/50/100 stand-mean) ##################"
Rscript --vanilla -e '
suppressPackageStartupMessages(library(data.table))
out <- "/fs/scratch/PUOM0008/crsfaaron/fvs_stress/out_3opt"
res <- rbindlist(lapply(c("greg","conus_dep","conus_free"), function(eq){
  f <- list.files(file.path(out,eq), pattern="_metrics.csv$", full.names=TRUE)
  if(!length(f)) return(NULL)
  d <- fread(f[1]); ycol <- intersect(c("PROJ_YEAR","py","YEAR","year"), names(d))[1]
  d <- d[get(ycol) %in% c(0,50,100)]
  bcol <- intersect(c("BA","BA_FT2AC","BA_M2HA"), names(d))[1]
  qcol <- intersect(c("QMD","QMD_IN","QMD_CM"), names(d))[1]
  tcol <- intersect(c("TPH","TPA"), names(d))[1]
  d[, .(equations=eq, year=get(ycol),
        BA=round(mean(get(bcol),na.rm=TRUE),1),
        QMD=round(mean(get(qcol),na.rm=TRUE),1),
        TPH=round(mean(get(tcol),na.rm=TRUE),0)), by=get(ycol)][, get:=NULL][]
}), fill=TRUE)
print(res)
fwrite(res, file.path(out,"three_option_summary.csv"))
' 2>&1 | tail -25
echo "################## DONE ##################"
