#!/usr/bin/env bash
# scripts/build_star_index.sh
# ==============================================================================
# Build STAR genome index from reference genome.
#
# WHY: Creates a reference file at which STAR program can easily
# parse and align samples to. 
#
# Output: a sorted IDX file at reference/star_index
# This IDX is passed to STAR in the align step.
#
# Arguments (passed by run_pipeline.sh):
#   $1    STAR_INDEX     : path to pre-built STAR genome index
#   $2    REF_GENOME     : path to reference genome FASTA
#   $3    GTF            : path to genome annotation GTF file
#   $4    THREADS        : number of CPU threads
#   $5    SJDB_OVERHANG  : length(bases) of the SA pre-indexing string
#                          Ideally its read-length - 1. 
#   $6    SA_INDEX_BASES : length of the donor/acceptor sequence
#                          on each side of the junctions
#                          Calculate min(14, log2(GenomeLength) / 2 - 1)
#   $7    STAR           : path or name of the STAR executable
# ==============================================================================
set -euo pipefail

STAR_INDEX="$1"
REF_GENOME="$2"
GTF="$3"
THREADS="$4"
SJDB_OVERHANG="$5"
SA_INDEX_BASES="$6"
STAR="$7"

mkdir -p "$STAR_INDEX"

# Build STAR index for reference genome
"$STAR" --runMode genomeGenerate \
    --runThreadN "$THREADS" \
    --genomeDir "$STAR_INDEX" \
    --genomeFastaFiles "$REF_GENOME" \
    --sjdbGTFfile "$GTF" \
    --sjdbOverhang "$SJDB_OVERHANG" \
    --genomeSAindexNbases "$SA_INDEX_BASES"

echo "[build_star_index] done"