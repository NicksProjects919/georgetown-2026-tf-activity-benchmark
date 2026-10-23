#!/bin/bash
#SBATCH --job-name=difftf_tfbs_bed
#SBATCH --account=gtw109
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --output=__PROJECT_DIR__/logs/difftf_tfbs_bed_%j.out
#SBATCH --error=__PROJECT_DIR__/logs/difftf_tfbs_bed_%j.err
#SBATCH --export=ALL

set -euo pipefail

source __PROJECT_DIR__/env.sh

SOURCE="$SCRATCH_PROJ/references/diffTF/FIMO_HOCOMOCOv11"
TARGET="$SCRATCH_PROJ/references/diffTF/FIMO_HOCOMOCOv11_bed"
TEMP="$SCRATCH_PROJ/references/diffTF/.FIMO_HOCOMOCOv11_bed_${SLURM_JOB_ID}.tmp"

if [ -e "$TARGET" ]; then
    echo "STOP: final target already exists: $TARGET"
    exit 1
fi

if [ -e "$TEMP" ]; then
    echo "STOP: temporary target already exists: $TEMP"
    exit 1
fi

EXPECTED=$(
    find "$SOURCE" -maxdepth 1 -type f \
        -name '*_TFBS.bed.gz' | wc -l
)

if [ "$EXPECTED" -ne 734 ]; then
    echo "STOP: expected 734 verified gzip files; found $EXPECTED"
    exit 1
fi

mkdir "$TEMP"
export TEMP

decompress_one() {
    local source_file="$1"
    local output_file="$TEMP/$(basename "$source_file" .gz)"

    gzip -cd -- "$source_file" > "$output_file"

    if [ ! -s "$output_file" ]; then
        echo "FAIL: empty output from $source_file"
        return 1
    fi
}
export -f decompress_one

echo "Decompression started: $(date)"

find "$SOURCE" -maxdepth 1 -type f \
    -name '*_TFBS.bed.gz' -print0 |
sort -z |
xargs -0 -r -n1 -P "$SLURM_CPUS_PER_TASK" \
    bash -c 'decompress_one "$1"' _

ACTUAL=$(
    find "$TEMP" -maxdepth 1 -type f \
        -name '*_TFBS.bed' | wc -l
)

if [ "$ACTUAL" -ne "$EXPECTED" ]; then
    echo "STOP: expected $EXPECTED BED files; created $ACTUAL"
    exit 1
fi

mv "$TEMP" "$TARGET"

echo "Decompression completed: $(date)"
echo "PASS: created $ACTUAL uncompressed TFBS BED files"
du -sh "$TARGET"
