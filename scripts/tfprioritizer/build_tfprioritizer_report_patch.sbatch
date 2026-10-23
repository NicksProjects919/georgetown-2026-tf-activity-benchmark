#!/bin/bash
#SBATCH --job-name=tfprio_patch
#SBATCH --account=gtw109
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=00:15:00
#SBATCH --output=__PROJECT_DIR__/logs/tfprio_patch_%j.out
#SBATCH --error=__PROJECT_DIR__/logs/tfprio_patch_%j.err
#SBATCH --export=ALL

set -euo pipefail

source __PROJECT_DIR__/env.sh
module load singularitypro/4.1.2

IMAGE="$SCRATCH_PROJ/containers/TF-Prioritizer/tf-prioritizer_master.sif"
PATCH_DIR="$PROJ/patches/TF-Prioritizer/biomart_https_report_null"
BASE_JAR="$PROJ/patches/TF-Prioritizer/biomart_https/TF-Prioritizer-biomart-https.jar"
PATCH_JAR="$PATCH_DIR/TF-Prioritizer-biomart-https-report-null.jar"
BUILD_DIR="$PATCH_DIR/classes_${SLURM_JOB_ID}"

test -s "$PATCH_DIR/ReportPreprocessing.java"
test -s "$BASE_JAR"
test ! -e "$PATCH_JAR"
test ! -e "$BUILD_DIR"

mkdir -p "$BUILD_DIR"

singularity exec --cleanenv \
  --bind "$PROJ:$PROJ" \
  "$IMAGE" \
  /bin/bash --noprofile --norc -c '
    set -euo pipefail

    PATCH_DIR="$1"
    BASE_JAR="$2"
    PATCH_JAR="$3"
    BUILD_DIR="$4"

    javac \
      -J-XX:ActiveProcessorCount=1 \
      -J-Xms64m \
      -J-Xmx2g \
      --release 17 \
      -cp "$BASE_JAR" \
      -d "$BUILD_DIR" \
      "$PATCH_DIR/ReportPreprocessing.java"

    cp "$BASE_JAR" "$PATCH_JAR"

    cd "$BUILD_DIR"

    jar uf "$PATCH_JAR" \
      org/exbio/tfprio/steps/report/ReportPreprocessing*.class
  ' _ "$PATCH_DIR" "$BASE_JAR" "$PATCH_JAR" "$BUILD_DIR"

echo "Created combined JAR:"
ls -lh "$PATCH_JAR"

echo
echo "Inserted report classes:"
jar tf "$PATCH_JAR" |
grep 'org/exbio/tfprio/steps/report/ReportPreprocessing'
