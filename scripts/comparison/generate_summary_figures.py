#!/usr/bin/env python3
"""Generate summary SVG figures from archived benchmark tables."""

from pathlib import Path
from html import escape
import csv

ROOT = Path(__file__).resolve().parents[2]
FIG = ROOT / "figures"


def read_tsv(path):
    with path.open() as handle:
        return list(csv.DictReader(handle, delimiter="\t"))


def tx(x, y, value, size=20, weight="normal", anchor="middle"):
    return (
        f'<text x="{x}" y="{y}" text-anchor="{anchor}" '
        f'font-size="{size}" font-weight="{weight}">'
        f'{escape(str(value))}</text>'
    )


FIG.mkdir(exist_ok=True)

# Complete final-result Venn diagram
rows = read_tsv(
    ROOT / "results/comparison_tables/complete_result_venn_regions.tsv"
)
counts = {row["region"]: int(row["count"]) for row in rows}

expected = {
    "TF-Prioritizer only": 11,
    "nf-core/tfactivity only": 15,
    "diffTF only": 303,
    "TF-Prioritizer + tfactivity only": 0,
    "TF-Prioritizer + diffTF only": 2,
    "tfactivity + diffTF only": 18,
    "All three": 0,
}
assert counts == expected

venn = [
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 900" '
    'font-family="Arial, Helvetica, sans-serif" fill="#17202A">',
    '<rect width="1200" height="900" fill="#FFFFFF"/>',
    tx(600, 50, "Overlap of Complete Final TF Lists", 34, "bold"),
    '<circle cx="410" cy="360" r="210" fill="#69AEDD" '
    'fill-opacity="0.35" stroke="#2D83B7" stroke-width="4"/>',
    '<circle cx="790" cy="360" r="210" fill="#E889A6" '
    'fill-opacity="0.35" stroke="#CE4F78" stroke-width="4"/>',
    '<circle cx="600" cy="565" r="210" fill="#87C98A" '
    'fill-opacity="0.35" stroke="#40984B" stroke-width="4"/>',
    tx(300, 103, "TF-Prioritizer", 27, "bold"),
    tx(300, 132, "Final prioritized TFs: n = 13", 18),
    tx(900, 103, "nf-core/tfactivity", 27, "bold"),
    tx(900, 132, "Final prioritized TFs: n = 33", 18),
    tx(600, 810, "diffTF", 27, "bold"),
    tx(600, 839, "Significant, QC-valid TF genes: n = 323", 18),
]

labels = [
    (325, 345, "TF-Prioritizer only", "only"),
    (875, 345, "nf-core/tfactivity only", "only"),
    (600, 665, "diffTF only", "only"),
    (600, 255, "TF-Prioritizer + tfactivity only", "TFP + tfactivity"),
    (470, 485, "TF-Prioritizer + diffTF only", "TFP + diffTF"),
    (730, 485, "tfactivity + diffTF only", "tfactivity + diffTF"),
    (600, 405, "All three", "all three"),
]

for x, y, key, label in labels:
    venn.append(tx(x, y, counts[key], 34, "bold"))
    venn.append(tx(x, y + 27, label, 17))

venn.extend([
    tx(600, 882, "TF symbols were standardized before comparison.", 17),
    "</svg>",
])

(FIG / "complete-final-venn.svg").write_text("\n".join(venn) + "\n")

# Runtime and storage comparison
rows = read_tsv(ROOT / "results/practical_benchmark.tsv")
assert [row["pipeline"] for row in rows] == [
    "nf-core/tfactivity",
    "TF-Prioritizer",
    "diffTF",
]

colors = ["#2D83B7", "#CE4F78", "#40984B"]
runtime = [int(row["runtime_seconds"]) / 3600 for row in rows]
storage = [float(row["results_storage"].split()[0]) for row in rows]

chart = [
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 740" '
    'font-family="Arial, Helvetica, sans-serif" fill="#17202A">',
    '<rect width="1200" height="740" fill="#FFFFFF"/>',
    tx(600, 50, "Observed Runtime and Results Storage", 34, "bold"),
]

panels = [
    ("Observed runtime", runtime, "observed_runtime", 105),
    (
        "Complete results-directory storage",
        storage,
        "results_storage",
        395,
    ),
]

for title, values, label_field, start in panels:
    chart.append(tx(50, start, title, 25, "bold", "start"))
    maximum = max(values)

    for index, row in enumerate(rows):
        y = start + 28 + index * 68
        width = values[index] / maximum * 700

        chart.append(tx(260, y + 29, row["pipeline"], 20, anchor="end"))
        chart.append(
            f'<rect x="285" y="{y}" width="{width:.1f}" height="42" '
            f'rx="5" fill="{colors[index]}"/>'
        )
        chart.append(
            tx(
                300 + width,
                y + 28,
                row[label_field],
                19,
                "bold",
                "start",
            )
        )

chart.extend([
    tx(
        600,
        680,
        "Recorded workflow observations, not a controlled speed test.",
        18,
    ),
    tx(
        600,
        710,
        "See docs/PRACTICAL_COMPARISON.md for measurement details.",
        18,
    ),
    "</svg>",
])

(FIG / "practical-comparison.svg").write_text(
    "\n".join(chart) + "\n"
)

print("Created: figures/complete-final-venn.svg")
print("Created: figures/practical-comparison.svg")
