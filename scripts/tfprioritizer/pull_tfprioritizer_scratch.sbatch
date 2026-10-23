#!/bin/bash
#SBATCH --job-name=pull_tfprio
#SBATCH --account=gtw109
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=04:00:00
#SBATCH --output=__PROJECT_DIR__/logs/pull_tfprio_%j.out
#SBATCH --error=__PROJECT_DIR__/logs/pull_tfprio_%j.err
#SBATCH --export=ALL

set -euo pipefail

source __PROJECT_DIR__/env.sh
module load singularitypro/4.1.2

CONTAINER_DIR="$SCRATCH_PROJ/containers/TF-Prioritizer"
CACHE_DIR="$SCRATCH_PROJ/.singularity/cache"
TEMP_DIR="$SCRATCH_PROJ/.singularity/tmp"

mkdir -p "$CONTAINER_DIR" "$CACHE_DIR" "$TEMP_DIR"

export SINGULARITY_CACHEDIR="$CACHE_DIR"
export SINGULARITY_TMPDIR="$TEMP_DIR"
export TMPDIR="$TEMP_DIR"

singularity pull \
  "$CONTAINER_DIR/tf-prioritizer_master.sif" \
  docker://nicotru/tf-prioritizer:master
