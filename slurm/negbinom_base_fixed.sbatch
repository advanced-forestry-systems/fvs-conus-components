#!/bin/bash
#SBATCH -A PUOM0008
#SBATCH -J ingrowth_negbinom_base
#SBATCH -t 24:00:00
#SBATCH --mem=96G
#SBATCH --cpus-per-task=4
#SBATCH -o /fs/scratch/PUOM0008/crsfaaron/fvs-conus/logs/negbinom_base_%j.out
#SBATCH -e /fs/scratch/PUOM0008/crsfaaron/fvs-conus/logs/negbinom_base_%j.err
set -uo pipefail
module load gcc/12.3.0 R/4.4.0
cd /users/PUOM0008/crsfaaron/fvs-conus
OUT=/fs/scratch/PUOM0008/crsfaaron/fvs-conus/output/conus/ingrowth/negbinom_base; mkdir -p $OUT
Rscript --vanilla R/35_fit_ingrowth_negbinom_v4.R \
  --stan_file=calibration/stan/ingrowth_negbinom_v2.stan \
  --traits=calibration/traits/species_traits_v2.rds \
  --outdir=$OUT --outname=ingrowth_negbinom_base_${SLURM_JOB_ID}
