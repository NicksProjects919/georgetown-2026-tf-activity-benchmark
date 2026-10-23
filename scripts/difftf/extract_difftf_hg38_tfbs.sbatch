#!/bin/bash
#SBATCH --job-name=difftf_tfbs_x
#SBATCH --account=gtw109
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=04:00:00
#SBATCH --output=__PROJECT_DIR__/logs/difftf_tfbs_extract_%j.out
#SBATCH --error=__PROJECT_DIR__/logs/difftf_tfbs_extract_%j.err
#SBATCH --export=ALL

set -euo pipefail

source __PROJECT_DIR__/env.sh

DEST="$SCRATCH_PROJ/references/diffTF"
ARCHIVE="$DEST/TFBS_hg38_FIMO_HOCOMOCOv11.tar.gz"
LISTING="$ARCHIVE.contents.txt"
TFBS_DIR="$DEST/FIMO_HOCOMOCOv11"

test -s "$ARCHIVE" || {
    echo "STOP: archive is missing or empty: $ARCHIVE"
    exit 1
}

gzip -t "$ARCHIVE"

test -s "$LISTING" || {
    echo "STOP: archive listing is missing: $LISTING"
    exit 1
}

if awk '
    /^\// || /(^|\/)\.\.(\/|$)/ {bad=1}
    $0 !~ /^FIMO_HOCOMOCOv11\// {bad=1}
    END {exit bad}
' "$LISTING"
then
    echo "PASS: archive paths are safe"
else
    echo "STOP: unsafe or unexpected archive path found"
    exit 1
fi

test ! -e "$TFBS_DIR" || {
    echo "STOP: extraction directory already exists: $TFBS_DIR"
    exit 1
}

echo "Extraction started: $(date)"
tar -xzf "$ARCHIVE" -C "$DEST"
echo "Extraction completed: $(date)"

COUNT=$(find "$TFBS_DIR" -maxdepth 1 -type f -name '*.bed.gz' | wc -l)

echo "TFBS BED files: $COUNT"

test "$COUNT" -eq 767 || {
    echo "STOP: expected 767 TFBS BED files, found $COUNT"
    exit 1
}

find "$TFBS_DIR" -maxdepth 1 -type f -name '*.bed.gz' -print0 |
xargs -0 -n 1 -P "$SLURM_CPUS_PER_TASK" gzip -t

BAD=0
while IFS= read -r FILE; do
    if ! gzip -cd "$FILE" |
         awk -F'\t' 'NR==1 {exit NF == 6 ? 0 : 1}'; then
        echo "INVALID BED6: $FILE"
        BAD=1
    fi
done < <(
    find "$TFBS_DIR" -maxdepth 1 -type f -name '*.bed.gz' | sort
)

test "$BAD" -eq 0 || {
    echo "STOP: one or more TFBS files failed BED6 validation"
    exit 1
}

touch "$TFBS_DIR/.validation_complete"

echo "PASS: all 767 TFBS files passed gzip and BED6 checks"
du -sh "$TFBS_DIR"
