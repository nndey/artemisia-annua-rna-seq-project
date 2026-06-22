#!/bin/bin/env bash
# ==============================================================================
# get_reference_genome.sh — Get reference genome used in Zhang et al. 2018 study
# ==============================================================================
# This script downloads the reference genome, reference transcriptome, and
# genome annotation used in the Zhang et al. 2018 study.
#
# Run this ONCE before using the pipeline for the first time. 
#
# Prerequisites: 
#   - Run from the root of the project directory
# Usage:
#   bash scripts/get_reference_genome.sh             # donwloads reference data to the 
#                                              reference/ directory
#
# Code Source: (https://bioinfo-kaust.github.io/academy-stage3-2026/html/lab1.html)
# ==============================================================================

set -euo pipefail
source config.sh

# ------------------------------------------------------------------------------
# Change working directory
# ------------------------------------------------------------------------------

cd $REF_DIR

# ------------------------------------------------------------------------------
# STEP 1: Download reference genome
# ------------------------------------------------------------------------------

echo "Downloading reference genome..."
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/003/112/345/GCA_003112345.1_ASM311234v1/GCA_003112345.1_ASM311234v1_genomic.fna.gz
gunzip GCA_003112345.1_ASM311234v1_genomic.fna.gz

# ------------------------------------------------------------------------------
# STEP 2: Download reference genome annotation
# ------------------------------------------------------------------------------

echo "Downloading reference genome annotation..."
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/003/112/345/GCA_003112345.1_ASM311234v1/GCA_003112345.1_ASM311234v1_genomic.gtf.gz
gunzip GCA_003112345.1_ASM311234v1_genomic.gtf.gz

# ------------------------------------------------------------------------------
# STEP 3: Download reference transcriptome
# ------------------------------------------------------------------------------

echo "Downloading transcriptome..."
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/003/112/345/GCA_003112345.1_ASM311234v1/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna.gz
gunzip GCA_003112345.1_ASM311234v1_rna_from_genomic.fna.gz


echo "All reference data has been downloaded."