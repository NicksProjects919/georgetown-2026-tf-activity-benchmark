#!/usr/bin/env python3
"""Validate the archived three-pipeline comparison tables."""

from pathlib import Path
import csv

REPO = Path(__file__).resolve().parents[2]
TABLES = REPO / "results" / "comparison_tables"


def read_tsv(name):
    path = TABLES / name
    with path.open() as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        rows = list(reader)

    for line_number, row in enumerate(rows, start=2):
        assert None not in row, (
            f"{path}:{line_number}: unexpected extra fields"
        )
        assert all(value is not None for value in row.values()), (
            f"{path}:{line_number}: missing fields"
        )

    return rows


tfp = read_tsv("tfprioritizer_standardized.tsv")
tfa = read_tsv("tfactivity_standardized.tsv")
motifs = read_tsv("difftf_motif_standardized.tsv")
genes = read_tsv("difftf_gene_standardized.tsv")
combined = read_tsv("three_pipeline_comparison.tsv")
membership = read_tsv("complete_result_membership.tsv")
regions = read_tsv("complete_result_venn_regions.tsv")
top13 = read_tsv("top13/top13_rankings.tsv")
top13_regions = read_tsv("top13/top13_venn_regions.tsv")

assert len(tfp) == 13
assert len(tfa) == 33
assert len(motifs) == 734
assert len(genes) == 653
assert len(combined) == 661
assert len(membership) == 349

raw_significant = {
    row["tf_symbol"]
    for row in genes
    if row["significant_FDR_0.05"] == "Yes"
}
assert len(raw_significant) == 327

tfp_final = {
    row["tf_symbol"]
    for row in membership
    if row["TF_Prioritizer_final"] == "Yes"
}
tfa_final = {
    row["tf_symbol"]
    for row in membership
    if row["tfactivity_final"] == "Yes"
}
difftf_final = {
    row["tf_symbol"]
    for row in membership
    if row["diffTF_significant"] == "Yes"
}

assert len(tfp_final) == 13
assert len(tfa_final) == 33
assert len(difftf_final) == 323
assert tfp_final & tfa_final == set()
assert tfp_final & difftf_final == {"HOXB7", "ZNF257"}
assert len(tfa_final & difftf_final) == 18
assert tfp_final & tfa_final & difftf_final == set()

excluded = raw_significant - difftf_final
assert excluded == {"DLX4", "HOMEZ", "MEOX2", "ZNF333"}

expected_complete_regions = {
    "TF-Prioritizer only": 11,
    "nf-core/tfactivity only": 15,
    "diffTF only": 303,
    "TF-Prioritizer + tfactivity only": 0,
    "TF-Prioritizer + diffTF only": 2,
    "tfactivity + diffTF only": 18,
    "All three": 0,
}

observed_complete_regions = {
    row["region"]: int(row["count"])
    for row in regions
}
assert observed_complete_regions == expected_complete_regions

top_sets = {}
for pipeline in ["TF-Prioritizer", "nf-core/tfactivity", "diffTF"]:
    rows = [
        row for row in top13
        if row["pipeline"] == pipeline
    ]
    assert len(rows) == 13
    assert sorted(int(row["rank"]) for row in rows) == list(range(1, 14))
    top_sets[pipeline] = {row["tf_symbol"] for row in rows}

assert top_sets["TF-Prioritizer"] & top_sets["nf-core/tfactivity"] == set()
assert top_sets["TF-Prioritizer"] & top_sets["diffTF"] == set()
assert top_sets["nf-core/tfactivity"] & top_sets["diffTF"] == set()
assert "ZNF333" not in top_sets["diffTF"]
assert "FOXA3" in top_sets["diffTF"]

expected_top13_regions = {
    "TF-Prioritizer only": 13,
    "nf-core/tfactivity only": 13,
    "diffTF only": 13,
    "TF-Prioritizer + tfactivity only": 0,
    "TF-Prioritizer + diffTF only": 0,
    "tfactivity + diffTF only": 0,
    "All three": 0,
}

observed_top13_regions = {
    row["region"]: int(row["count"])
    for row in top13_regions
}
assert observed_top13_regions == expected_top13_regions

print("PASS: all archived comparison tables are internally consistent")
print("TF-Prioritizer final TFs: 13")
print("nf-core/tfactivity final TFs: 33")
print("diffTF raw significant TF genes: 327")
print("diffTF QC-valid significant TF genes: 323")
print("Complete-list overlaps: 0, 2, 18, and 0 shared by all three")
print("Top-13 comparison: no TF shared between any pair")
