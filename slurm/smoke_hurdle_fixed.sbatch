#!/bin/bash
#SBATCH -A PUOM0008
#SBATCH -J ingrowth_hurdle_smoke
#SBATCH -t 00:40:00
#SBATCH -N 1 --cpus-per-task=4
#SBATCH --mem=48G
#SBATCH -o /fs/scratch/PUOM0008/crsfaaron/fvs-conus/logs/hurdle_smoke_%j.out
module load gcc/12.3.0 R/4.4.0
cd /users/PUOM0008/crsfaaron/fvs-conus
Rscript --vanilla R/35b_fit_ingrowth_hurdle.R   --stan_file=calibration/stan/ingrowth_hurdle_v1.stan   --traits=calibration/traits/species_traits_v2.rds   --outdir=/fs/scratch/PUOM0008/crsfaaron/fvs-conus/output/conus/ingrowth/hurdle_smoke   --outname=hurdle_smoke_${SLURM_JOB_ID} --smoke
