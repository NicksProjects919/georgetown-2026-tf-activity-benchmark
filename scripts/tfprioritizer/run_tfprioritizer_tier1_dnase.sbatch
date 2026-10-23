#!/bin/bash
#SBATCH --job-name=tfprio_dnase
#SBATCH --account=gtw109
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=48:00:00
#SBATCH --output=__PROJECT_DIR__/logs/tfprio_dnase_%j.out
#SBATCH --error=__PROJECT_DIR__/logs/tfprio_dnase_%j.err
#SBATCH --export=ALL

set -euo pipefail

source __PROJECT_DIR__/env.sh
module load singularitypro/4.1.2

IMAGE="$SCRATCH_PROJ/containers/TF-Prioritizer/tf-prioritizer_master.sif"
PATCH_JAR="$PROJ/patches/TF-Prioritizer/biomart_https/TF-Prioritizer-biomart-https.jar"
RGT_RW="$SCRATCH_PROJ/dependencies/TF-Prioritizer/rgtdata"
CONFIG="$PROJ/configs/TF-Prioritizer/tier1_dnase.json"
OUTDIR="$SCRATCH_PROJ/results/TF-Prioritizer/tier1_dnase"

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

if test -d "$OUTDIR" &&
   find "$OUTDIR" -mindepth 1 -maxdepth 1 -print -quit | grep -q .; then
    echo "STOP: output directory already contains files: $OUTDIR"
    exit 1
fi

mkdir -p "$OUTDIR"

echo "Started: $(date)"
echo "Node: $(hostname)"
echo "CPUs: $SLURM_CPUS_PER_TASK"
echo "Output: $OUTDIR"

singularity exec --cleanenv \
    --env RGTDATA="$RGT_RW" \
    --bind "$PROJ:$PROJ" \
    --bind "$SCRATCH_PROJ:$SCRATCH_PROJ" \
    "$IMAGE" \
    java -jar "$PATCH_JAR" \
      -c "$CONFIG" \
      -o "$OUTDIR" \
      -t "$SLURM_CPUS_PER_TASK"

echo "Finished successfully: $(date)"
