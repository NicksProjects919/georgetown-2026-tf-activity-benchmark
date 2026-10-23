import requests
import csv
import os
import sys
import time

BASE = "https://www.encodeproject.org"
PROJECT = os.path.expanduser("~/TF_Benchmark")

EXPERIMENTS = {
    "ATAC": {
        "K562": ["ENCSR483RKN", "ENCSR859USB", "ENCSR868FGK", "ENCSR956DNB"],
        "MCF7": ["ENCSR422SUG"]
    },
    "DNase": {
        "K562": ["ENCSR000EKP", "ENCSR000EKQ", "ENCSR000EKS", "ENCSR000EOT"],
        "MCF7": ["ENCSR000EKV", "ENCSR000EKW", "ENCSR000EKZ", "ENCSR000EPH"]
    }
}

if len(sys.argv) != 2:
    print("Usage: python scripts/find_encode_bams_clean.py ATAC")
    print("   or: python scripts/find_encode_bams_clean.py DNase")
    sys.exit(1)

assay = sys.argv[1]
rows = []

for cell_line in EXPERIMENTS[assay]:
    for experiment in EXPERIMENTS[assay][cell_line]:
        print("Checking", assay, cell_line, experiment)

        url = BASE + "/experiments/" + experiment + "/?format=json"
        r = requests.get(url, headers={"Accept": "application/json"})
        r.raise_for_status()
        data = r.json()

        for file_info in data.get("files", []):

            if file_info.get("status") != "released":
                continue
            if file_info.get("file_format") != "bam":
                continue
            if file_info.get("assembly") != "GRCh38":
                continue
            if file_info.get("output_type") != "unfiltered alignments":
                continue

            analysis_titles = []
            for analysis in file_info.get("analyses", []):
                if isinstance(analysis, dict):
                    analysis_titles.append(analysis.get("title", ""))

            analysis_text = " | ".join(analysis_titles)

            if "ENCODE4" not in analysis_text:
                continue
            if "ENCODE3" in analysis_text:
                continue

            href = file_info.get("href", "")
            download_url = BASE + href if href else ""

            rows.append({
                "cell_line": cell_line,
                "assay": assay,
                "experiment": experiment,
                "file_accession": file_info.get("accession", ""),
                "file_format": file_info.get("file_format", ""),
                "output_type": file_info.get("output_type", ""),
                "assembly": file_info.get("assembly", ""),
                "status": file_info.get("status", ""),
                "analysis_titles": analysis_text,
                "file_size_bytes": file_info.get("file_size", ""),
                "download_url": download_url
            })

        time.sleep(0.2)

output_file = os.path.join(PROJECT, "metadata", "ENCODE4_GRCh38_unfiltered_released_bams_" + assay + ".tsv")
download_script = os.path.join(PROJECT, "downloads", "download_ENCODE4_GRCh38_unfiltered_released_bams_" + assay + ".sh")

fieldnames = [
    "cell_line", "assay", "experiment", "file_accession",
    "file_format", "output_type", "assembly", "status",
    "analysis_titles", "file_size_bytes", "download_url"
]

with open(output_file, "w", newline="") as out:
    writer = csv.DictWriter(out, fieldnames=fieldnames, delimiter="\t")
    writer.writeheader()
    writer.writerows(rows)

with open(download_script, "w") as out:
    out.write("#!/bin/bash\n")
    out.write("set -euo pipefail\n\n")

    for row in rows:
        outdir = "$HOME/TF_Benchmark/datasets/ENCODE/" + row["cell_line"] + "/" + row["assay"]
        filename = row["file_accession"] + ".bam"
        out.write("mkdir -p " + outdir + "\n")
        out.write("wget -c -O " + outdir + "/" + filename + " \"" + row["download_url"] + "\"\n\n")

os.chmod(download_script, 0o755)

print()
print("Done.")
print("Metadata table:", output_file)
print("Download script:", download_script)
print("Total ENCODE4-only released GRCh38 unfiltered BAM files found:", len(rows))
