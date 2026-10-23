#!/bin/bash
#SBATCH --job-name=tfprio_resume
#SBATCH --account=gtw109
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=12:00:00
#SBATCH --output=__PROJECT_DIR__/logs/tfprio_resume_%j.out
#SBATCH --error=__PROJECT_DIR__/logs/tfprio_resume_%j.err
#SBATCH --export=ALL

set -euo pipefail

source __PROJECT_DIR__/env.sh
module load singularitypro/4.1.2

IMAGE="$SCRATCH_PROJ/containers/TF-Prioritizer/tf-prioritizer_master.sif"
PATCH_JAR="$PROJ/patches/TF-Prioritizer/biomart_https_report_null/TF-Prioritizer-biomart-https-report-fixes.jar"
RGT_RW="$SCRATCH_PROJ/dependencies/TF-Prioritizer/rgtdata"
CONFIG="$PROJ/configs/TF-Prioritizer/tier1_dnase.json"
OUTDIR="$SCRATCH_PROJ/results/TF-Prioritizer/tier1_dnase"
RUNTIME_CACHE="$SCRATCH_PROJ/dependencies/TF-Prioritizer/runtime_cache"

for FILE in "$IMAGE" "$PATCH_JAR" "$CONFIG"; do
    test -s "$FILE" || {
        echo "STOP: missing or empty file: $FILE"
        exit 1
    }
done

test -d "$RGT_RW" || {
    echo "STOP: missing RGT directory: $RGT_RW"
    exit 1
}

test -d "$OUTDIR/output" || {
    echo "STOP: existing TF-Prioritizer output was not found: $OUTDIR/output"
    exit 1
}

mkdir -p \
    "$RUNTIME_CACHE/matplotlib" \
    "$RUNTIME_CACHE/igv_cache" \
    "$RUNTIME_CACHE/npm"

echo "Resume started: $(date)"
echo "Node: $(hostname)"
echo "CPUs: $SLURM_CPUS_PER_TASK"
echo "Existing output: $OUTDIR"
echo "Combined patched JAR: $PATCH_JAR"
sha256sum "$PATCH_JAR"

RUN_LOG="$PROJ/logs/tfprio_resume_${SLURM_JOB_ID}.internal.log"

singularity exec --cleanenv \
    --env RGTDATA="$RGT_RW" \
    --env MPLCONFIGDIR="$RUNTIME_CACHE/matplotlib" \
    --env IGV_CACHE="$RUNTIME_CACHE/igv_cache" \
    --env NPM_CONFIG_CACHE="$RUNTIME_CACHE/npm" \
    --bind "$PROJ:$PROJ" \
    --bind "$SCRATCH_PROJ:$SCRATCH_PROJ" \
    "$IMAGE" \
    java -jar "$PATCH_JAR" \
      -c "$CONFIG" \
      -o "$OUTDIR" \
      -t "$SLURM_CPUS_PER_TASK" 2>&1 | tee "$RUN_LOG"

if grep -qE 'Execution failed|ErrorDuringCreation' "$RUN_LOG"; then
    echo "STOP: TF-Prioritizer reported an internal workflow failure"
    exit 1
fi

echo "Resume finished successfully: $(date)"
