#!/bin/bash

# code reference (https://bioinfo-kaust.github.io/academy-stage3-2026/html/lab1.html)

SECONDS=0

# change working directory
WORK_DIR="$HOME/artemisia-annua-rna-seq-project"
REF_DIR="$WORK_DIR/reference"

cd $REF_DIR

# extract and map transcript to gene sequences

awk -F'\t' '$3=="transcript" {
  if (match($9, /gene_id "[^"]+/)) {
    gene = substr($9, RSTART, RLENGTH)
    sub(/^gene_id "/, "", gene)
    sub(/"$/, "", gene)
  }
  if (match($9, /transcript_id "[^"]+"/)) {
    tx = substr($9, RSTART, RLENGTH)
    sub(/^transcript_id "/, "", tx)
    sub(/"$/, "", tx)
  }
  if (gene && tx) print tx "\t" gene
}' GCA_003112345.1_ASM311234v1_genomic.gtf > tx2gene.tsv

# add header
printf "transcript_id\tgene_id\n" | cat - tx2gene.tsv > tmp && mv tmp tx2gene.tsv

# view first few lines
head tx2gene.tsv
wc -l tx2gene.tsv

duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."

