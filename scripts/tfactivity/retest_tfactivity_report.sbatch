#!/bin/bash
#SBATCH --job-name=tfact_report_retest
#SBATCH --partition=shared
#SBATCH --account=gtw109
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=00:20:00
#SBATCH --output=__PROJECT_DIR__/logs/tfact_report_retest_%j.out
#SBATCH --export=ALL

set -euo pipefail
source ~/TF_Benchmark/env.sh

TESTDIR="$SCRATCH_PROJ/report_build_test_52621722"
ASSETS="$TESTDIR/build/src/assets"
CONTAINER="$SCRATCH_PROJ/containers/tfactivity/community-cr-prod.seqera.io-docker-registry-v2-blobs-sha256-43-43c7b329cc3c4ce5ea033e750aec1caeb43f7129636993e346fd522a6d68bb84-data.img"

find "$ASSETS" -type f -name "*.json" -exec sed -i \
  -e 's/: NaN/: null/g' \
  -e 's/: -Infinity/: null/g' \
  -e 's/: Infinity/: null/g' {} +

singularity exec --bind "$SCRATCH_PROJ" "$CONTAINER" bash -lc '
    cd "$1/build"
    export HOME="$1/temp"
    npm run build
' _ "$TESTDIR"

test -s "$TESTDIR/build/dist/index.html"
echo "REPORT BUILD TEST: PASS"
