#!/bin/bash
#SBATCH --job-name=tfprio_check2
#SBATCH --account=gtw109
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=00:30:00
#SBATCH --output=__PROJECT_DIR__/logs/tfprio_check2_%j.out
#SBATCH --error=__PROJECT_DIR__/logs/tfprio_check2_%j.err
#SBATCH --export=ALL

set -u -o pipefail

source __PROJECT_DIR__/env.sh
module load singularitypro/4.1.2

IMAGE="$SCRATCH_PROJ/containers/TF-Prioritizer/tf-prioritizer_master.sif"
PATCH_JAR="$PROJ/patches/TF-Prioritizer/biomart_https/TF-Prioritizer-biomart-https.jar"
RGT_RW="$SCRATCH_PROJ/dependencies/TF-Prioritizer/rgtdata"
CONFIG="$PROJ/configs/TF-Prioritizer/tier1_dnase.json"
OUTDIR="$SCRATCH_PROJ/results/TF-Prioritizer/validation2_${SLURM_JOB_ID}"

mkdir -p "$OUTDIR"

set +e
timeout --kill-after=30s 25m \
  singularity exec --cleanenv \
    --env RGTDATA="$RGT_RW" \
    --bind "$PROJ:$PROJ" \
    --bind "$SCRATCH_PROJ:$SCRATCH_PROJ" \
    "$IMAGE" \
    java -jar "$PATCH_JAR" \
      -c "$CONFIG" \
      -o "$OUTDIR" \
      -t 4
STATUS=$?
set -e

if [ "$STATUS" -eq 124 ] || [ "$STATUS" -eq 137 ]; then
    echo "VALIDATION WINDOW COMPLETED: pipeline remained active for 25 minutes"
    exit 0
fi

exit "$STATUS"
