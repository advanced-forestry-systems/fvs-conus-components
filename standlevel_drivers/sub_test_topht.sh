#!/bin/bash
#SBATCH --job-name=topht_test
#SBATCH --time=00:15:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=2
#SBATCH --account=PUOM0008
#SBATCH --output=/users/PUOM0008/crsfaaron/Disturbance/logs/topht_test_%j.out
#SBATCH --error=/users/PUOM0008/crsfaaron/Disturbance/logs/topht_test_%j.err

module load gcc/12.3.0
module load gdal/3.7.3 geos/3.12.0 proj/9.2.1
module load R/4.4.0
Rscript ~/test_topht.R
