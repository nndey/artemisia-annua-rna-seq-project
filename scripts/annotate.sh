#!/usr/bin/env bash
# scripts/annotate.sh
# ==============================================================================
# Generate functional annotation (GO terms, KEGG pathways, orthology) for the
# A. annua reference genome using eggNOG-mapper.
#
# WHY: The A. annua genome (GCA_003112345.1) is a GenBank-only assembly with
# no functional annotation — no GO terms, no KEGG mappings, nothing beyond
# structural gene models (coordinates, exon/CDS structure). Downstream
# enrichment analysis (GO/KEGG) requires a gene-to-term mapping that doesn't
# exist for this species in public databases like g:Profiler. eggNOG-mapper
# assigns functional annotation to any species' protein sequences via
# orthology-based transfer from the eggNOG database, independent of whether
# the organism has dedicated database support anywhere else.
#
# This is a one-time reference-annotation step, not a per-sample step — it
# runs once against the whole proteome, not once per SRA sample. Requires
# scripts/setup_annotation.sh to have been run first.
#
# IDEMPOTENT: both the protein extraction and the eggNOG-mapper run check
# for their expected output first and skip if already present. This matters
# because eggNOG-mapper against ~26,750 proteins takes hours, and this step
# has no --steps filter protection against being re-triggered by a normal
# no-filter `bash run_pipeline.sh` call.
#
# Output: an eggNOG-mapper .emapper.annotations TSV file at
# <ANNOTATION_DIR>/artemisia_annotation.emapper.annotations
# This file is parsed downstream to build the gene-to-GO mapping used by
# the enrichment analysis notebook (enrichment_analysis.qmd).
#
# Arguments (passed by run_pipeline.sh):
#   $1    REF_GENOME    : path to reference genome FASTA (.fna)
#   $2    REF_GTF       : path to genome annotation GTF file
#   $3    PROTEIN_FASTA : path to extracted protein FASTA (.faa) output path
#   $4    ANNOTATION_DIR: output directory for eggNOG-mapper results
#   $5    EGGNOG_DB_DIR : path to the local eggNOG-mapper database directory
#   $6    THREADS       : number of CPU threads
#   $7    GFFREAD       : path or name of the gffread executable
#   $8    EMAPPER       : path or name of the emapper.py executable
# ==============================================================================

set -euo pipefail

REF_GENOME="$1"
REF_GTF="$2"
PROTEIN_FASTA="$3"
ANNOTATION_DIR="$4"
EGGNOG_DB_DIR="$5"
THREADS="$6"
GFFREAD="$7"
EMAPPER="$8"

REF_GENOME="$(realpath "${REF_GENOME}")"
REF_GTF="$(realpath "${REF_GTF}")"
PROTEIN_FASTA="$(realpath "${PROTEIN_FASTA}")"
ANNOTATION_DIR="$(realpath "${ANNOTATION_DIR}")"
EGGNOG_DB_DIR="$(realpath "${EGGNOG_DB_DIR}")"

mkdir -p "${ANNOTATION_DIR}"

# ---- Extract protein sequences (skip if already done) ----
if [[ -s "${PROTEIN_FASTA}" ]]; then
    echo "Protein FASTA already exists, skipping extraction: ${PROTEIN_FASTA}"
    echo "  ($(grep -c '>' "${PROTEIN_FASTA}") proteins)"
else
    "${GFFREAD}" -y "${PROTEIN_FASTA}" -g "${REF_GENOME}" "${REF_GTF}"
    echo "Protein sequences extracted: $(grep -c '>' "${PROTEIN_FASTA}") proteins"
fi

# ---- Run eggNOG-mapper (skip if already done) ----
ANNOTATION_OUTPUT="${ANNOTATION_DIR}/artemisia_annotation.emapper.annotations"

if [[ -s "${ANNOTATION_OUTPUT}" ]]; then
    echo "eggNOG-mapper annotation already exists, skipping: ${ANNOTATION_OUTPUT}"
else
    "${EMAPPER}" \
      -i "${PROTEIN_FASTA}" \
      --itype proteins \
      -o artemisia_annotation \
      --output_dir "${ANNOTATION_DIR}" \
      --data_dir "${EGGNOG_DB_DIR}" \
      --cpu "${THREADS}"

    echo "eggNOG-mapper annotation complete: ${ANNOTATION_OUTPUT}"
fi