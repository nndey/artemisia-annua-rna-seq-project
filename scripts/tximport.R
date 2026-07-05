#!/usr/bin/env Rscript
# =============================================================================
# scripts/tximport.R
# Aggregate Salmon transcript-level counts to gene level using tximport.
# Output is a gene-level counts matrix ready for DESeq2.
# =============================================================================
#
# WHY THIS STEP EXISTS:
# count.sh produces counts/counts_matrix.csv — a transcript-level matrix
# merged directly from Salmon's quant.sf NumReads column. That matrix is
# useful for quick inspection but is NOT suitable for DESeq2 because:
#   1. It is at transcript level, not gene level
#   2. It has no length-bias correction across samples
#
# This script uses tximport to properly collapse transcript counts to gene
# level using a tx2gene mapping generated from the GTF annotation, and
# applies lengthScaledTPM scaling so counts are comparable across samples
# even when isoform usage differs.
#
# HOW THIS RELATES TO count.sh:
#   count.sh output  → counts/counts_matrix.csv     (transcript-level, inspection only)
#   tximport output  → counts/gene_counts_matrix.csv (gene-level, DESeq2 input)
#                   → counts/gene_tpm_matrix.csv     (gene-level TPM, visualisation)
#                   → counts/tximport_object.rds     (full object, preferred DESeq2 input)
#                   → counts/tx2gene.csv             (transcript → gene mapping)
#                   → counts/tximport_summary.txt    (run summary)
#
# All outputs share the counts/ directory with count.sh's counts_matrix.csv
# so all count-related files are in one place.
#
# WHY lengthScaledTPM:
# Different samples may have different transcript isoform usage — one sample
# might express mostly the short isoform of a gene, another the long isoform.
# Longer transcripts generate more reads for the same expression level, making
# raw counts incomparable across samples when isoform usage differs.
# lengthScaledTPM corrects for this by scaling by average transcript length
# across samples before handing off to DESeq2. This is the current
# best-practice recommendation for Salmon → DESeq2 workflows.
#
# Usage (called by run_pipeline.sh):
#   Rscript scripts/tximport.R \
#     --salmon_dir   salmon_quant/ \
#     --gtf          reference/GCA_003112345.1_ASM311234v1_genomic.gtf \
#     --samples_csv  samples.csv \
#    --samples      SRR6808226,SRR6808227 \
#     --counts_csv   counts/counts_matrix.csv \
#     --output_dir   counts/
# =============================================================================


# =============================================================================
# SECTION 1: ARGUMENT PARSING
# optparse handles command-line flags cleanly.
# R equivalent of argparse in Python / case "$1" in bash.
# =============================================================================

suppressPackageStartupMessages({
    library(optparse)
})

option_list <- list(

    make_option("--salmon_dir",
        type    = "character",
        default = NULL,
        help    = "Directory containing per-sample Salmon output (e.g. salmon_quant/)"
    ),

    make_option("--gtf",
        type    = "character",
        default = NULL,
        help    = "Path to genome annotation GTF file (e.g. references/annotation.gtf)"
    ),

    make_option("--samples_csv",
        type    = "character",
        default = NULL,
        help    = "Path to samples.csv with columns: sample_id, condition, r1, r2"
    ),

    make_option("--samples",
    type    = "character",
    default = NULL,
    help    = "Comma-separated sample IDs to process (default: all samples in samples_csv).
               Pass a subset when not all samples have been quantified yet.
               e.g. --samples SRR6808226,SRR6808227"
    ),

    make_option("--counts_csv",
        type    = "character",
        default = NULL,
        help    = "Path to counts/counts_matrix.csv produced by count.sh (used for cross-check)"
    ),

    make_option("--output_dir",
        type    = "character",
        default = "counts/",
        help    = "Output directory — same as count.sh output dir [default: counts/]"
    )
)

opt <- parse_args(OptionParser(option_list = option_list))

# Validate required arguments.
# stop() exits with an error message — equivalent to 'echo ERROR && exit 1' in bash.
if (is.null(opt$salmon_dir))   stop("--salmon_dir is required")
if (is.null(opt$gtf))          stop("--gtf is required")
if (is.null(opt$samples_csv))  stop("--samples_csv is required")
# --counts_csv is optional — cross-check runs only if it's provided


# =============================================================================
# SECTION 2: LOAD LIBRARIES
# Loaded after argument parsing so --help works even if a library is missing.
# =============================================================================

suppressPackageStartupMessages({
    library(tximport)    # aggregates Salmon transcript counts to gene level
    library(rtracklayer) # reads GTF files into R as structured GRanges objects
    library(readr)       # fast CSV/TSV reading and writing (tidyverse)
    library(dplyr)       # data manipulation: filter(), select(), distinct()
    library(tibble)      # rownames_to_column() for clean data frame handling
})


# =============================================================================
# SECTION 3: SETUP
# =============================================================================

# Create output directory if it doesn't already exist.
# recursive = TRUE is the R equivalent of mkdir -p.
# showWarnings = FALSE suppresses the warning if it already exists.
dir.create(opt$output_dir, recursive = TRUE, showWarnings = FALSE)

# Logging function — prepends a timestamp to every message.
# cat() writes to stdout without adding an extra newline like print() would.
log_msg <- function(msg) {
    cat(format(Sys.time(), "[%Y-%m-%d %H:%M:%S]"), msg, "\n")
}

log_msg("Starting tximport aggregation")
log_msg(paste("Salmon directory :", opt$salmon_dir))
log_msg(paste("GTF file         :", opt$gtf))
log_msg(paste("Samples CSV      :", opt$samples_csv))
log_msg(paste("counts_matrix.csv:", ifelse(is.null(opt$counts_csv), "(not provided — cross-check skipped)", opt$counts_csv)))
log_msg(paste("Output directory :", opt$output_dir))


# =============================================================================
# SECTION 4: LOAD SAMPLES
# Read samples.csv and locate each sample's quant.sf file.
# =============================================================================

log_msg("Loading sample manifest...")

# Load full sample manifest
samples <- read_csv(opt$samples_csv, show_col_types = FALSE)

# Filter to requested samples if --samples was provided
if (!is.null(opt$samples)) {
    requested <- trimws(strsplit(opt$samples, ",")[[1]])
    missing_requested <- setdiff(requested, samples$sample_id)
    if (length(missing_requested) > 0) {
        stop(paste("Requested samples not found in samples.csv:",
            paste(missing_requested, collapse = ", ")))
    }
    samples <- samples[samples$sample_id %in% requested, ]
    log_msg(paste("Filtering to", nrow(samples), "requested sample(s):",
        paste(samples$sample_id, collapse = ", ")))
}

# Build quant_files BEFORE the cross-check — it's needed by both
quant_files        <- file.path(opt$salmon_dir, samples$sample_id, "quant.sf")
names(quant_files) <- samples$sample_id

missing_files <- quant_files[!file.exists(quant_files)]
if (length(missing_files) > 0) {
    stop(paste(
        "Missing quant.sf files for samples:",
        paste(names(missing_files), collapse = ", "),
        "\nExpected at:\n",
        paste(missing_files, collapse = "\n")
    ))
}

log_msg(paste("Found quant.sf files for", length(quant_files), "samples:",
    paste(names(quant_files), collapse = ", ")))

# Cross-check against count.sh output — now quant_files exists
if (!is.null(opt$counts_csv)) {
    log_msg("Cross-checking against count.sh counts_matrix.csv...")
    # ... rest of cross-check block unchanged
}

# =============================================================================
# SECTION 5: CROSS-CHECK AGAINST count.sh OUTPUT (optional)
# If --counts_csv was provided, compare the sample columns in count.sh's
# counts_matrix.csv against the quant.sf files found here.
#
# WHY: count.sh and tximport.R both derive sample lists independently.
# If they disagree (e.g. a sample failed quantification so count.sh has
# fewer columns than expected) that's worth flagging before running
# tximport on a potentially incomplete dataset.
# =============================================================================

if (!is.null(opt$counts_csv)) {
    log_msg("Cross-checking against count.sh counts_matrix.csv...")

    if (!file.exists(opt$counts_csv)) {
        # Non-fatal warning — count.sh may not have run yet.
        # We warn and continue rather than stopping.
        warning(paste("counts_matrix.csv not found at:", opt$counts_csv,
            "— cross-check skipped. Run count.sh first if you want this check."))
    } else {
        # Read just the header of counts_matrix.csv to get column names.
        # n_max = 0 reads zero data rows — we only want the column names.
        counts_header <- read_csv(opt$counts_csv, n_max = 0,
                                  show_col_types = FALSE)

        # Column names from count.sh: first column is "Name" (transcript ID),
        # remaining columns are sample IDs.
        # We drop "Name" to get just the sample ID columns.
        counts_samples <- colnames(counts_header)[colnames(counts_header) != "Name"]

        # Sample IDs from quant.sf discovery above.
        tximport_samples <- names(quant_files)

        # Find samples in count.sh output that tximport can't find quant.sf for.
        only_in_counts <- setdiff(counts_samples, tximport_samples)
        # Find samples tximport found that count.sh doesn't have.
        only_in_tximport <- setdiff(tximport_samples, counts_samples)

        if (length(only_in_counts) > 0) {
            warning(paste(
                "Samples in counts_matrix.csv but no quant.sf found:",
                paste(only_in_counts, collapse = ", ")
            ))
        }
        if (length(only_in_tximport) > 0) {
            warning(paste(
                "Samples with quant.sf but missing from counts_matrix.csv:",
                paste(only_in_tximport, collapse = ", "),
                "\nRun count.sh again to regenerate counts_matrix.csv."
            ))
        }
        if (length(only_in_counts) == 0 && length(only_in_tximport) == 0) {
            log_msg(paste("Cross-check passed: both sources agree on",
                length(tximport_samples), "samples"))
        }
    }
}


# =============================================================================
# SECTION 6: BUILD TX2GENE MAPPING
# Generate a transcript ID → gene ID mapping table from the GTF annotation.
#
# WHY: count.sh merges at whatever level quant.sf uses (transcript IDs).
# tximport needs to know which transcripts belong to each gene in order
# to collapse them. The GTF annotation file contains this mapping.
#
# tx2gene format — two columns:
#   TXNAME : transcript ID — must match the 'Name' column in quant.sf exactly
#   GENEID : gene ID — what tximport collapses transcripts into
# =============================================================================

log_msg("Building tx2gene mapping from GTF...")
log_msg("(This may take a few minutes for large or fragmented GTF files)")

# import() from rtracklayer reads the GTF into a GRanges object.
# GRanges is a specialised R object for genomic intervals — each row
# is one feature (gene, transcript, exon, etc.) with start/end coordinates
# and metadata columns for attributes like transcript_id and gene_id.
gtf    <- import(opt$gtf)
gtf_df <- as.data.frame(gtf)
# as.data.frame() flattens the GRanges object into a regular R data frame
# so we can use standard dplyr operations on it.

# Filter to transcript-level rows and extract the two columns we need.
# GTF files have rows for genes, transcripts, exons, CDS, UTRs — we only
# want transcript rows, which have both transcript_id and gene_id populated.
tx2gene <- gtf_df %>%
    filter(type == "transcript") %>%
    # type is a standard GTF column — "gene", "transcript", "exon", etc.

    select(TXNAME = transcript_id, GENEID = gene_id) %>%
    # Rename columns to match what tximport expects: TXNAME and GENEID.
    # select() in dplyr can rename columns inline: new_name = old_name.

    distinct()
    # Remove duplicate rows — the same transcript_id/gene_id pair should
    # only appear once in the tx2gene table.

if (nrow(tx2gene) == 0) {
    stop(paste(
        "tx2gene table is empty after filtering the GTF.",
        "Check that your GTF has 'transcript' type rows with",
        "'transcript_id' and 'gene_id' attributes.",
        "\nTypes found in GTF:", paste(unique(gtf_df$type), collapse = ", ")
    ))
}

log_msg(paste("tx2gene built:",
    nrow(tx2gene), "transcripts →",
    length(unique(tx2gene$GENEID)), "unique genes"
))

# Save tx2gene to the counts/ directory alongside count.sh's output.
tx2gene_path <- file.path(opt$output_dir, "tx2gene.csv")
write_csv(tx2gene, tx2gene_path)
log_msg(paste("tx2gene saved:", tx2gene_path))


# =============================================================================
# SECTION 7: RUN TXIMPORT
# Collapse transcript-level Salmon counts to gene level.
# =============================================================================

log_msg("Running tximport...")

# tximport() reads all quant.sf files and collapses transcript counts to
# gene level using the tx2gene mapping.
#
# countsFromAbundance = "lengthScaledTPM" — the scaling method:
#   Step 1: Salmon estimates TPM per transcript (length-normalised abundance)
#   Step 2: tximport scales by the average transcript length across all samples
#           (not per-sample length, which would introduce unwanted variation)
#   Step 3: Multiply by library size to recover count-scale values
#   Result: counts that are comparable across samples even when isoform
#           usage differs between conditions.
#   This is the recommended method for Salmon → DESeq2 (Love et al. 2018).
#
# ignoreTxVersion = TRUE:
#   Strips version suffixes from transcript IDs before matching.
#   e.g. "AT1G01010.1" becomes "AT1G01010" for matching purposes.
#   This is a very common source of "no transcripts matched" errors,
#   especially with plant genome annotations. Leave this TRUE.
txi <- tximport(
    files               = quant_files,
    type                = "salmon",
    tx2gene             = tx2gene,
    countsFromAbundance = "lengthScaledTPM",
    # No ignoreTxVersion or ignoreAfterBar needed -
    # quant.sf and tx2gene IDs already match exactly for this assembly.
)

# tximport returns a named list with three matrices (all genes × samples):
#   txi$counts    — gene-level count matrix       → DESeq2 input
#   txi$abundance — gene-level TPM matrix         → visualisation
#   txi$length    — average transcript length     → used internally by DESeq2


# =============================================================================
# SECTION 8: SAVE OUTPUTS
# All saved to the same counts/ directory as count.sh's counts_matrix.csv
# so all count-related files are co-located.
# =============================================================================

log_msg("Saving outputs...")

# --- Gene-level counts matrix (CSV) ---
# This is the tximport equivalent of count.sh's counts_matrix.csv, but:
#   - Collapsed to gene level (count.sh is transcript level)
#   - Length-bias corrected (count.sh uses raw NumReads)
#   - Named gene_counts_matrix.csv to clearly distinguish from counts_matrix.csv
#
# rownames_to_column() moves the gene IDs from R row names into an
# explicit "gene_id" column — makes the CSV readable and unambiguous.
counts_df   <- as.data.frame(txi$counts) %>% rownames_to_column("gene_id")
counts_path <- file.path(opt$output_dir, "gene_counts_matrix.csv")
write_csv(counts_df, counts_path)
log_msg(paste("Gene counts matrix saved:", counts_path))

# --- TPM matrix (CSV) ---
# TPM values are useful for within-sample comparisons and visualisation
# (heatmaps, PCA, expression plots) but should NOT be used as DESeq2 input.
# DESeq2 requires raw-scale counts, not pre-normalised values.
tpm_df   <- as.data.frame(txi$abundance) %>% rownames_to_column("gene_id")
tpm_path <- file.path(opt$output_dir, "gene_tpm_matrix.csv")
write_csv(tpm_df, tpm_path)
log_msg(paste("TPM matrix saved:", tpm_path))

# --- Full tximport object (.rds) ---
# .rds is R's native single-object binary format.
# Saving the full txi object is preferable to the CSV alone for DESeq2
# because DESeqDataSetFromTximport() uses txi$counts, txi$abundance,
# AND txi$length together — the length matrix enables internal offset
# correction that improves differential expression accuracy.
# Load in deseq2.R with: txi <- readRDS("counts/tximport_object.rds")
rds_path <- file.path(opt$output_dir, "tximport_object.rds")
saveRDS(txi, rds_path)
log_msg(paste("tximport object (.rds) saved:", rds_path))


# =============================================================================
# SECTION 9: SUMMARY
# =============================================================================

n_genes   <- nrow(txi$counts)
n_samples <- ncol(txi$counts)

# rowSums() sums counts across all samples for each gene.
# Genes with a rowSum of 0 have zero counts in every sample.
# These will be filtered out by DESeq2 automatically, but it's useful
# to report what fraction they represent.
pct_zero <- round(sum(rowSums(txi$counts) == 0) / n_genes * 100, 1)

summary_text <- paste0(
    "=== tximport summary ===\n",
    "Genes            : ", n_genes,    "\n",
    "Samples          : ", n_samples,  "\n",
    "Genes all-zero   : ", pct_zero,   "% (filtered automatically in DESeq2)\n",
    "Scaling method   : lengthScaledTPM\n",
    "\n",
    "Outputs (in ", opt$output_dir, "):\n",
    "  gene_counts_matrix.csv  — gene-level counts for DESeq2 (CSV)\n",
    "  gene_tpm_matrix.csv     — gene-level TPM for visualisation (CSV)\n",
    "  tximport_object.rds     — full txi object (preferred DESeq2 input)\n",
    "  tx2gene.csv             — transcript → gene mapping used\n",
    "  tximport_summary.txt    — this summary\n",
    "\n",
    "Relationship to count.sh output:\n",
    "  counts_matrix.csv       — transcript-level, raw NumReads (inspection only)\n",
    "  gene_counts_matrix.csv  — gene-level, length-corrected (DESeq2 input)\n",
    "========================\n"
)

cat(summary_text)

summary_path <- file.path(opt$output_dir, "tximport_summary.txt")
writeLines(summary_text, summary_path)

log_msg("tximport complete.")