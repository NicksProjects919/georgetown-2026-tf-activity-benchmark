#!/bin/bash
#SBATCH --job-name=tfprio_rgt
#SBATCH --account=gtw109
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=00:30:00
#SBATCH --output=__PROJECT_DIR__/logs/tfprio_rgt_%j.out
#SBATCH --error=__PROJECT_DIR__/logs/tfprio_rgt_%j.err
#SBATCH --export=ALL

set -euo pipefail

source __PROJECT_DIR__/env.sh
module load singularitypro/4.1.2

IMAGE="$SCRATCH_PROJ/containers/TF-Prioritizer/tf-prioritizer_master.sif"
DEP_ROOT="$SCRATCH_PROJ/dependencies/TF-Prioritizer"
FINAL="$DEP_ROOT/rgtdata"
BUILD="$DEP_ROOT/rgtdata.build_${SLURM_JOB_ID}"

FASTA="$SCRATCH_PROJ/references/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna"
GTF="$SCRATCH_PROJ/references/GENCODE_v29/gencode.v29.annotation.gtf"

if [ -e "$FINAL" ]; then
    echo "STOP: final RGT directory already exists: $FINAL"
    exit 1
fi

mkdir -p "$BUILD"

singularity exec --cleanenv \
  --bind "$SCRATCH_PROJ:$SCRATCH_PROJ" \
  "$IMAGE" \
  cp -a /srv/dependencies/rgtdata/. "$BUILD/"

mv "$BUILD/setupGenomicData.py" \
   "$BUILD/setupGenomicData.original.py"

cat > "$BUILD/setupGenomicData.py" <<'PY'
#!/usr/bin/env python3
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parent
args = sys.argv[1:]

if args == ["--hg38"]:
    required = [
        root / "hg38/genome_hg38.fa",
        root / "hg38/genome_hg38.fa.fai",
        root / "hg38/gencode.v21.annotation.gtf",
        root / "hg38/chrom.sizes.hg38",
    ]
    missing = [str(path) for path in required if not path.exists()]
    if missing:
        raise SystemExit("Missing staged hg38 files:\n" + "\n".join(missing))
    print("Using pre-staged hg38 FASTA, index, and GTF")
    raise SystemExit(0)

original = root / "setupGenomicData.original.py"
subprocess.run([sys.executable, str(original), *args], check=True)
PY

chmod u+x "$BUILD/setupGenomicData.py"

ln -s "$FASTA" "$BUILD/hg38/genome_hg38.fa"
ln -s "$FASTA.fai" "$BUILD/hg38/genome_hg38.fa.fai"
ln -s "$GTF" "$BUILD/hg38/gencode.v21.annotation.gtf"

mv "$BUILD" "$FINAL"

echo "Created writable RGT data: $FINAL"
readlink -f "$FINAL/hg38/genome_hg38.fa"
readlink -f "$FINAL/hg38/gencode.v21.annotation.gtf"
python3 "$FINAL/setupGenomicData.py" --hg38
