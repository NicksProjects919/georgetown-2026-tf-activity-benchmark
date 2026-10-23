#!/bin/bash
#SBATCH --job-name=difftf_tfbs
#SBATCH --account=gtw109
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=04:00:00
#SBATCH --output=__PROJECT_DIR__/logs/difftf_tfbs_%j.out
#SBATCH --error=__PROJECT_DIR__/logs/difftf_tfbs_%j.err
#SBATCH --export=ALL

set -euo pipefail

source __PROJECT_DIR__/env.sh

URL="https://www.embl.de/download/zaugg/diffTF/TFBS/TFBS_hg38_FIMO_HOCOMOCOv11.tar.gz"
DEST="$SCRATCH_PROJ/references/diffTF"
ARCHIVE="$DEST/TFBS_hg38_FIMO_HOCOMOCOv11.tar.gz"
PART="$ARCHIVE.part"
LISTING="$ARCHIVE.contents.txt"

mkdir -p "$DEST"

if test -s "$ARCHIVE"; then
    gzip -t "$ARCHIVE"
    echo "Archive already exists and passed gzip validation: $ARCHIVE"
    exit 0
fi

echo "Download started: $(date)"
echo "URL: $URL"
echo "Partial file: $PART"

curl \
  --location \
  --fail \
  --retry 8 \
  --retry-delay 15 \
  --continue-at - \
  --output "$PART" \
  "$URL"

gzip -t "$PART"
mv "$PART" "$ARCHIVE"

sha256sum "$ARCHIVE" > "$ARCHIVE.sha256"
tar -tzf "$ARCHIVE" > "$LISTING"

echo "Download and validation completed: $(date)"
ls -lh "$ARCHIVE" "$ARCHIVE.sha256" "$LISTING"

echo
echo "First archive entries:"
head -20 "$LISTING"
