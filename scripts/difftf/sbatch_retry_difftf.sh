#!/bin/bash

set -u

SBATCH_BIN="/cm/shared/apps/slurm/current/bin/sbatch"
SQUEUE_BIN="/cm/shared/apps/slurm/current/bin/squeue"

MAX_ATTEMPTS=5
ATTEMPT=1
LAST_STATUS=1

JOBSCRIPT="${!#}"
JOBNAME=$(basename -- "$JOBSCRIPT")

ERRFILE=$(mktemp)
trap 'rm -f "$ERRFILE"' EXIT

while [ "$ATTEMPT" -le "$MAX_ATTEMPTS" ]; do
    : > "$ERRFILE"

    OUTPUT=$("$SBATCH_BIN" "$@" 2>"$ERRFILE")
    LAST_STATUS=$?

    if [ "$LAST_STATUS" -eq 0 ]; then
        if [ -s "$ERRFILE" ]; then
            cat "$ERRFILE" >&2
        fi
        printf '%s\n' "$OUTPUT"
        exit 0
    fi

    MESSAGE=$(cat "$ERRFILE")

    if ! grep -qE \
        'Unexpected message received|Socket timed out|Unable to contact slurm controller' \
        "$ERRFILE"
    then
        printf '%s\n' "$MESSAGE" >&2
        exit "$LAST_STATUS"
    fi

    # If Slurm accepted the job but lost the response, recover its job ID.
    EXISTING=$(
        "$SQUEUE_BIN" -h -u "$USER" -n "$JOBNAME" -o '%A' 2>/dev/null |
        head -1
    )

    if [[ "$EXISTING" =~ ^[0-9]+$ ]]; then
        echo "WARNING: recovered submitted job $EXISTING after transient sbatch response failure" >&2
        printf '%s\n' "$EXISTING"
        exit 0
    fi

    if [ "$ATTEMPT" -eq "$MAX_ATTEMPTS" ]; then
        echo "ERROR: sbatch failed after $MAX_ATTEMPTS attempts" >&2
        printf '%s\n' "$MESSAGE" >&2
        exit "$LAST_STATUS"
    fi

    DELAY=$((ATTEMPT * 5))
    echo "WARNING: transient sbatch failure on attempt $ATTEMPT; retrying in ${DELAY}s" >&2
    printf '%s\n' "$MESSAGE" >&2

    sleep "$DELAY"
    ATTEMPT=$((ATTEMPT + 1))
done

exit "$LAST_STATUS"
