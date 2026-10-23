#!/bin/bash
#SBATCH --job-name=difftf_env
#SBATCH --account=gtw109
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=02:00:00
#SBATCH --output=__PROJECT_DIR__/logs/difftf_env_%j.out
#SBATCH --error=__PROJECT_DIR__/logs/difftf_env_%j.err
#SBATCH --export=ALL

set -euo pipefail

source __PROJECT_DIR__/env.sh
source __MINIFORGE_DIR__/etc/profile.d/conda.sh

BASE_ENV="__MINIFORGE_DIR__/envs/difftf"
NEW_ENV="__MINIFORGE_DIR__/envs/difftf_tier1"
MAMBA="__MINIFORGE_DIR__/bin/mamba"

if [ -e "$NEW_ENV" ]; then
    echo "STOP: target environment already exists: $NEW_ENV"
    exit 1
fi

echo "Cloning existing diffTF environment: $(date)"

"$MAMBA" create \
    --yes \
    --prefix "$NEW_ENV" \
    --clone "$BASE_ENV"

echo "Installing missing diffTF dependencies: $(date)"

"$MAMBA" install \
    --yes \
    --prefix "$NEW_ENV" \
    --override-channels \
    -c conda-forge \
    -c bioconda \
    r-checkmate \
    r-tidyverse \
    r-lsr \
    r-ggrepel \
    r-modeest \
    bioconductor-csaw \
    bioconductor-diffbind \
    r-locfdr \
    bioconductor-vsn \
    bioconductor-geneplotter

"$NEW_ENV/bin/Rscript" --vanilla - <<'RS'
packages <- c(
    "checkmate", "tidyverse", "futile.logger", "lsr",
    "ggrepel", "modeest", "Rsamtools", "DESeq2", "csaw",
    "limma", "matrixStats", "DiffBind", "locfdr", "vsn",
    "geneplotter", "RColorBrewer"
)

available <- vapply(
    packages,
    requireNamespace,
    logical(1),
    quietly = TRUE
)

if (!all(available)) {
    stop(
        "Missing after installation: ",
        paste(packages[!available], collapse = ", ")
    )
}

cat("PASS: all", length(packages), "diffTF R packages are available\n")
RS

"$MAMBA" list --explicit --prefix "$NEW_ENV" \
    > "$PROJ/configs/diffTF/difftf_tier1_environment_explicit.txt"

echo "Environment completed successfully: $(date)"
echo "Environment: $NEW_ENV"
