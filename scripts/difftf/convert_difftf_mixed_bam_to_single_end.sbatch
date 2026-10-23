#!/bin/bash
#SBATCH --job-name=difftf_fixbam
#SBATCH --account=gtw109
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=08:00:00
#SBATCH --output=__PROJECT_DIR__/logs/difftf_fixbam_%j.out
#SBATCH --error=__PROJECT_DIR__/logs/difftf_fixbam_%j.err
#SBATCH --export=ALL

set -euo pipefail

source __PROJECT_DIR__/env.sh

module purge
module load cpu/0.17.3b
module load gcc/10.2.0/npcyll4
module load samtools/1.13/2cnwok7

INPUT="$SCRATCH_PROJ/inputs/TF-Prioritizer/tier1_dnase/bams_coordinate/K562/DNase/ENCFF638QFS.bam"

OUTDIR="$SCRATCH_PROJ/inputs/diffTF/tier1_dnase/bams_single_end/K562/DNase"
OUTPUT="$OUTDIR/ENCFF638QFS.bam"
PARTIAL="$OUTDIR/ENCFF638QFS.partial.bam"
FLAGSTAT="$OUTDIR/ENCFF638QFS.flagstat.txt"
PROVENANCE="$OUTDIR/ENCFF638QFS.conversion.txt"

EXPECTED_RECORDS=229297094

mkdir -p "$OUTDIR"

for TARGET in \
    "$OUTPUT" \
    "$OUTPUT.bai" \
    "$PARTIAL" \
    "$FLAGSTAT" \
    "$PROVENANCE"
do
    if [ -e "$TARGET" ]; then
        echo "STOP: target already exists: $TARGET" >&2
        exit 1
    fi
done

echo "Conversion started: $(date)"
echo "Node: $(hostname)"
echo "Input: $INPUT"
echo "Output: $OUTPUT"
samtools --version | head -1

# Select all unpaired records plus read 1 from paired records.
# Remove flags describing pairing while retaining alignment information.
samtools view \
    -@ 7 \
    -b \
    -e '(!flag.paired) || flag.read1' \
    --remove-flags 235 \
    -o "$PARTIAL" \
    "$INPUT"

samtools quickcheck -v "$PARTIAL"

samtools flagstat -@ 7 "$PARTIAL" > "${PARTIAL}.flagstat"

TOTAL=$(awk 'NR == 1 {print $1 + $3}' "${PARTIAL}.flagstat")
PAIRED=$(awk '/ paired in sequencing/ {print $1 + $3; exit}' \
    "${PARTIAL}.flagstat")

if [ "$TOTAL" -ne "$EXPECTED_RECORDS" ]; then
    echo "STOP: expected $EXPECTED_RECORDS records; found $TOTAL" >&2
    exit 1
fi

if [ "$PAIRED" -ne 0 ]; then
    echo "STOP: output still contains $PAIRED paired records" >&2
    exit 1
fi

mv "$PARTIAL" "$OUTPUT"
mv "${PARTIAL}.flagstat" "$FLAGSTAT"

samtools index -@ 7 "$OUTPUT"
samtools quickcheck -v "$OUTPUT"

{
    echo "Source BAM: $INPUT"
    echo "Derived BAM: $OUTPUT"
    echo "Transformation: retained unpaired records and READ1 from paired records"
    echo "Removed SAM pairing flags: 0xEB (decimal 235)"
    echo "Original source was not modified"
    echo "Output records: $TOTAL"
    echo "Samtools: $(samtools --version | head -1)"
    echo "Slurm job: $SLURM_JOB_ID"
    echo "Completed: $(date)"
} > "$PROVENANCE"

echo
echo "Output validation:"
cat "$FLAGSTAT"

echo
ls -lh "$OUTPUT" "$OUTPUT.bai" "$FLAGSTAT" "$PROVENANCE"
echo "SINGLE-END-COMPATIBLE BAM CREATED SUCCESSFULLY"
