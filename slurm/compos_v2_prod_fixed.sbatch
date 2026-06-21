#!/bin/bash
#SBATCH -A PUOM0008
#SBATCH -J compos_v2_prod
#SBATCH -t 48:00:00
#SBATCH --mem=192G
#SBATCH --cpus-per-task=4
#SBATCH -o /fs/scratch/PUOM0008/crsfaaron/fvs-conus/logs/compos_v2_prod_%j.out
#SBATCH -e /fs/scratch/PUOM0008/crsfaaron/fvs-conus/logs/compos_v2_prod_%j.err
#SBATCH --mail-type=END,FAIL --mail-user=aaron.weiskittel@maine.edu
set -uo pipefail
module load gcc/12.3.0 R/4.4.0
cd /users/PUOM0008/crsfaaron/fvs-conus
OUT=/fs/scratch/PUOM0008/crsfaaron/fvs-conus/output/conus/ingrowth/compos_v2_prod; mkdir -p $OUT
Rscript --vanilla R/36_fit_ingrowth_species_composition.R   --stan_file=calibration/stan/ingrowth_species_composition_v2.stan   --recruit_data=calibration/data/ingrowth_per_recruit.rds   --traits=calibration/traits/species_traits_v2.rds   --outdir=$OUT --outname=compos_v2_prod   --top_n_sp=40 --subsample=20000 --max_treedepth=12 --adapt_delta=0.95   --iter_warmup=500 --iter_sampling=500 --chains=4
