#!/bin/bash
#SBATCH --job-name=gompit_mod_smoke
#SBATCH --account=PUOM0008
#SBATCH --time=03:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=4 --mem=72G
#SBATCH --output=/fs/scratch/PUOM0008/crsfaaron/fvs-conus/logs/gompit_mod_smoke_%j.out
#SBATCH --error=/fs/scratch/PUOM0008/crsfaaron/fvs-conus/logs/gompit_mod_smoke_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=aaron.weiskittel@maine.edu
set -uo pipefail
module load gcc/12.3.0 R/4.4.0 >/dev/null 2>&1
cd /users/PUOM0008/crsfaaron/fvs-conus
mkdir -p /fs/scratch/PUOM0008/crsfaaron/fvs-conus/logs
Rscript --vanilla calibration/R/50g_fit_gompit_modifier.R --smoke 2>&1 | tail -40
echo DONE
