# Reproducibility and Path Configuration

## Computing environment

The benchmark was run on the Expanse high-performance computing system at the San Diego Supercomputer Center. The submitted scripts use the Slurm workload manager.

Before reuse, the paths and Slurm settings should be adjusted for the target computing environment.

## Path placeholders

Personal and system-specific paths were removed from the archived scripts, configurations, and sample sheets. They were replaced with the following placeholders:

| Placeholder | Meaning |
|---|---|
| `__PROJECT_DIR__` | Repository and project-support directory |
| `__SCRATCH_PROJECT_DIR__` | Large input-data, reference-data, work, and result directory |
| `__MINIFORGE_DIR__` | Miniforge installation directory |

Replace these placeholders before executing the scripts.

For example:

```text
__PROJECT_DIR__          → /path/to/TF_Benchmark
__SCRATCH_PROJECT_DIR__  → /path/to/scratch/TF_Benchmark
__MINIFORGE_DIR__        → /path/to/miniforge3
```

## Data availability

Large genomic inputs, reference files, workflow work directories, containers, and complete output directories are not stored in this GitHub repository.

The `data_manifest` directory documents the original data sources and accession numbers. The `samplesheets` directory records the input organization used for the benchmark.

## Software environments

The exact diffTF Conda package specification is provided in:

```text
environments/difftf_conda_explicit.txt
```

Additional software versions and pipeline commit identifiers are documented separately.
