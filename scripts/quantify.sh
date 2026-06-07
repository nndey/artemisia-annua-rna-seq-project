#!/usr/bin/env bash
# scripts/quantify.sh
# ==============================================================================
# Quantify transcript expression with Salmon in alignment-based mode.
#
# WHY: Salmon takes the BAM from STAR and the reference transcriptome to
# estimate how many reads came from each transcript. It outputs: 
#   quant.sf       : transcript-level counts and TPM
#   quant.genes.sf : gene-level aggregates (when --geneMap is provided)
#
# We use alignment-based mode (--alignments) rather than Salmon's own
# mapping, so the alignments stay consistent with STAR's output.
#
# TPM (Transcripts Per Million): length- and depth-normalized expression.
#   Good for comparing expression levels within a sample.
# NumReads: estimated read count per transcript.
#   Used by DESeq2 for differential expression analysis.
# Arguments (passed by run_pipeline.sh):
#   $1  SID            : sample ID
#   $2  ALIGMENT_DIR   : directory containing STAR BAM files (alignment/)
#   $3  OUT_DIR        : output directory (salmon_quant/)
#   $4  TRANSCRIPTOME  : path to reference transcriptome FASTA
#   $5  GTF            : path to GTF annotation (for gene-level aggregation)
#   $6  LIB_TYPE       : Salmon library type (A = auto-detect)
#   $7  THREADS        : number of CPU threads
#   $8  SALMON         : path or name of the Salmon executable
# ==============================================================================

set -euo pipefail 

SID="$1"
ALIGNMENT_DIR="$2"
OUT_DIR="$3"
TRANSCRIPTOME="$4"
GTF="$5"
LIB_TYPE="$6"
THREADS="$7"
SALMON="$8"

# STAR always names it BAM "Aligned.sortedByCoord.out.bam" inside the sample dir.
BAM="${ALIGNMENT_DIR}/${SID}/Aligned.sortedByCoord.out.bam"
SAMPLE_OUT="${OUT_DIR}/${SID}"

mkdir -p "$SAMPLE_OUT"

"$SALMON" quant \
    --alignments "$BAM" \
    # Tell Salmon to use our pre-computer STAR alignments instead of
    # performing its own mapping. Keeps alignments consistent.
    --targets "$TRANSCRIPTOME" \
    # The reference transcriptome FASTA — Salmon needs transcript sequences
    # to estimate effective lengths and correct for sequence bias.
    --libType "$LIB_TYPE" \
    # "A" = auto-detect strand orientation from the data.
    # Salmon examines a subset of reads to determine whether the library
    # is stranded (and in which direction) or unstranded.
    --geneMap "$GTF" \
    # Maps transcript IDs to gene IDs so Salmon can also output
    # gene-level aggregates in quant.genes.sf.
    --threads "$THREADS" \
    --validateMappings \
    # Extra consistency check: verifies that aligned reads are compatible
    # with the transcriptome sequences. Recommended in alignment-based mode.
    --output "$SAMPLE_OUT"
    # Salmon writes quant.sf, quant.genes.sf, logs, and aux files here.

echo "[quantify] ${SID} done"