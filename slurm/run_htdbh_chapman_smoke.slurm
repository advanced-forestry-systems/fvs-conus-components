#!/bin/bash
#SBATCH --job-name=htdbh_chapman_smoke
#SBATCH --time=02:00:00
#SBATCH --mem=48G
#SBATCH --cpus-per-task=4
#SBATCH --account=PUOM0008
#SBATCH --output=/fs/scratch/PUOM0008/crsfaaron/fvs-conus/logs/htdbh_chapman_smoke_%j.out
#SBATCH --error=/fs/scratch/PUOM0008/crsfaaron/fvs-conus/logs/htdbh_chapman_smoke_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=aaron.weiskittel@maine.edu

set -uo pipefail
module load gcc/12.3.0 R/4.4.0
cd /users/PUOM0008/crsfaaron/fvs-conus
mkdir -p /fs/scratch/PUOM0008/crsfaaron/fvs-conus/logs

echo "######## SPECIES-FREE Chapman smoke ########"
Rscript --vanilla calibration/R/36_fit_htdbh_chapman.R \
  --stan_file=calibration/stan/ht_dbh_chapman_speciesfree.stan \
  --traits=calibration/traits/species_traits_v2.rds \
  --outdir=calibration/output/conus/ht_dbh/chapman_sf_smoke \
  --outname=htdbh_chapman_sf_smoke \
  --subsample=30000 --smoke

echo "######## SPECIES-SPECIFIC Chapman smoke ########"
Rscript --vanilla calibration/R/36_fit_htdbh_chapman.R \
  --stan_file=calibration/stan/ht_dbh_chapman.stan \
  --traits=calibration/traits/species_traits_v2.rds \
  --outdir=calibration/output/conus/ht_dbh/chapman_ss_smoke \
  --outname=htdbh_chapman_ss_smoke \
  --subsample=30000 --smoke

echo "######## DONE ########"
