# Summary Figures

This directory contains figures generated from the archived benchmark
tables.

- `complete-final-venn.svg` shows overlap among the complete final TF
  lists after TF-name standardization.
- `practical-comparison.svg` summarizes the recorded runtime and complete
  results-directory storage.

Runtime values are descriptive workflow observations rather than a
controlled performance benchmark. See `docs/PRACTICAL_COMPARISON.md`
for measurement details and limitations.

Recreate both figures from the repository root by running
`python3 scripts/comparison/generate_summary_figures.py`.
