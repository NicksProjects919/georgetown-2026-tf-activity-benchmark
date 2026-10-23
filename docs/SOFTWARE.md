# Software and Pipeline Versions

## Computing environment

The benchmark was run on the Expanse high-performance computing system at the San Diego Supercomputer Center using the Slurm workload manager.

## nf-core/tfactivity

| Item | Version or identifier |
|---|---|
| Pipeline | nf-core/tfactivity |
| Pipeline version | 0.0.1dev |
| Source commit | `4ac627e7439087a4a8be3dfe7bcb6f6ed55a3d1d` |
| Executed script revision | `c94a29f43d` |
| Nextflow | 26.04.4, build 12445 |
| Execution profile | Singularity |
| Successful run | July 29–30, 2026 |

The workflow-generated component versions are preserved in
`environments/tfactivity_software_versions.yml`.

The report-generation compatibility change is documented in
`patches/tfactivity_report_nan_compatibility.patch`.

## TF-Prioritizer

| Item | Version or identifier |
|---|---|
| Source repository | `https://github.com/biomedbigdata/TF-Prioritizer` |
| Container source | `docker://nicotru/tf-prioritizer:master` |
| Container source revision | `73b6b2f2d87281649d363199121a061be8a77678` |
| Container runtime | SingularityPRO 4.1.2 |
| Local SIF SHA256 | `5e084e38c0cb88603834dcc6ace6ece65a1e648d4b9aa20953b409d2c51ae193` |

The large Singularity image is not stored in this repository.

## diffTF

| Item | Version or identifier |
|---|---|
| Source commit | `44a3c04b61933f48420c785e8905ce1fbe02dcf3` |
| Source description | `v1.9-1-g44a3c04` |
| Snakemake | 7.32.4 |
| R | 4.5.3 |
| DiffBind | 3.20.0 |
| DESeq2 | 1.50.2 |
| readr | 2.2.0 |

The complete Conda package specification is preserved in
`environments/difftf_conda_explicit.txt`.

The source compatibility changes are documented in
`patches/difftf_modern_software_compatibility.patch`.

## Reuse notes

Pipeline source code and large container images are not duplicated here.
The repository instead preserves source revisions, configurations,
execution scripts, environment specifications, and compatibility patches.
