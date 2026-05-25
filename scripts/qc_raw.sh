#!/bin/env bash
# scripts/qc_raw.sh
# ==============================================================================
# Run FastQC on raw (untrimmed) FASTQ files.
# 
# WHY: Establishes a quality baseline before trimming so you can compre
# raw vs trimmed reports in MultiQC. Shows adapter contamination, per-base
# quality, duplication levels, and GC content.
#
# Arguments (passed by run_pipeline.sh):
#   $1   SID     : sample ID
#   $2   R1      : path to raw R1 FASTQ file
#   $3   R2      : path to raw R2 FASTQ file
#   $4   OUT_DIR : output directory (qc_reports/fastqc_raw/)
#   $5   THREADS : number of CPU threads to use
#   $6   FASTQC  : path or name of the fastqc executable
# ==============================================================================

set -euo pipefail

SID="$1"
R1="$2"
R2="$3"
OUT_DIR="$4"
THREADS="$5"
FASTQC="$6"

mkdir -p "$OUT_DIR"

# Run FastQC on both R1 and R2 in one command.
# FastQC generates one HTML report and one .zip archive per input file.
#
#  --outdir   : where to write the reports
#  --threads  : FastQC can process multiple files in parallel;
#               pass both files and set threads=2 to process them simultaneously
"$FASTQC" "$R1" "$R2" \
    --outdir "$OUT_DIR" \
    --threads "$THREADS"

echo "[qc_raw] ${SID} done"
