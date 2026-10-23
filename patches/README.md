# Pipeline Compatibility Patches

These patches record compatibility changes required to complete the benchmark on Expanse.

## nf-core/tfactivity report patch

**Patch:** `tfactivity_report_nan_compatibility.patch`

**Base commit:** `4ac627e7439087a4a8be3dfe7bcb6f6ed55a3d1d`

The report generator produced invalid JSON values such as `NaN` and `Infinity`.
This patch converts those values to `null` before the HTML report is created.
It affects report generation only and does not change the TF calculations.

Apply the patch from the tfactivity source directory with:

```bash
git apply /path/to/tfactivity_report_nan_compatibility.patch
```

## diffTF compatibility patch

**Patch:** `difftf_modern_software_compatibility.patch`

**Base commit:** `44a3c04b61933f48420c785e8905ce1fbe02dcf3`

**Source description:** `v1.9-1-g44a3c04`

This patch records two compatibility changes:

1. It replaces the deprecated `path` argument with `file` in eight `readr::write_tsv()` calls.

2. It supplies explicit sample peak indices to `DiffBind::dba.peakset()`.
The original implicit behavior produced an empty consensus peak set with DiffBind 3.20.0.

Apply the patch from the diffTF source directory with:

```bash
git apply /path/to/difftf_modern_software_compatibility.patch
```

These patches were created for the source revisions listed above and should be reviewed before use with other versions.
