#!/bin/bash
#SBATCH -A PUOM0008
#SBATCH -J ingrowth_hurdle_mid
#SBATCH -t 24:00:00
#SBATCH --mem=96G
#SBATCH --cpus-per-task=4
#SBATCH -o /fs/scratch/PUOM0008/crsfaaron/fvs-conus/logs/hurdle_mid_%j.out
#SBATCH -e /fs/scratch/PUOM0008/crsfaaron/fvs-conus/logs/hurdle_mid_%j.err
#SBATCH --mail-type=END,FAIL --mail-user=aaron.weiskittel@maine.edu
set -uo pipefail
module load gcc/12.3.0 R/4.4.0
cd /users/PUOM0008/crsfaaron/fvs-conus
OUT=/fs/scratch/PUOM0008/crsfaaron/fvs-conus/output/conus/ingrowth/hurdle_mid; mkdir -p $OUT
Rscript --vanilla R/35b_fit_ingrowth_hurdle.R   --stan_file=calibration/stan/ingrowth_hurdle_v1.stan   --traits=calibration/traits/species_traits_v2.rds   --outdir=$OUT --outname=ingrowth_hurdle_mid_${SLURM_JOB_ID}   --max_treedepth=12 --adapt_delta=0.95 --iter_warmup=250 --iter_sampling=250 --chains=4
