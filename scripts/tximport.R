#!/usr/bin/env Rscript
# =============================================================================
# scripts/tximport.R
# Aggregate Salmon transcript-level counts to gene level using tximport.
# Output is a counts matrix ready for DESeq2.
# =============================================================================
#
# WHY THIS STEP EXISTS:
# Salmon quantifies expression at the TRANSCRIPT level — one row per
# transcript isoform. DESeq2 works at the GENE level — one row per gene.
# A single gene can have many transcripts (isoforms), so we need to 
# collapse transcript counts up to gene level before running DESeq2.
#
# tximport does this collapse using the tx2gene mapping (transcript ID →
# gene ID), which we generate here from the GTF annotation file.
#
# WHY lengthScaledTPM:
# Different samples may have different transcript isoform usage — one sample
# might express mostly the short isoform of a gene, another mostly the long
# isoform. This makes raw counts incomparable across samples because longer
# transcripts produce more reads for the same expression level.
# lengthScaledTPM corrects for this by scaling counts by the average
# transcript length across samples before handing off to DESeq2. 
# This is the current best-practice recommendation for Salmon → DESeq2.
#
# Usage (called by run_pipeline.sh):
#   Rscript scripts/tximport.R \
#    --salmon_dir    salmon_quant/ \
#    --gtf           references/annotation.gtf \
#    --samples_csv   samples.csv \
#    --output_dir    counts/
#
# Outputs:
#   counts/gene_counts_matrix.tsv    — gene-level counts matrix (genes × samples)
#   counts/tx2gene.csv               — transcript-to-gene mapping used
#   counts/tximport_summary.txt      — summary of the import
# =============================================================================


# =============================================================================
# SECTION 1: ARGUMENT PARSING
# We use the optparse library to handle command-line arguments cleanly.
# This is the R equivalent of argparse in Python / case "$1" in bash.
# =============================================================================

# suppressPackageStartupMessages suppresses the verbose loading messages
# that R packages print on startup — keeps script output clean.
suppressPackageStartupMessages({
    library(optparse)   # command-line argument parsing
})

# Define the expected command-line flags.
# Each make_option() call defines one flag:
#   option   : the flag name (e.g. "--salmon_dir")
#   type     : expected data type ("character", "integer", "double")
#   default  : value used if the flag is not provided (NULL = required)
#   help     : description shown when --help is run
option_list <- list(

    make_option("--salmon_dir",
        type    = "character",
        default = NULL,
        help    = "Directory containing per-sample Salmon output (e.g., salmon_quant/)" 
    ),

    make_option("--gtf",
        type    = "character",
        default = NULL,
        help    = "Path to genome annotation GTF file (e.g., references/annotation.gtf)" 
    ),

    make_option("--samples_csv",
        type    = "character",
        default = NULL,
        help    = "Path to samples.csv with columns: sample_id, condition, r1, r2" 
    ),

    make_option("--output_dir",
        type    = "character",
        default = "counts/",
        help    = "Output directory for counts matrix and tx2gene file [default: counts/]" 
    )
)

# parse_args() reads the actual command-line arguments and matches them
# to the option_list definitions above.
# OptionParser() builds the parser object from the option list.
opt <- parse_args(OptionParser(option_list = option_list))

# Validate that all required arguments were provided.
# We stop() with a message if any are missing — stop() is R's way of
# exiting with an error, equivalent to 'echo "ERROR..." & exit 1' in bash.
if (is.null(opt$salmon_dir)) stop("--salmon_dir is required")
if (is.null(opt$gtf))        stop("--gtf is required")
if (is.null(opt$samples_csv)) stop("--samples_csv is required")


# =============================================================================
# SECTION 2: LOAD LIBRARIES
# All libraries needed for this script are loaded here, after argument
# parsing — this way we still get the --help message even if a library
# is missiong, rather than a cryptic "package not found" error first.
# =============================================================================

suppressPackageStartupMessages({
    library(tximport)    # aggregates Salmon transcript counts to gene level
    library(rtracklayer) # reads GTF files into R as structured objects
    library(readr)       # fast CSV reading/writing (tidyverse)
    library(dplyr)       # data manipulation (tidyverse)
})


# =============================================================================
# SECTION 3: SETUP
# Create output directory and set up a simple logging function.
# =============================================================================

# Create output directory if it doesn't exist.
# recursive = TRUE is equivalent to mkdir -p — creates parent dirs too.
dir.create(opt$output_dir, recursive = TRUE, showWarnings = FALSE)

# Simple logging function — pastes a timestamp before every message.
# format(Sys.time(), ...) formats the current time as a string.
log_msg <- function(msg) {
    cat(format(Sys.time(), "[%Y-%m-%d %H:%M:%S]"), msg, "\n")
}

log_msg("Starting tximport aggregation")
log_msg(paste("Salmon directory :", opt$salmon_dir))
log_msg(paste("GTF file         :", opt$gtf))
log_msg(paste("Samples CSV      :", opt$samples_csv))
log_msg(paste("Output directory :", opt$output_dir))


# =============================================================================
# SECTION 4: LOAD SAMPLES
# Read samples.csv and locate each sample's quant.sf file.
# =============================================================================

log_msg("Loading sample manifest...")

# read_csv() reads a CSV file into a tibble (tidyverse data frame).
# A tibble is like a regular R data.frame but prints more cleanly.
samples <- read_csv(opt$samples_csv, show_col_types = FALSE)

# Build the path to each sample's quant.sf file. 
# file.path() joins path components with the OS separator (/).
# It's safer than paste() with "/" because it handles trailing slashes correctly.
# e.g. file.path("salmon_quant", "ctrl_1", "quant.sf")
#      → "salmon_quant/ctrl_1/quant.sf"
quant_files <- file.path(opt$salmon_dir, samples$sample_id, "quant.sf")

# Name each path with its sample ID.
# tximport uses these names as the column names in its output matrix.
names(quant_files) <- samples$sample_id

# Validate that all quant.sf files actually exist before proceeding.
# file.exists() returns a logical vector (TRUE/FALSE per file).
# !file.exists() flips it — TRUE where files are MISSING.
missing <- quant_files[!file.exists(quant_files)]
if (length(missing) > 0) {
    stop(paste(
        "Missing quant.sf files for samples:",
        paste(names(missing), collapse = ", "),
        "\nExpected paths:\n",
        paste(missing, collapse = "\n")
    ))
}

log_msg(paste("Found quant.sf files for", length(quant_files), "samples"))



# =============================================================================
# SECTION 5: BUILD TX2GENE MAPPING
# Generate a transcript-to-gene mapping table from the GTF annotation file.
#
# WHY: Salmon's quant.sf files use transcript IDs as row identifiers
# (e.g. "transcript_001.1"). DESeq2 needs gene IDs (e.g. "gene_001").
# tximport needs a two-column table mapping each transcript ID to its
# parent gene ID so it knows which transcripts to collapse together.
#
# tx2gene format:
#   Column 1: TXNAME  — transcript ID (must match quant.sf Name column)
#   Column 2: GENEID  — gene ID
# =============================================================================

log_msg("Building tx2gene mapping from GTF...")
log_msg("(This may take a few minutes for large GTF files)")

# import() from rtracklayer reads the GTF file into a GRanges object —
# a structured R object representing genomic intervals with metadata.
# Each row in the GTF becomes one entry with attributes as columns.
gtf <- import(opt$gtf)

# Convert the GRanges object to a standard R data frame for easier manipulation.
# as.data.frame() flattens the GRanges structure into rows and columns.
gtf_df <- as.data.frame(gtf)

# Filter to only "transcript" rows — we only need rows that have both
# a transcript_id and a gene_id attribute.
# GTF files contain rows for genes, transcripts, exons, CDS, UTRs etc.
# We only need the transcript-level rows for tx2gene.
tx2gene <- gtf_df %>%
    # Keep only rows where 'type' column equals "transcript"
    filter(type == "transcript") %>%

    # Select only the two columns we need.
    # 'transcript_id' and 'gene_id' are standard GTF attribute fields.
    # Note: some GTF files use different field names — if this errors, 
    # check your GTF with: head -50 your_annotation.gtf
    select(TXNAME = transcript_id, GENEID = gene_id) %>%

    # Remove any duplicate rows (same transcirpt appearing twice).
    distinct()

# Validate the tx2gene table has content.
if (nrow(tx2gene) == 0) {
    stop(paste(
        "tx2gene table is empty.",
        "Check that your GTF file has 'transcript' rows with",
        "'transcript_id' and 'gene_id' attributes.",
        "\nFirst few rows of GTF:\n",
        paste(head(gtf_df$type), collapse = ", ")
    ))
}

log_msg(paste("tx2gene mapping built:",
    nrow(tx2gene), "transcripts →",
    length(unique(tx2gene$GENEID)), "genes"
))

# Save the tx2gene table to the output directory.
# This is useful for debugging and for DESeq2 annotation later.
tx2gene_path <- file.path(opt$output_dir, "tx2gene.csv")
write_csv(tx2gene, tx2gene_path)
log_msg(paste("tx2gene saved to:", tx2gene_path))


# =============================================================================
# SECTION 6: RUN TXIMPORT
# Aggregate transcript-level Salmon counts to gene level.
# =============================================================================

log_msg("Running tximport...")

# tximport() is the main function — it reads all quant.sf files and
# collapses transcript counts to gene level using the tx2gene mapping.
#
# Key arguments:
#   files                : named vector of quant.sf file paths
#   type                 : "salmon" tells tximport the file format
#   tx2gene              : the mapping table we built above
#   countsFromAbundance  : the scaling method
# 
# countsFromAbundance = "lengthScaledTPM":
#   1. Salmon estimates TPM per transcript (length-normalized abundance)
#   2. tximport scales these TPMs by the average transcript length
#      across all samples (not per-sample length)
#   3. The result is multiplied by the total library size to get counts
#   This produces counts that are comparable across samples even when 
#   isoform usage differs — the recommended input for DESeq2.
#   To change this later: swap "lengthScaledTPM" for:
#     "scaledTPM"  — simpler scaling, ignores length differences
#     "no"         — raw estimated counts, no scaling (not recommended
#                    when isoform usage varies across conditions)
#
#   ignoreTxVersion = TRUE:
#   Transcript IDs in GTF files often have version suffixes
#   (e.g. "AT1GO1010.1" vs "AT1GO1010"). This strips the version
#   number so IDs match between the GTF and quant.sf files.
#   Common source of "no matching transcripts" errors — leave this TRUE.
txi <- tximport(
    files               = quant_files,
    type                = "salmon",
    tx2gene             = tx2gene,
    countsFromAbundance = "lengthScaledTPM",
    ignoreTxVersion     = TRUE
)

# tximport returns a list with three matrices, all genes × samples:
#   txi$counts     — the gene-level count matrix (what DESeq2 uses)
#   txi$abundance  — TPM values per gene
#   txi$length     — average transcript length per gene per sample


# =============================================================================
# SECTION 7: SAVE OUTPUTS
# =============================================================================

log_msg("Saving outputs...")

# --- Gene counts matrix ---
# txi$counts is a matrix. We convert it to a data frame and add the 
# gene IDs as an explicit column (rather than row names) for easier
# downstream handling in DESeq2 and for readable TSV output.
counts_df <- as.data.frame(txi$counts) %>%
    tibble::rownames_to_column("gene_id")   # move row names to a column

counts_path <- file.path(opt$output_dir, "gene_counts_matrix.tsv")
write_tsv(counts_df, counts_path)
log_msg(paste("Gene counts matrix saved to:", counts_path))

# --- TPM matrix (useful for visualization, not for DESeq2) ---
tpm_df <- as.data.frame(txi$abundance) %>%
    tibble::rownames_to_column("gene_id")

tpm_path <- file.path(opt$output_dir, "gene_tpm_matrix.csv")
write_csv(tpm_df, tpm_path)
log_msg(paste("TPM matrix saved to:", tpm_path))

# --- Save the full tximport object as an .rds file ---
# .rds is R's native binary format for saving a single R object.
# DESeq2 can load this directly with readRDS(), which is more efficient
# than re-running tximport and avoids any rounding from the CSV.
# This is the preferred input format for DESeq2.
rds_path <- file.path(opt$output_dir, "tximport_object.rds")
saveRDS(txi, rds_path)
log_msg(paste("tximport object saved to:", rds_path))


# =============================================================================
# SECTION 8: SUMMARY
# Print a summary so the log shows key numbers at a glance.
# =============================================================================

n_genes   <- nrow(txi$counts)
n_samples <- ncol(txi$counts)

# Calculate the percentage of genes with zero counts across ALL samples.
# rowSums() sums each row (gene) across all sample columns.
# == 0 returns TRUE/FALSE, sum() counts the TRUEs, / n_genes gives %.
pct_zero <- round(sum(rowSums(txi$counts) == 0) / n_genes * 100, 1)

summary_text <- paste0(
    "=== tximport summary ===\n",
    "Genes          : ", n_genes,    "\n",
    "Samples        : ", n_samples,  "\n",
    "Genes all-zero : ", pct_zero, "%\ (will be filtered in DESeq2)\n",
    "Scaling method : lengthScaledTPM\n",
    "Outputs:\n",
    "  ", counts_path, "\n",
    "  ", tpm_path,    "\n",
    "  ", rds_path,    "\n",
    "  ", tx2gene_path, "\n",
    "========================\n"
)

cat(summary_text)

# Save the summary to a text file for the log record.
summary_path <- file.path(opt$output_dir, "tximport_summary.txt")
writeLines(summary_text, summary_path)

log_msg("tximport complete.")