# Native Final Summary Outputs

This directory contains small, unmodified final outputs copied directly
from each pipeline. The standardized cross-pipeline tables are stored in
`../comparison_tables/`.

## TF-Prioritizer

`tfprioritizer/dcg.tsv` is the final DCG-ranked list of 13 TFs used in
the comparison.

## nf-core/tfactivity

`tfactivity/DNase-seq.tf_ranking.tsv` is the final DNase-seq-specific
ranking of 33 TFs used in the comparison.

## diffTF

`difftf/K562vsMCF7.all.summary.tsv.gz` contains the final results for
734 TF motif models.

`difftf/K562vsMCF7.all.summary.volcano.pdf` is the final volcano plot.

`difftf/K562vsMCF7.all.diagnosticPlots.pdf` contains the final
diagnostic plots.

## Files not included

Large interactive report directories, workflow work directories,
intermediate files, containers, and large detailed result tables are
not stored in GitHub.

Notable excluded outputs include the 878 MB nf-core/tfactivity report
directory, the 274 MB diffTF all-motif table, and the complete
TF-Prioritizer output directory. These outputs can be reproduced using
the archived scripts, configurations, environments, and input manifest.

## Verification

`SHA256SUMS` records checksums for the five native output files.

The script `../../scripts/comparison/verify_native_summaries.py`
confirms that the native TF rankings and diffTF motifs agree with the
standardized comparison tables.
