#!/bin/bash
#SBATCH --job-name=difftf_dnase
#SBATCH --account=gtw109
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=48:00:00
#SBATCH --output=__PROJECT_DIR__/logs/difftf_dnase_%j.out
#SBATCH --error=__PROJECT_DIR__/logs/difftf_dnase_%j.err
#SBATCH --export=ALL

set -euo pipefail

source __PROJECT_DIR__/env.sh

DIFFTF="$PROJ/pipelines/diffTF"
ENV_DIR="__MINIFORGE_DIR__/envs/difftf_tier1"
CONFIG="$PROJ/configs/diffTF/tier1_dnase.json"
CLUSTER_CONFIG="$PROJ/configs/diffTF/expanse_cluster.json"
WORKDIR="$SCRATCH_PROJ/work/diffTF_tier1_dnase"
CLUSTER_LOGS="$PROJ/logs/diffTF_cluster"
SUBMIT_WRAPPER="$PROJ/scripts/sbatch_retry_difftf.sh"

export PATH="$ENV_DIR/bin:$PATH"

mkdir -p "$WORKDIR" "$CLUSTER_LOGS"
cd "$WORKDIR"

echo "diffTF full run started: $(date)"
echo "Driver job: $SLURM_JOB_ID"
echo "Driver node: $(hostname)"
echo "Snakemake: $(snakemake --version)"
echo "Config: $CONFIG"
echo "Work directory: $WORKDIR"

snakemake \
  --snakefile "$DIFFTF/src/Snakefile" \
  --configfile "$CONFIG" \
  --cluster-config "$CLUSTER_CONFIG" \
  --cluster "$SUBMIT_WRAPPER --parsable --account=gtw109 --partition=shared --nodes=1 --ntasks=1 --cpus-per-task={threads} --mem={cluster.mem} --time={cluster.time} --output=$CLUSTER_LOGS/%x_%j.out --error=$CLUSTER_LOGS/%x_%j.err --export=ALL" \
  --jobs 40 \
  --local-cores 1 \
  --max-jobs-per-second 0.15 \
  --max-status-checks-per-second 1 \
  --latency-wait 120 \
  --rerun-incomplete \
  --printshellcmds \
  --reason

echo "diffTF FULL RUN COMPLETED SUCCESSFULLY: $(date)"
