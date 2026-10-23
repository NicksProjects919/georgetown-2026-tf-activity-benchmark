#!/usr/bin/env python3
import csv, json, os, re, urllib.request

PROJ = os.environ["PROJ"]
MAN = f"{PROJ}/metadata/DNase_peaks/peak_manifest.tsv"
OUT = f"{PROJ}/metadata/DNase_peaks/peak_manifest_annotated.tsv"
BASE = "https://www.encodeproject.org"

rows = list(csv.DictReader(open(MAN), delimiter="\t"))
for r in rows:
    req = urllib.request.Request(
        f"{BASE}/files/{r['file_accession']}/?format=json",
        headers={"Accept": "application/json"})
    d = json.load(urllib.request.urlopen(req))
    sfn = d.get("submitted_file_name", "") or ""
    m = re.search(r"nuclear\.([0-9.]+)\.peaks", sfn)
    r["fdr"] = m.group(1) if m else "UNKNOWN"
    r["date_created"] = d.get("date_created", "")[:10]
    r["file_size_mb"] = round(int(d.get("file_size", 0)) / 1e6, 2)

with open(OUT, "w", newline="") as fh:
    w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()), delimiter="\t")
    w.writeheader(); w.writerows(rows)

from collections import Counter
print(Counter((r["fdr"], r["date_created"][:4]) for r in rows))
print(f"\n-> {OUT}")
