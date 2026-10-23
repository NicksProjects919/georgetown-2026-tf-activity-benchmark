#!/bin/bash
#SBATCH --job-name=difftf_consensus_diag
#SBATCH --account=gtw109
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=64G
#SBATCH --time=01:00:00
#SBATCH --output=__PROJECT_DIR__/logs/difftf_consensus_diag_%j.out
#SBATCH --error=__PROJECT_DIR__/logs/difftf_consensus_diag_%j.err
#SBATCH --export=ALL

set -euo pipefail

source __PROJECT_DIR__/env.sh

ENV_DIR="__MINIFORGE_DIR__/envs/difftf_tier1"
SAMPLES="$PROJ/samplesheets/diffTF/tier1_dnase_sampleData.tsv"

export PATH="$ENV_DIR/bin:$PATH"

Rscript --vanilla - "$SAMPLES" <<'RS'
args <- commandArgs(trailingOnly = TRUE)
samples_file <- args[[1]]

suppressPackageStartupMessages({
    library(DiffBind)
    library(readr)
})

samples <- read_tsv(samples_file, show_col_types = FALSE)
samples$Condition <- samples$conditionSummary
samples$PeakCaller <- "narrow"
samples$conditionSummary <- samples$Condition

cat("DiffBind version:", as.character(packageVersion("DiffBind")), "\n")
cat("Input samples:", nrow(samples), "\n")

original <- dba(sampleSheet = as.data.frame(samples))
consensus <- dba.peakset(original, minOverlap = 2)

cat("Original peak-list entries:", length(original$peaks), "\n")
cat("Consensus peak-list entries:", length(consensus$peaks), "\n")
cat(
    "Rows per consensus entry:",
    paste(vapply(consensus$peaks, NROW, integer(1)), collapse = ","),
    "\n"
)

cat("\nConsensus object summary:\n")
print(dba.show(consensus))

expected_index <- nrow(samples) + 1
cat("\nIndex assumed by diffTF:", expected_index, "\n")

if (length(consensus$peaks) >= expected_index) {
    cat(
        "Rows at assumed index:",
        NROW(consensus$peaks[[expected_index]]),
        "\n"
    )
} else {
    cat("Assumed index does not exist\n")
}
RS
