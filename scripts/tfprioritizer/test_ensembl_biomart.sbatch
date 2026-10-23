#!/bin/bash
#SBATCH --job-name=biomart_test
#SBATCH --account=gtw109
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --time=00:05:00
#SBATCH --output=__PROJECT_DIR__/logs/biomart_test_%j.out
#SBATCH --error=__PROJECT_DIR__/logs/biomart_test_%j.err
#SBATCH --export=ALL

set -u -o pipefail

source __PROJECT_DIR__/env.sh
module load singularitypro/4.1.2

IMAGE="$SCRATCH_PROJ/containers/TF-Prioritizer/tf-prioritizer_master.sif"
QUERY="/tmp/biomart_${SLURM_JOB_ID}.xml"

cat > "$QUERY" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE Query>
<Query virtualSchemaName="default" formatter="TSV" header="0" uniqueRows="1" datasetConfigVersion="0.6">
  <Dataset name="hsapiens_gene_ensembl" interface="default">
    <Filter name="ensembl_gene_id" value="ENSG00000139618"/>
    <Attribute name="ensembl_gene_id"/>
    <Attribute name="hgnc_symbol"/>
  </Dataset>
</Query>
XML

PASS=0

for URL in \
  "https://www.ensembl.org/biomart/martservice" \
  "https://mart.ensembl.org/biomart/martservice"
do
    echo "Testing: $URL"

    if singularity exec --cleanenv "$IMAGE" \
      curl -LfsS \
        --connect-timeout 15 \
        --max-time 60 \
        --get \
        --data-urlencode "query@$QUERY" \
        "$URL" |
      tee "/tmp/biomart_${SLURM_JOB_ID}.tsv" |
      grep -q '^ENSG00000139618'; then
        echo "PASS: $URL"
        head -1 "/tmp/biomart_${SLURM_JOB_ID}.tsv"
        PASS=1
    else
        echo "FAIL: $URL"
    fi
done

if [ "$PASS" -ne 1 ]; then
    exit 1
fi
