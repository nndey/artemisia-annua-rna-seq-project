#!/usr/bin/env bash
# ==============================================================================
# get_fastq_files.sh — Get sample files used in Zhang et al. 2018 study
# ==============================================================================
# This script downloads all of the FASTQ sample files used in the 
# Zhang et al. 2018 study. 
#
# Run this ONCE before using the pipeline for the first time.
#
# Prerequisites:
#   - sra-tools must already be installed
#   - Run from the root of the project directory
# Usage:
#   bash scripts/get_fastq_files.sh                  # downloads FASTQ samples to raw_data/
#                                              directory
# ==============================================================================

set -euo pipefail 
source config.sh


# ------------------------------------------------------------------------------
# Loop through the SRA Database for all samples used in Zhang et al. 2018 study 
# ------------------------------------------------------------------------------

function LoopSRA
{
m=${#SraNumbers[@]}
for (( i=0; i<m; i++))
do
  echo "Currently downloading: ${SraNumbers[$i]}"
  prefetch --output-directory "${SRA_DIR}" "${SraNumbers[$i]}" --progress
done
}

# ------------------------------------------------------------------------------
# Download FASTQ files for all samples used in Zhang et al. 2018 study
# Adaptated from Erick Lu (https://erilu.github.io/python-fastq-downloader/)
# 
# Loop will download the .sra files to ~/raw_data/sra_downloads/
# ------------------------------------------------------------------------------

function LoopFASTQ
{
m=${#SraNumbers[@]}
for (( i=0; i<m; i++))
do
  echo "Generating fastq for: ${SraNumbers[$i]}"
  fasterq-dump \
    --outdir "${RAW_DIR}" \
    --threads "${FASTERQ_THREADS}" \
    --mem "${FASTERQ_MEM}" \
    --split-files \
    --progress \
    "${SRA_DIR}/${SraNumbers[$i]}/${SraNumbers[$i]}.sra"
done
}

# ------------------------------------------------------------------------------
# Create bash array with SRA sample IDs used in Zhang et al. 2018 study
# As a reference, SRA IDs correspond to the following sample conditions: 
# B3, B1, B2, RL2, RL3, WL1, WL2, WL3, RL3
# ------------------------------------------------------------------------------

SraNumbers=(SRR6808226 SRR6808227 SRR6808228 SRR6808229 SRR6808230 SRR6808231 SRR6808232 SRR6808239 SRR6808240)

LoopSRA ${SraNumbers[@]}


# ------------------------------------------------------------------------------
# Extract the .sra files from above into the designated output directory
# ------------------------------------------------------------------------------

LoopFASTQ ${SraNumbers[@]}


echo "All sample FASTQ files have been downloaded."


