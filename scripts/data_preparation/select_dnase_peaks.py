#!/usr/bin/env python3
import csv, json, os, urllib.request
from collections import defaultdict

PROJ = os.environ["PROJ"]
MAN = f"{PROJ}/metadata/DNase_peaks/peak_manifest.tsv"
BASE = "https://www.encodeproject.org"

rows = list(csv.DictReader(open(MAN), delimiter="\t"))
for r in rows:
    req = urllib.request.Request(
        f"{BASE}/files/{r['file_accession']}/?format=json",
        headers={"Accept": "application/json"})
    d = json.load(urllib.request.urlopen(req))
    r["preferred_default"] = bool(d.get("preferred_default"))
    r["date_created"] = d.get("date_created", "")[:10]
    r["file_size"] = int(d.get("file_size", 0))
    r["analyses"] = ";".join(
        (a.get("accession") or a.get("@id","").strip("/").split("/")[-1])
        if isinstance(a, dict) else a.strip("/").split("/")[-1]
        for a in d.get("analyses", []))

groups = defaultdict(list)
for r in rows:
    groups[(r["cell_line"], r["experiment"], r["bio_reps"])].append(r)

print(f"{len(groups)} replicate groups\n")
for k in sorted(groups):
    print(f"--- {k[0]} {k[1]} rep{k[2]}")
    for r in sorted(groups[k], key=lambda x: (not x["preferred_default"], x["date_created"]), reverse=False):
        print(f"    {r['file_accession']}  pref={r['preferred_default']}  "
              f"{r['date_created']}  {r['file_size']/1e6:.2f}MB  {r['analyses']}")
    picked = sorted(groups[k], key=lambda x: (x["preferred_default"], x["date_created"]))[-1]
    print(f"    -> WOULD PICK {picked['file_accession']}")
