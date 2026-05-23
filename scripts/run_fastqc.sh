#!/bin/bash
set -euo pipefail
set -x

SECONDS=0

# set temporary environment variables for the session
PROJECT_DIR="$HOME/artemisia-annua-rna-seq-project"
DATA_DIR="$PROJECT_DIR/raw_data"
FASTQ_DIR="$PROJECT_DIR/qc_reports"

cd $DATA_DIR

# STEP 1: Run FastQC on all raw FASTQ files
fastqc "$DATA_DIR"/*.fastq -o "$FASTQ_DIR/fastqc_raw" -t 16

# View directory of raw fastqc outputs
ls -la "$FASTQ_DIR/fastqc_raw/"

# STEP 2: Quality Trimming with fastp
# Define sample IDs (B3, B1, B2, RL2, RL3, WL1, WL2, WL3, RL1)
SAMPLES="SRR6808226 SRR6808227 SRR6808228 SRR6808229 SRR6808230 SRR6808231 SRR6808232 SRR6808239 SRR6808240"

# Process each sample
for SAMPLE in $SAMPLES;
do
  R1="$DATA_DIR/${SAMPLE}_1.fastq"
  R2="$DATA_DIR/${SAMPLE}_2.fastq"
  
  fastp \
      --in1 $R1 \
      --in2 $R2 \
      --out1 "$PROJECT_DIR/trimmed_data/${SAMPLE}_1.trimmed.fastq" \
      --out2 "$PROJECT_DIR/trimmed_data/${SAMPLE}_2.trimmed.fastq" \
      --qualified_quality_phred 20 \
      --length_required 36 \
      --detect_adapter_for_pe \
      --overrepresentation_analysis \
      --thread 16 \
      --json "$FASTQ_DIR/fastp/${SAMPLE}.json" \
      --html "$FASTQ_DIR/fastp/${SAMPLE}.html" \
      2>> "$PROJECT_DIR/logs/fastp.log"
      
done

# View output of fastqc trimmed output
ls -lh "$PROJECT_DIR/trimmed_data/"

# Compare file sizes before and after trimming
echo "=== Raw vs Trimmed File Sizes ==="
ls -lh "$DATA_DIR"/*_1.fastq
ls -lh "$PROJECT_DIR/trimmed_data"/*_1.trimmed.fastq

# Get read counts before and after
seqkit stats "$DATA_DIR"/*_1.fastq "$PROJECT_DIR/trimmed_data"/*_1.trimmed.fastq

# STEP 3: Run FastQC on trimmed data
fastqc "$PROJECT_DIR/trimmed_data"/*.fastq -o "$FASTQ_DIR/fastqc_trimmed" -t 16

echo "Compare a sample's fastqc reports before and after trimming"

echo "Browse the HTML reports"

# STEP 4: Generate MultiQC reports
# Generate a comprehensive report with all QC data
multiqc "$FASTQ_DIR" -o "$FASTQ_DIR" -n multiqc_all --force

duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
