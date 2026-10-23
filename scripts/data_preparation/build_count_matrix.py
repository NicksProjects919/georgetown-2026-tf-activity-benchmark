#!/usr/bin/env python3
import glob, os
import pandas as pd

ROOT = os.environ["SCRATCH_PROJ"] + "/datasets/ENCODE"
OUTD = os.environ["PROJ"] + "/samplesheets/tfactivity"
COUNT_COL = "expected_count"
EXCLUDE = {"ENCFF268RFK"}          # GENCODE V24, others are V29

series, design = {}, []
for cell in ["K562", "MCF7"]:
    for f in sorted(glob.glob(f"{ROOT}/{cell}/RNAseq/*.tsv")):
        acc = os.path.basename(f)[:-4]
        if acc in EXCLUDE:
            print(f"  SKIP {acc}")
            continue
        name = f"{cell}_{acc}"
        df = pd.read_csv(f, sep="\t", usecols=["gene_id", COUNT_COL],
                         dtype={"gene_id": str})
        df = df[df["gene_id"].str.startswith("ENSG")]
        df = df[~df["gene_id"].str.contains("PAR_Y")]
        df["gene_id"] = df["gene_id"].str.split(".").str[0]
        df = df.groupby("gene_id", as_index=False)[COUNT_COL].sum()
        series[name] = df.set_index("gene_id")[COUNT_COL]
        design.append({"sample": name, "condition": cell})
        print(f"  {name}: {len(df)} genes")

mat = pd.DataFrame(series)
print(f"\nunion:        {len(mat)} genes across {mat.shape[1]} samples")
mat = mat.dropna()
print(f"intersection: {len(mat)} genes")
mat = mat.round(0).astype(int)
mat.index.name = "gene_id"
mat.to_csv(f"{OUTD}/counts.csv")
pd.DataFrame(design).to_csv(f"{OUTD}/design.csv", index=False)

d = pd.DataFrame(design)
print("\n" + d.groupby("condition").size().to_string())
print(f"\nwrote {OUTD}/counts.csv and design.csv")
