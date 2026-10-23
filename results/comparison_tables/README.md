# Three-Pipeline TF Comparison

This directory contains the final standardized tables used to compare
TF-Prioritizer, nf-core/tfactivity, and diffTF for the K562-versus-MCF7
DNase-seq benchmark.

## Standardization

TF names were converted to gene symbols before comparison.

TF-Prioritizer and nf-core/tfactivity were compared using their final
rank positions rather than their raw DCG scores.

For diffTF, HOCOMOCO v11 motif identifiers were mapped to TF gene
symbols. When multiple motifs mapped to the same TF, the representative
motif was selected by the lowest adjusted p-value and then the largest
absolute weighted mean difference.

Positive diffTF effects indicate greater accessibility in MCF7, while
negative effects indicate greater accessibility in K562. Statistical
significance was defined as an adjusted p-value below 0.05.

## Complete final-result comparison

- TF-Prioritizer reported 13 final TFs.
- nf-core/tfactivity reported 33 final TFs.
- diffTF evaluated 734 motif models representing 653 TF gene symbols.
- diffTF identified 327 significant TF genes before the final
  binding-site quality-control exclusion.
- The final Venn comparison contained 323 QC-valid significant diffTF
  TF genes.

Four significant genes—DLX4, HOMEZ, MEOX2, and ZNF333—were excluded
from the final Venn comparison because their motif models lacked enough
usable binding-site observations.

The complete final-result overlap was:

| Comparison | Shared TFs |
|---|---:|
| TF-Prioritizer and nf-core/tfactivity only | 0 |
| TF-Prioritizer and diffTF only | 2 |
| nf-core/tfactivity and diffTF only | 18 |
| All three pipelines | 0 |

The two TFs shared by TF-Prioritizer and diffTF were HOXB7 and ZNF257.

## Equal-sized top-13 comparison

TF-Prioritizer produced only 13 final TFs. Therefore, a second
comparison used the top 13 QC-valid TF genes from every pipeline so
that all three sets had the same size.

TF-Prioritizer and nf-core/tfactivity were ordered by their final DCG
rankings. diffTF was ordered by adjusted p-value, with absolute effect
size used to resolve ties.

The corrected diffTF list excludes the sparse ZNF333 motif model and
includes FOXA3 as the next QC-valid result. No TF was shared between
any pair of pipelines in the final top-13 comparison.

## Files

- `tfprioritizer_standardized.tsv`: final TF-Prioritizer ranking.
- `tfactivity_standardized.tsv`: final nf-core/tfactivity ranking.
- `difftf_motif_standardized.tsv`: standardized motif-level diffTF data.
- `difftf_gene_standardized.tsv`: gene-level diffTF ranking.
- `three_pipeline_comparison.tsv`: combined comparison by TF symbol.
- `complete_result_membership.tsv`: membership in each complete final set.
- `complete_result_venn_regions.tsv`: complete-list Venn regions.
- `top13/`: equal-sized, QC-corrected top-13 comparison.

## Reproducibility

The comparison was originally performed interactively during the
benchmark. The script
`../../scripts/comparison/verify_comparison_tables.py` validates the
archived row counts, quality-control exclusions, overlaps, and top-13
results. It does not regenerate the standardized tables from the
original pipeline output directories.

## Interpretation

The pipelines use different definitions, scoring methods, and final
filters. Differences in overlap therefore reflect methodological
differences and do not by themselves establish that one pipeline is
more biologically accurate than another.
