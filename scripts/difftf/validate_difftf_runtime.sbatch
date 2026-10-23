#!/bin/bash
#SBATCH --job-name=difftf_check
#SBATCH --account=gtw109
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --time=01:00:00
#SBATCH --output=__PROJECT_DIR__/logs/difftf_check_%j.out
#SBATCH --error=__PROJECT_DIR__/logs/difftf_check_%j.err
#SBATCH --export=ALL

set -euo pipefail

source __PROJECT_DIR__/env.sh

DIFFTF="$PROJ/pipelines/diffTF"
ENV_DIR="__MINIFORGE_DIR__/envs/difftf_tier1"
CONFIG="$PROJ/configs/diffTF/tier1_dnase.json"
WORKDIR="$SCRATCH_PROJ/work/diffTF_tier1_dnase"

export PATH="$ENV_DIR/bin:$PATH"

mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "Runtime validation started: $(date)"
echo "Node: $(hostname)"

snakemake \
  --snakefile "$DIFFTF/src/Snakefile" \
  --configfile "$CONFIG" \
  --cores 1 \
  --printshellcmds \
  --reason \
  checkParameterValidity

echo "RUNTIME VALIDATION COMPLETED SUCCESSFULLY"
