#!/bin/bash
#SBATCH --job-name=tfprio_sortbam
#SBATCH --account=gtw109
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=48G
#SBATCH --time=48:00:00
#SBATCH --output=__PROJECT_DIR__/logs/tfprio_sortbam_%j.out
#SBATCH --error=__PROJECT_DIR__/logs/tfprio_sortbam_%j.err
#SBATCH --export=ALL

set -euo pipefail

source __PROJECT_DIR__/env.sh
module load singularitypro/4.1.2

SAMTOOLS_IMAGE="$SCRATCH_PROJ/containers/tfactivity/depot.galaxyproject.org-singularity-samtools-1.22.1--h96c455f_0.img"

SOURCE_ROOT="$SCRATCH_PROJ/inputs/TF-Prioritizer/tier1_dnase/bams"
DEST_ROOT="$SCRATCH_PROJ/inputs/TF-Prioritizer/tier1_dnase/bams_coordinate"
TEMP_ROOT="$SCRATCH_PROJ/work/TF-Prioritizer/bam_sort/${SLURM_JOB_ID}"
MANIFEST="$DEST_ROOT/sort_manifest.tsv"

run_samtools() {
    singularity exec --cleanenv \
      --bind "$SCRATCH_PROJ:$SCRATCH_PROJ" \
      "$SAMTOOLS_IMAGE" \
      samtools "$@"
}

mkdir -p "$DEST_ROOT" "$TEMP_ROOT"

if [ ! -e "$MANIFEST" ]; then
    printf 'staged_bam\tsource_bam\tbytes\tstatus\n' > "$MANIFEST"
fi

mapfile -t BAM_LINKS < <(
    find "$SOURCE_ROOT" -type l -name "*.bam" -print | sort
)

if [ "${#BAM_LINKS[@]}" -ne 10 ]; then
    echo "STOP: expected 10 staged BAM links; found ${#BAM_LINKS[@]}"
    exit 1
fi

for LINK in "${BAM_LINKS[@]}"; do
    RELATIVE="${LINK#"$SOURCE_ROOT"/}"
    FINAL_BAM="$DEST_ROOT/$RELATIVE"
    FINAL_BAI="$FINAL_BAM.bai"

    SOURCE_BAM="$(readlink -f "$LINK")"
    SAMPLE="$(basename "$FINAL_BAM" .bam)"

    TEMP_BAM="$TEMP_ROOT/${SAMPLE}.bam"
    TEMP_BAI="$TEMP_BAM.bai"
    TEMP_PREFIX="$TEMP_ROOT/${SAMPLE}.sorttmp"

    echo
    echo "Processing: $RELATIVE"
    echo "Source: $SOURCE_BAM"

    # A retry may safely skip an already completed BAM.
    if [ -s "$FINAL_BAM" ] && [ -s "$FINAL_BAI" ]; then
        run_samtools quickcheck "$FINAL_BAM"

        SORT_ORDER="$(
          run_samtools view -H "$FINAL_BAM" |
          awk -F'\t' '
            $1=="@HD" {
              for (i=2; i<=NF; i++)
                if ($i ~ /^SO:/) {
                  sub(/^SO:/, "", $i)
                  print $i
                }
            }'
        )"

        if [ "$SORT_ORDER" = "coordinate" ]; then
            echo "Already complete and valid; skipping"
            continue
        fi
    fi

    # Do not overwrite an incomplete or invalid result.
    if [ -e "$FINAL_BAM" ] || [ -e "$FINAL_BAI" ]; then
        echo "STOP: incomplete or invalid final files already exist:"
        echo "$FINAL_BAM"
        echo "$FINAL_BAI"
        exit 1
    fi

    run_samtools sort \
      -@ "$SLURM_CPUS_PER_TASK" \
      -m 4G \
      -T "$TEMP_PREFIX" \
      -o "$TEMP_BAM" \
      "$LINK"

    run_samtools index \
      -@ "$SLURM_CPUS_PER_TASK" \
      "$TEMP_BAM"

    run_samtools quickcheck "$TEMP_BAM"

    SORT_ORDER="$(
      run_samtools view -H "$TEMP_BAM" |
      awk -F'\t' '
        $1=="@HD" {
          for (i=2; i<=NF; i++)
            if ($i ~ /^SO:/) {
              sub(/^SO:/, "", $i)
              print $i
            }
        }'
    )"

    if [ "$SORT_ORDER" != "coordinate" ]; then
        echo "STOP: output does not report coordinate sorting"
        exit 1
    fi

    mkdir -p "$(dirname "$FINAL_BAM")"

    mv "$TEMP_BAM" "$FINAL_BAM"
    mv "$TEMP_BAI" "$FINAL_BAI"

    BYTES="$(stat -c '%s' "$FINAL_BAM")"

    printf '%s\t%s\t%s\tPASS\n' \
      "$FINAL_BAM" "$SOURCE_BAM" "$BYTES" >> "$MANIFEST"

    echo "PASS: $FINAL_BAM"
done

BAM_COUNT="$(find "$DEST_ROOT" -type f -name "*.bam" | wc -l)"
BAI_COUNT="$(find "$DEST_ROOT" -type f -name "*.bam.bai" | wc -l)"

echo
echo "Coordinate-sorted BAMs: $BAM_COUNT"
echo "BAM indexes: $BAI_COUNT"

if [ "$BAM_COUNT" -ne 10 ] || [ "$BAI_COUNT" -ne 10 ]; then
    echo "STOP: expected 10 BAMs and 10 indexes"
    exit 1
fi

echo "ALL 10 BAMs SORTED AND INDEXED SUCCESSFULLY"
