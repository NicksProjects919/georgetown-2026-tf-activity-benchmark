#!/bin/bash
#SBATCH --job-name=difftf_tfbs_check
#SBATCH --account=gtw109
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --output=__PROJECT_DIR__/logs/difftf_tfbs_check_%j.out
#SBATCH --error=__PROJECT_DIR__/logs/difftf_tfbs_check_%j.err
#SBATCH --export=ALL

set -euo pipefail

source __PROJECT_DIR__/env.sh

ARCHIVE="$SCRATCH_PROJ/references/diffTF/TFBS_hg38_FIMO_HOCOMOCOv11.tar.gz"
TFBS_DIR="$SCRATCH_PROJ/references/diffTF/FIMO_HOCOMOCOv11"

EXPECTED=$(
    tar -tzf "$ARCHIVE" |
    awk '/_TFBS\.bed\.gz$/ {n++} END {print n+0}'
)

ACTUAL=$(
    find "$TFBS_DIR" -maxdepth 1 -type f \
        -name '*_TFBS.bed.gz' | wc -l
)

echo "Files in archive: $EXPECTED"
echo "Files extracted:  $ACTUAL"

if [ "$EXPECTED" -ne "$ACTUAL" ]; then
    echo "STOP: archive and extracted file counts differ"
    exit 1
fi

validate_bed() {
    local file="$1"

    if ! gzip -cd -- "$file" |
        awk -F'\t' '
            NF != 6 ||
            $1 !~ /^chr/ ||
            $2 !~ /^[0-9]+$/ ||
            $3 !~ /^[0-9]+$/ ||
            $3 <= $2 ||
            $4 == "" ||
            $6 !~ /^[+-]$/ {
                exit 1
            }
            END {
                if (NR == 0) exit 1
            }
        '
    then
        echo "FAIL: $file"
        return 1
    fi
}
export -f validate_bed

find "$TFBS_DIR" -maxdepth 1 -type f \
    -name '*_TFBS.bed.gz' -print0 |
sort -z |
xargs -0 -r -n1 -P "$SLURM_CPUS_PER_TASK" \
    bash -c 'validate_bed "$1"' _

touch "$TFBS_DIR/.validation_complete"

echo "PASS: all $ACTUAL TFBS files are readable and have valid BED6 records"
