#!/bin/bash
#SBATCH --job-name=tfact_dnase
#SBATCH --partition=shared
#SBATCH --account=gtw109
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=48:00:00
#SBATCH --output=__PROJECT_DIR__/logs/tfact_dnase_driver_%j.out
#SBATCH --export=ALL

set -euo pipefail

source ~/TF_Benchmark/env.sh
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate tfbench
cd "$SCRATCH_PROJ"

export NXF_ANSI_LOG=false

OUTDIR="$SCRATCH_PROJ/results/tfactivity/tier1_dnase"
mkdir -p "$OUTDIR/pipeline_info"

nextflow run "$PROJ/pipelines/tfactivity" \
    -profile singularity \
    -params-file "$PROJ/configs/tfactivity/params_tier1_dnase.yaml" \
    -c "$PROJ/configs/tfactivity/expanse_slurm.config" \
    -work-dir "$SCRATCH_PROJ/work/tfactivity_tier1_dnase" -resume
