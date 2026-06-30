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
#   $4    STAR_INDEX   : path to pre-built STAR genome index directory
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
STAR_QUANT_MODE="${10}"
STAR="${11}"

# Each sample gets its own subdirectory because STAR writes multiple output
# files (BAM, logs, splice junction table, etc.).
SAMPLE_OUT="${OUT_DIR}/${SID}/"
mkdir -p "$SAMPLE_OUT"

R1="${TRIMMED_DIR}/${SID}_R1_trimmed.fastq.gz"
R2="${TRIMMED_DIR}/${SID}_R2_trimmed.fastq.gz"


# --sjdbGTFfile: the annotation file used to guide splice-aware alignment.
# STAR uses gene models to identify known splice junctions,
# improving alignment accuracy at exon boundaries.

# zcat decompresses .fastq.gz files on the fly.
# Without this, STAR would try to read the compressed bytes literally.

# "BAM SortedByCoordinate": output a coordinate-sorted BAM.
# This genomic BAM is used by downstream tools that need genome
# coordinates (MultiQC, IGV, etc.) — NOT by salmon. Salmon consumes
# the separate Aligned.toTranscriptome.out.bam produced via
# --quantMode TranscriptomeSAM below, which is transcript-coordinate
# and grouped by read name, not coordinate-sorted.

# Extra fields in each BAM record:
#   NH = number of genomic locations the read maps to
#   HI = which alignment this is (for multi-mappers)
#   AS = alignment score
#   NM = number of mismatches

# All STAR output files will be named e.g.:
#   alignment/<SID>/Aligned.sortedByCoord.out.bam
#   alignment/<SID>/Log.final.out   ← alignment summary (MultiQC reads this)

"$STAR" \
    --runThreadN "$THREADS" \
    --genomeDir "$STAR_INDEX" \
    --sjdbGTFfile "$GTF" \
    --readFilesIn "$R1" "$R2" \
    --readFilesCommand zcat \
    --outSAMtype $SAM_TYPE \
    --outSAMattributes $SAM_ATTR \
    --genomeLoad "$GENOME_LOAD" \
    --quantMode "$STAR_QUANT_MODE" \
    --outFileNamePrefix "$SAMPLE_OUT"

echo "[align] ${SID} done"