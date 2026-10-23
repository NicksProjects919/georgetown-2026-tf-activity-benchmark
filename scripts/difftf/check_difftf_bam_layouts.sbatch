#!/bin/bash
#SBATCH --job-name=difftf_layout
#SBATCH --account=gtw109
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=04:00:00
#SBATCH --output=__PROJECT_DIR__/logs/difftf_layout_%j.out
#SBATCH --error=__PROJECT_DIR__/logs/difftf_layout_%j.err
#SBATCH --export=ALL

set -euo pipefail

source __PROJECT_DIR__/env.sh

ENV_DIR="__MINIFORGE_DIR__/envs/difftf_tier1"
SHEET="$PROJ/samplesheets/diffTF/tier1_dnase_sampleData.tsv"
OUTDIR="$SCRATCH_PROJ/results/diffTF/tier1_dnase/diagnostics/bam_layout"

export PATH="$ENV_DIR/bin:$PATH"
mkdir -p "$OUTDIR"

check_bam() {
    BAM="$1"
    SAMPLE=$(basename "$BAM" .bam)
    STAT="$OUTDIR/${SAMPLE}.flagstat.txt"
    RESULT="$OUTDIR/${SAMPLE}.layout.tsv"

    samtools flagstat -@ 2 "$BAM" > "$STAT"

    PRIMARY=$(awk '$0 ~ / primary$/ {print $1 + $3; exit}' "$STAT")
    PAIRED=$(awk '/ paired in sequencing/ {print $1 + $3; exit}' "$STAT")

    if [ -z "$PRIMARY" ] || [ -z "$PAIRED" ]; then
        echo "STOP: unable to parse $STAT" >&2
        exit 1
    fi

    if [ "$PAIRED" -eq 0 ]; then
        LAYOUT="single-end"
    elif [ "$PAIRED" -eq "$PRIMARY" ]; then
        LAYOUT="paired-end"
    else
        LAYOUT="mixed"
    fi

    printf '%s\t%s\t%s\t%s\n' \
        "$SAMPLE" "$PRIMARY" "$PAIRED" "$LAYOUT" > "$RESULT"
}

export -f check_bam
export OUTDIR

awk -F'\t' 'NR > 1 {print $3}' "$SHEET" |
    xargs -P 4 -n 1 bash -c 'check_bam "$1"' _

{
    printf 'sample\tprimary_records\tpaired_records\tlayout\n'
    cat "$OUTDIR"/*.layout.tsv | sort
} | tee "$OUTDIR/summary.tsv"

echo "ALL BAM LAYOUTS CHECKED SUCCESSFULLY"
