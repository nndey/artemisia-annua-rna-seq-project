#!/bin/bash

# code reference (https://bioinfo-kaust.github.io/academy-stage3-2026/html/lab1.html)

SECONDS=0
# change working directory
WORK_DIR="$HOME/artemisia-annua-rna-seq-project"
REF_DIR="$WORK_DIR/reference"

cd $REF_DIR

# STEP 1: Download reference genome
echo "Downloading reference genome..."
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/003/112/345/GCA_003112345.1_ASM311234v1/GCA_003112345.1_ASM311234v1_genomic.fna.gz
gunzip GCA_003112345.1_ASM311234v1_genomic.fna.gz

# STEP 2: Download reference genome annotation
echo "Downloading reference genome annotation..."
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/003/112/345/GCA_003112345.1_ASM311234v1/GCA_003112345.1_ASM311234v1_genomic.gtf.gz
gunzip GCA_003112345.1_ASM311234v1_genomic.gtf.gz

# STEP 3: Download reference transcriptome
echo "Downloading transcriptome..."
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/003/112/345/GCA_003112345.1_ASM311234v1/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna.gz
gunzip GCA_003112345.1_ASM311234v1_rna_from_genomic.fna.gz

duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
