#!/bin/bash
#SBATCH --job-name=difftf_dryrun
#SBATCH --account=gtw109
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=01:00:00
#SBATCH --output=__PROJECT_DIR__/logs/difftf_dryrun_%j.out
#SBATCH --error=__PROJECT_DIR__/logs/difftf_dryrun_%j.err
#SBATCH --export=ALL

set -euo pipefail

source __PROJECT_DIR__/env.sh

DIFFTF="$PROJ/pipelines/diffTF"
ENV_DIR="__MINIFORGE_DIR__/envs/difftf"
CONFIG="$PROJ/configs/diffTF/tier1_dnase.json"
WORKDIR="$SCRATCH_PROJ/work/diffTF_tier1_dnase"

export PATH="$ENV_DIR/bin:$PATH"

mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "Dry run started: $(date)"
echo "Node: $(hostname)"
echo "Snakemake: $(snakemake --version)"

snakemake \
  --snakefile "$DIFFTF/src/Snakefile" \
  --configfile "$CONFIG" \
  --cores "$SLURM_CPUS_PER_TASK" \
  --dry-run \
  --quiet

echo "DRY RUN COMPLETED SUCCESSFULLY"
