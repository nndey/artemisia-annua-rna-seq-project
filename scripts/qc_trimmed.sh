#!/usr/bin/env bash
# scripts/qc_trimmed.sh
# ==============================================================================
# Run FastQC on trimmed FASTQ files.
#
# WHY: Re-running FastQC after trimming lets you confirm that:
#   - Adapter sequences have been removed
#   - Per-base quality scores have improved
#   - Read length distribution looks appropriate
# MultiQC will display raw vs trimmed FastQC reports side-by-side.
#
# Arguments (passed by run_pipeline.sh):
#   $1  SID          : sample ID
#   $2  TRIMMED_DIR  : directory containing trimmed FASTQ files (trimmed_data/)
#   $3  OUT_DIR      : output directory (qc_reports/fastqc_trimmed/)
#   $4  THREADS      : number of CPU threads
#   $5  FASTQC       : path or name of the fastqc executable
# ==============================================================================

set -euo pipefail

SID="$1"
TRIMMED_DIR="$2"
OUT_DIR="$3"
THREADS="$4"
FASTQC="$5"

mkdir -p "$OUT_DIR"

# Build paths to the trimmed files produced by trim.sh.
# These filenames must match the --out1 / --out2 values used in trim.sh exactly.
R1="${TRIMMED_DIR/${SID}_R1_trimmed.fastq.gz"}
R2="${TRIMMED_DIR/${SID}_R2_trimmed.fastq.gz"}

"$FASTQC" "$R1" "$R2" \
    --outdir "$OUT_DIR" \
    --threads "$THREADS"

echo "[qc_trimmed] ${SID} done"

