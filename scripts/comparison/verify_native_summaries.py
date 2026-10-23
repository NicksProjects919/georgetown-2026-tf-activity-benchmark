#!/usr/bin/env python3
"""Verify native final summaries against standardized comparison tables."""

from pathlib import Path
import csv
import gzip
import re

REPO = Path(__file__).resolve().parents[2]
NATIVE = REPO / "results" / "final_summary_files"
TABLES = REPO / "results" / "comparison_tables"


def read_tsv(path):
    with path.open() as handle:
        return list(csv.DictReader(handle, delimiter="\t"))


tfp_raw = read_tsv(NATIVE / "tfprioritizer/dcg.tsv")
tfp_std = read_tsv(TABLES / "tfprioritizer_standardized.tsv")

assert [row["TF"] for row in tfp_raw] == [
    row["tf_symbol"] for row in tfp_std
]

tfa_raw = read_tsv(
    NATIVE / "tfactivity/DNase-seq.tf_ranking.tsv"
)
tfa_std = read_tsv(TABLES / "tfactivity_standardized.tsv")

pattern = re.compile(r"^(.+)\(([^()]+)\)$")
raw_pairs = []

for row in tfa_raw:
    match = pattern.match(row[""])
    assert match, f"Unable to parse tfactivity TF: {row['']}"
    raw_pairs.append((match.group(1), match.group(2)))

standardized_pairs = [
    (row["tf_symbol"], row["jaspar_motif"])
    for row in tfa_std
]

assert raw_pairs == standardized_pairs

with gzip.open(
    NATIVE / "difftf/K562vsMCF7.all.summary.tsv.gz",
    "rt",
) as handle:
    difftf_raw = list(csv.DictReader(handle, delimiter="\t"))

difftf_std = read_tsv(TABLES / "difftf_motif_standardized.tsv")

assert len(difftf_raw) == 734
assert {row["TF"] for row in difftf_raw} == {
    row["motif_id"] for row in difftf_std
}

print("PASS: TF-Prioritizer native ranking agrees")
print("PASS: nf-core/tfactivity native ranking agrees")
print("PASS: all 734 native diffTF motifs agree")
