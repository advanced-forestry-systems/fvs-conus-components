#!/bin/bash
#SBATCH --job-name=htdbh_chapman_prod
#SBATCH --time=24:00:00
#SBATCH --mem=128G
#SBATCH --cpus-per-task=8
#SBATCH --account=PUOM0008
#SBATCH --output=/fs/scratch/PUOM0008/crsfaaron/fvs-conus/logs/htdbh_chapman_prod_%j.out
#SBATCH --error=/fs/scratch/PUOM0008/crsfaaron/fvs-conus/logs/htdbh_chapman_prod_%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=aaron.weiskittel@maine.edu

set -uo pipefail
module load gcc/12.3.0 R/4.4.0
cd /users/PUOM0008/crsfaaron/fvs-conus
mkdir -p /fs/scratch/PUOM0008/crsfaaron/fvs-conus/logs

echo "######## SPECIES-FREE Chapman PRODUCTION (100k, 4x1000) ########"
Rscript --vanilla calibration/R/36_fit_htdbh_chapman.R \
  --stan_file=calibration/stan/ht_dbh_chapman_speciesfree.stan \
  --traits=calibration/traits/species_traits_v2.rds \
  --outdir=/fs/scratch/PUOM0008/crsfaaron/fvs-conus/output/conus/ht_dbh/chapman_sf_100k \
  --outname=htdbh_chapman_sf_100k_${SLURM_JOB_ID} \
  --subsample=100000

echo "######## SPECIES-SPECIFIC Chapman PRODUCTION (100k, 4x1000) ########"
Rscript --vanilla calibration/R/36_fit_htdbh_chapman.R \
  --stan_file=calibration/stan/ht_dbh_chapman.stan \
  --traits=calibration/traits/species_traits_v2.rds \
  --outdir=/fs/scratch/PUOM0008/crsfaaron/fvs-conus/output/conus/ht_dbh/chapman_ss_100k \
  --outname=htdbh_chapman_ss_100k_${SLURM_JOB_ID} \
  --subsample=100000

# mirror the small validation artifacts back to home for review
for m in sf ss; do
  H=/users/PUOM0008/crsfaaron/fvs-conus/output/conus/ht_dbh/chapman_${m}_100k
  S=/fs/scratch/PUOM0008/crsfaaron/fvs-conus/output/conus/ht_dbh/chapman_${m}_100k
  mkdir -p "$H"
  cp -v $S/*_holdout_*.csv $S/*_summary.csv $S/*_curve_grid.csv $S/*_meta.rds "$H/" 2>/dev/null
done
echo "######## DONE ########"
