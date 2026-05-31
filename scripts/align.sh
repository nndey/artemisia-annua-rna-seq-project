#!/usr/bin/env bash
# scripts/align.sh
# ==============================================================================
# Align trimmed reads to the reference genome with STAR.
#
# WHY: We need to know where in the genome each read came from.
# STAR handles reads that span exon-exon splice junctions, which is
# critical for RNA-seq data derived from processed mRNA (which lacks introns).
#
# Output: a sorted BAM file at alignment/<SID>/Aligned.sortedByCoord.out.bam
# This BAM is passed to Salmon in the quantify step.
#
# Arguments (passed by run_pipeline.sh):
#   $1    SID          : sample ID
#   $2    TRIMMED_DIR  : directory containing trimmed FASTQ files
#   $3    OUT_DIR      : output directory (alignment/)
#   $4    STAR_INDEX   : path to pre-built STAR genome index
#   $5    GTF          : path to genome annotation GTF file
#   $6    THREADS      : number of CPU threads
#   $7    SAM_TYPE     : STAR --outSAMtype value (e.g. "BAM SortedByCoordinate")
#   $8    SAM_ATTR     : STAR --outSAMattributes value (e.g. "NH HI AS NM")
#   $9    GENOME_LOAD  : STAR --genomeLoad value (e.g. NoSharedMemory)
#   $10   STAR         : path or name of the STAR executable
# ==============================================================================

set -euo pipefail

SID="$1"
TRIMMED_DIR="$2"
OUT_DIR="$3"
STAR_INDEX="$4"
GTF="$5"
THREADS="$6"
SAM_TYPE="$7"
SAM_ATTR="$8"
GENOME_LOAD="$9"
STAR="${10}"

# Each sample gets its own subdirectory because STAR writes multiple output
# files (BAM, logs, splice junction table, etc.).
SAMPLE_OUT="${OUT_DIR}/${SID}/"
mkdir -p "$SAMPLE_OUT"

R1="${TRIMMED_DIR}/${SID}_R1.trimmed.fastq.gz"
R2="${TRIMMED_DIR}/${SID}_R2.trimmed.fastq.gz"

"$STAR" \
    --runThreadN "$THREADS" \
    --genomeDir "$STAR_INDEX" \
    --sjdbGTFfile "$GTF" \
    # --sjdbGTFfile: the annotation file used to guide splice-aware alignment.
    # STAR uses gene models to identify known splice junctions,
    # improving alignment accuracy at exon boundaries.
    --readFilesIn "$R1" "$R2" \
    --readFilesCommand zcat \
    # zcat decompresses .fastq.gz files on the fly.
    # Without this, STAR would try to read the compressed bytes literally.
    --outSAMtype $SAM_TYPE \
    # "BAM SoredByCoordinate": output a coordinate-sorted BAM.
    # Sorted BAMs are required by Salmon and most downstream tools
    # Note: no quotes around $SAM_TYPE — it contains a space that STAR
    # needs to see as two separate tokens (BAM and SortedByCoordinate).
    --outSAMattributes $SAM_ATTR \
    # Extra fields in each BAM record:
    #   NH = number of genomic locations the read maps to
    #   HI = which alignment this is (for multi-mappers)
    #   AS = alignment score
    #   NM = number of mismatches
    --genomeLoad "$GENOME_LOAD" \
    --outFileNamePrefix "$SAMPLE_OUT"
    # All STAR output files will be named e.g.:
    #   alignment/<SID>/Aligned.sortedByCoord.out.bam
    #   alignment/<SID>/Log.final.out   ← alignment summary (MultiQC reads this)

echo "[align] ${SID} done"