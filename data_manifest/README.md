# ENCODE Input Data Manifest

This directory documents the public ENCODE inputs used for the K562-versus-MCF7 transcription-factor activity benchmark.

## Input summary

The benchmark used 38 ENCODE files:

| Data type | K562 | MCF7 | Total |
|---|---:|---:|---:|
| DNase-seq peak files | 5 | 5 | 10 |
| DNase-seq BAM alignments | 5 | 5 | 10 |
| RNA-seq gene quantifications | 14 | 4 | 18 |
| **Total** | **24** | **14** | **38** |

The selected DNase-seq peak and alignment files use the GRCh38 human genome assembly. The assembly of all ten peak files was confirmed directly through their ENCODE file records.

## Manifest

`encode_input_manifest.tsv` records:

- Cell line and assay
- Role of each input file
- ENCODE file and experiment accessions
- File format and reference information
- Pipelines that used each input
- Direct ENCODE source links
- Relevant processing notes

## Pipeline usage

- **TF-Prioritizer:** DNase-seq peaks, DNase-seq alignments, and RNA-seq counts
- **nf-core/tfactivity:** DNase-seq peaks and RNA-seq counts
- **diffTF basic mode:** DNase-seq peaks and DNase-seq alignments

## Accession naming

The original ENCODE BAM and peak files have different file accessions. They are connected through their shared ENCODE experiment accessions.

For pipeline organization, local BAM filenames and sample identifiers were associated with the corresponding peak sample identifiers. The manifest retains the original ENCODE file accessions so that the source files can be identified and downloaded correctly.

## Data storage

The genomic input files are too large for this GitHub repository and are not included. They can be obtained from ENCODE using the source links in the manifest.

The sample sheets in `../samplesheets/` document how these inputs were organized for the benchmark.
