# Practical Pipeline Comparison

This document summarizes the observed practical differences among
nf-core/tfactivity, TF-Prioritizer, and diffTF during the K562-versus-MCF7
DNase-seq benchmark on Expanse.

## Runtime and storage

| Pipeline | Observed runtime | Results storage | Main output |
|---|---:|---:|---|
| nf-core/tfactivity | 17 h 45 min 54 s | 3.9 GB | Interactive HTML report and tables |
| TF-Prioritizer | 20 h 40 min 42 s | 48 GB | Interactive HTML report and tables |
| diffTF | 80 h 38 min 56 s | 9.1 GB | TSV tables and PDF plots |

nf-core/tfactivity had the shortest observed runtime and used the least
storage. TF-Prioritizer used the most storage, while diffTF had the
longest observed completion time.

## Runtime interpretation

These values describe the observed time required to obtain the completed
benchmark results; they are not controlled measurements of algorithmic
speed.

- The nf-core/tfactivity value was calculated from the timestamps in the
  successful Nextflow execution trace.
- The TF-Prioritizer value is the cumulative elapsed time of its main run
  and production resume jobs.
- The diffTF value combines the 48-hour timed-out run and its successful
  resume.

The nf-core/tfactivity value does not include its earlier unsuccessful
attempts, whereas the cumulative TF-Prioritizer and diffTF values include
time spent in incomplete production runs. The pipelines also used
different execution models and levels of parallelism. These values should
therefore be treated as descriptive records of the benchmark rather than
as controlled, directly comparable performance measurements.

## Setup and software

### nf-core/tfactivity

- Used Nextflow with Singularity containers.
- Managed individual workflow processes and their software environments.
- Required a compatibility fix for invalid `NaN` and `Infinity` values
  produced during HTML report generation.

### TF-Prioritizer

- Used a Singularity container because of its older software
  requirements.
- Required additional dependency and compatibility troubleshooting.
- Produced the largest complete results directory.

### diffTF

- Used Snakemake, R, and a dedicated Conda environment.
- Required compatibility changes for current versions of readr and
  DiffBind.
- Required preprocessing of one mixed-layout BAM file.

## Failures and recovery

### nf-core/tfactivity

Three failed workflow attempts were recorded during reference retrieval
and report generation. Nextflow's `-resume` option allowed completed
processes to be reused.

### TF-Prioritizer

Two production jobs ended without completing, including one cancelled
job and one failed resume. Existing intermediate outputs were retained
and reused in later resume jobs.

### diffTF

Two driver runs failed because of transient Slurm submission responses,
and one later run reached the 48-hour time limit. A submission-retry
wrapper was added, the workflow was unlocked after the timeout, and
Snakemake reused completed outputs during the successful resume.

## Output interpretability

TF-Prioritizer and nf-core/tfactivity produced interactive HTML reports
that made their final rankings easier to explore. diffTF produced
detailed tables and PDF plots, but its results required more manual
interpretation and TF-name standardization for comparison.

## Overall practical result

Based on the recorded values, nf-core/tfactivity had the most favorable
practical profile: the shortest listed runtime, the least storage use,
and structured restart behavior through Nextflow. TF-Prioritizer produced
an accessible interactive report but required more storage and
compatibility work. diffTF provided an independent statistical analysis
but required the most computation time and more manual result
interpretation.
