import csv
import os
import re
from collections import defaultdict

INPUT_FILES = {
    "K562": "metadata/ChIP/K562_all_metadata.tsv",
    "MCF7": "metadata/ChIP/MCF7_all_metadata.tsv"
}

OUTPUT_DIR = "metadata/ChIP"


def parse_version(analysis_title):
    match = re.search(
        r"ENCODE4 v(\d+)\.(\d+)\.(\d+)",
        analysis_title
    )

    if not match:
        return None

    return tuple(int(value) for value in match.groups())


def clean_target(target):
    target = target.strip()
    target = re.sub(
        r"-human$",
        "",
        target,
        flags=re.IGNORECASE
    )

    if not target:
        return "Unknown_target"

    return target


def normalize_biosample_name(name):
    name = name.strip().upper()

    # Remove spaces, hyphens, and underscores so:
    # MCF-7 -> MCF7
    # MCF_7 -> MCF7
    # K562  -> K562
    name = re.sub(r"[\s_-]+", "", name)

    return name


os.makedirs(OUTPUT_DIR, exist_ok=True)

for cell_line, input_file in INPUT_FILES.items():

    if not os.path.isfile(input_file):
        raise FileNotFoundError(
            "Missing input file: " + input_file
        )

    matching_rows = []

    with open(
        input_file,
        "r",
        encoding="utf-8",
        newline=""
    ) as handle:

        reader = csv.DictReader(
            handle,
            delimiter="\t"
        )

        fieldnames = reader.fieldnames

        if fieldnames is None:
            raise ValueError(
                "No header found in: " + input_file
            )

        normalized_cell_line = normalize_biosample_name(
            cell_line
        )

        for row in reader:

            file_format = row.get(
                "File format",
                ""
            ).strip().lower()

            assembly = row.get(
                "File assembly",
                ""
            ).strip()

            output_type = row.get(
                "Output type",
                ""
            ).strip().lower()

            file_status = row.get(
                "File Status",
                ""
            ).strip().lower()

            analysis_title = row.get(
                "File analysis title",
                ""
            ).strip()

            biosample = normalize_biosample_name(
                row.get(
                    "Biosample term name",
                    ""
                )
            )

            download_url = row.get(
                "File download URL",
                ""
            ).strip()

            if file_format != "bam":
                continue

            if assembly != "GRCh38":
                continue

            if output_type != "unfiltered alignments":
                continue

            if file_status != "released":
                continue

            if not analysis_title.startswith("ENCODE4"):
                continue

            if biosample != normalized_cell_line:
                continue

            if not download_url:
                continue

            version = parse_version(
                analysis_title
            )

            if version is None:
                continue

            row["_target_clean"] = clean_target(
                row.get(
                    "Experiment target",
                    ""
                )
            )

            row["_version_tuple"] = version

            matching_rows.append(row)

    rows_by_target = defaultdict(list)

    for row in matching_rows:
        target = row["_target_clean"]
        rows_by_target[target].append(row)

    selected_rows = []

    for target, rows in rows_by_target.items():

        newest_version = max(
            row["_version_tuple"]
            for row in rows
        )

        target_rows = [
            row
            for row in rows
            if row["_version_tuple"] == newest_version
        ]

        selected_rows.extend(target_rows)

    selected_rows.sort(
        key=lambda row: (
            row["_target_clean"],
            row.get(
                "Biological replicate(s)",
                ""
            ),
            row.get(
                "File accession",
                ""
            )
        )
    )

    output_tsv = os.path.join(
        OUTPUT_DIR,
        cell_line
        + "_ENCODE4_newest_per_target_"
        + "GRCh38_unfiltered_released_bams.tsv"
    )

    output_urls = os.path.join(
        OUTPUT_DIR,
        cell_line
        + "_ENCODE4_newest_per_target_"
        + "GRCh38_unfiltered_released_bam_urls.txt"
    )

    with open(
        output_tsv,
        "w",
        encoding="utf-8",
        newline=""
    ) as handle:

        writer = csv.DictWriter(
            handle,
            fieldnames=fieldnames,
            delimiter="\t",
            extrasaction="ignore"
        )

        writer.writeheader()

        for row in selected_rows:
            writer.writerow(row)

    with open(
        output_urls,
        "w",
        encoding="utf-8"
    ) as handle:

        for row in selected_rows:
            url = row.get(
                "File download URL",
                ""
            ).strip()

            if url:
                handle.write(url + "\n")

    print()
    print("=" * 70)
    print(cell_line)
    print("=" * 70)

    if not rows_by_target:
        print("No matching BAM files found.")

    for target in sorted(rows_by_target):

        newest_version = max(
            row["_version_tuple"]
            for row in rows_by_target[target]
        )

        target_rows = [
            row
            for row in rows_by_target[target]
            if row["_version_tuple"] == newest_version
        ]

        version_text = ".".join(
            str(value)
            for value in newest_version
        )

        print(
            target
            + ": "
            + str(len(target_rows))
            + " BAMs kept from ENCODE4 v"
            + version_text
        )

    print()
    print(
        "Total BAMs kept: "
        + str(len(selected_rows))
    )

    print(
        "Metadata: "
        + output_tsv
    )

    print(
        "URLs: "
        + output_urls
    )
