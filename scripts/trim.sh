#!/usr/bin/env bash
# scripts/trim.sh
# ==============================================================================
# Quality-trim reads and remove adapters with fastp.
#
# WHY: Raw reads contain low-quality bases (especially at 3' ends) and
# Illumina adapter sequences from short fragments. These degrade alignment
# accuracy and introduce noise into expresssion estimates. fastp removes them.
#
# fastp also generates a QC report (JSON + HTML) that MultiQC will read later
# to summarize trimming statistics across all samples.
# 
# Arguments (passed run_pipeline.sh):
#   $1   SID           : sample ID
#   $2   R1            : path to raw R1 FASTQ
#   $3   R2            : path to raw R2 FASTQ
#   $4   OUT_DIR       : output directory for trimmed reads (trimmed_data/)
#   $5   QC_DIR        : output directory for fastp QC reports (qc_reports/fastp/)
#   $6   THREADS       : number of CPU threads
#   $7   MIN_LEN       : discard reads shorter than this after trimming
#   $8   QUAL          : minimum Phred quality score for a base to be "qualified"
#   $9   UNQUAL_PCT    : discard read if more than this % of bases are unqualified
#   $10  FASTP         : path or name of the fastp executable
# ==============================================================================

set -euo pipefail
SID="$1"
R1="$2"
R2="$3"
OUT_DIR="$4"
QC_DIR="$5"
THREADS="$6"
MIN_LEN="$7"
QUAL="$8"
UNQUAL_PCT="$9"
FASTP="${10}"
# Note: arguments beyond $9 must use ${10}, ${11} etc. — the braces are required.

mkdir -p "$OUT_DIR" "$QC_DIR"

"$FASTP" \
      --in1 "$R1" \
      --in2 "$R2" \
      --out1 "${OUT_DIR}/${SID}_R1_trimmed.fastq.gz" \
      --out2 "${OUT_DIR}/${SID}_R2_trimmed.fastq.gz" \
      --json "${QC_DIR}/${SID}_fastp.json" \
      --html "${QC_DIR}/${SID}_fastp.html" \
      --length_required "$MIN_LEN" \
      --qualified_quality_phred "$QUAL" \
      --unqualified_percent_limit "$UNQUAL_PCT" \
      --thread "$THREADS" \
      --overrepresentation_analysis \
      --detect_adapter_for_pe
      # --detect_adapter_for_pe:  fastp automatically identifies and removes
      # Illumina adapter sequences for paired-end data.
      # No need to provide adapter sequences manually.

echo "[trim] ${SID} done"