import csv
import os

inputs = {
    "K562": "metadata/ChIP/K562_all_metadata.tsv",
    "MCF7": "metadata/ChIP/MCF7_all_metadata.tsv"
}

for cell_line, input_path in inputs.items():

    output_tsv = (
        "metadata/ChIP/"
        + cell_line
        + "_ENCODE4_GRCh38_unfiltered_released_bams.tsv"
    )

    output_urls = (
        "metadata/ChIP/"
        + cell_line
        + "_ENCODE4_GRCh38_unfiltered_released_bam_urls.txt"
    )

    with open(input_path, "r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        rows = list(reader)
        fieldnames = reader.fieldnames

    selected = []

    for row in rows:
        biosample = row["Biosample term name"].strip().lower()
        normalized_biosample = biosample.replace("-", "")
        normalized_cell_line = cell_line.lower().replace("-", "")

        if (
            row["File format"].strip().lower() == "bam"
            and row["File assembly"].strip().lower() == "grch38"
            and row["File Status"].strip().lower() == "released"
            and row["File analysis title"].strip().lower().startswith("encode4")
            and row["Output type"].strip().lower() == "unfiltered alignments"
            and normalized_cell_line in normalized_biosample
        ):
            selected.append(row)

    with open(output_tsv, "w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=fieldnames,
            delimiter="\t"
        )
        writer.writeheader()
        writer.writerows(selected)

    with open(output_urls, "w", encoding="utf-8") as handle:
        for row in selected:
            handle.write(row["File download URL"].strip() + "\n")

    print(cell_line + ": " + str(len(selected)) + " BAMs")
    print("Metadata: " + output_tsv)
    print("URLs: " + output_urls)
    print()
