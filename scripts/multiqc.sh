#!/usr/bin/env bash
# scripts/multiqc.sh
# ==============================================================================
# Aggregate all QC reports into a single interactive HTML report with MultiQC.
#
# WHY: By this point QC outputs are scattered across multiple directories:
#   - FastQC reports (raw and trimmed)
#   - fastp JSON reports
#   - STAR alignment log files
#   - Salmon quantification logs
# MultiQC scans all of them and produces one browser-viewable report where
# you can compare all samples side-by-side. This is typically the first thing
# a collaborator or reviewer will look at to assess data quality.
#
# Arguments (passed by run_pipeline.sh):
#   $1  QC_RAW_DIR      : FastQC reports on raw reads
#   $2  QC_TRIMMED_DIR  : FastQC reports on trimmed reads
#   $3  QC_FASTP_DIR    : fastp JSON reports
#   $4  ALIGNMENT_DIR   : STAR output directory (MultiQC finds Log.final.out files)
#   $5  SALMON_DIR      : Salmon output directory (MultiQC finds logs here)
#   $6  RESULTS_TABLES  : results/tables/ — used to derive results/multiqc/ output path
#   $7  MULTIQC         : path or name of the multiqc executable
# ==============================================================================


set -euo pipefail

QC_RAW_DIR="$1"
QC_TRIMMED_DIR="$2"
QC_FASTP_DIR="$3"
ALIGNMENT_DIR="$4"
SALMON_DIR="$5"
RESULTS_TABLES="$6"
MULTIQC="$7"

# Derive the MultiQC output directory from RESULTS_TABLES.
# dirname strips the last path component:
#   dirname "results/tables" → "results"
# Then we append /multiqc to get "results/multiqc".
RESULTS_DIR=$(dirname "$RESULTS_TABLES")
OUT_DIR="${RESULTS_DIR}/multiqc"

mkdir -p "$OUT_DIR"

"$MULTIQC" \
    "$QC_RAW_DIR" \
    "$QC_TRIMMED_DIR" \
    "$QC_FASTP_DIR" \
    "$ALIGNMENT_DIR" \
    "$SALMON_DIR" \
    # MultiQC recursively searches each directory for files it recognizes.
    # It knows the output formats of FastQC, fastp, STAR, Salmon, and 100+
    # other bioinformatics tools — no configuration needed.
    --outdir "$OUT_DIR" \
    --force
    # --force: overwrite any existing MultiQC report.
    # Without this flag, MultiQC exits with an error if the output already exists.


echo "[multiqc] report written to ${OUT_DIR}"