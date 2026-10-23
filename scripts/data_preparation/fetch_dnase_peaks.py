#!/usr/bin/env python3
import csv, json, os, urllib.request

PROJ = os.environ["PROJ"]
MAP = f"{PROJ}/metadata/DNase_peaks/bam_to_experiment.tsv"
OUT = f"{PROJ}/metadata/DNase_peaks/peak_manifest.tsv"
BASE = "https://www.encodeproject.org"

exps = {}
with open(MAP) as fh:
    for cell, fileacc, exp in csv.reader(fh, delimiter="\t"):
        exps[exp] = cell

rows = []
for exp, cell in sorted(exps.items()):
    url = (f"{BASE}/search/?type=File&dataset=/experiments/{exp}/"
           "&file_format=bed&file_format_type=narrowPeak&output_type=peaks"
           "&assembly=GRCh38&status=released&format=json&limit=all")
    req = urllib.request.Request(url, headers={"Accept": "application/json"})
    data = json.load(urllib.request.urlopen(req))
    hits = data.get("@graph", [])
    print(f"{cell}\t{exp}\t{len(hits)} peak file(s)")
    for f in hits:
        rows.append({
            "cell_line": cell,
            "experiment": exp,
            "file_accession": f["accession"],
            "bio_reps": ",".join(str(r) for r in f.get("biological_replicates", [])),
            "genome_annotation": f.get("genome_annotation", "NA"),
            "output_type": f["output_type"],
            "url": BASE + f["href"],
        })

if not rows:
    raise SystemExit("No peak files matched. Send me the output above.")

with open(OUT, "w", newline="") as fh:
    w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()), delimiter="\t")
    w.writeheader(); w.writerows(rows)
print(f"\n{len(rows)} peak files -> {OUT}")
