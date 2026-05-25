#!/usr/bin/env bash
# scripts/subsample.sh
# =============================================================================
# Subsample a fixed number of reads from raw FASTQ files using seqtk.
# 
# WHY: Full datasets can be 30M+ reds. Subsampling to 1M reads lets you
# develop and test the pipeline ~30x faster. Skip this step in production.
#
# Arguments (passed by run_pipeline.sh):
#   $1  SID          : sample ID (e.g. ctrl_1)
#   $2  R1           : path to raw R1 FASTQ file
#   $3  R2           : path to raw R2 FASTQ file
#   $4  OUT_DIR      : output directory (subsampled_data/)
#   $5  N_READS      : number of reads to subsample (e.g. 1000000)
# =============================================================================

set -euo pipefail

# Assign positional arguments to named variables for readability
# In bash, $1 $2 $3... are the arguments passed to the script.
# Naming them makes the code self-documenting.
SID="$1"
R1="$2"
R2="$3"
OUT_DIR="$4"
N_READS="$5"

# Create the output directory if it doesn't exist.
# -p: create parent directories too; no error if it already exists.
mkdir -p "$OUT_DIR"

# Process R1 and R2 in a loop to avoid duplicating code.
# The loop iterates twice: once for R1 input/output, once for R2.
for read_tag in R1 R2; do

    # Choose which input file to use based on the current loop iteration.
    # In bash, if/elif/else blocks work like this:
    #   if [[ condition ]]; then ... elif [[ condition ]]; then ... fi
    if [[ "$read_tag" == "R1" ]]; then
        INPUT="$R1"
    else
        INPUT="$R2"
    fi

    OUTPUT="${OUT_DIR}/${SID}_${read_tag}.fastq.gz"

    # seqtk sample: randomly subsample reads from a FASTQ file.
    #   -s42     : random seed. Using a fixed seed (42 is conventional)
    #              means the same reads are always selected — reproducible.
    #   $INPUT   : input FASTQ file (can be gzipped)
    #   $N_READS : how many reads to keep
    #
    # | gzip : pipe seqtk's uncompressed output through gzip to compress it.
    # >       : redirect compressed output to the output file.
    seqtk sample -s42 "$INPUT" "$N_READS" | gzip > "$OUTPUT"

done

echo "[subsample] ${SID} done"