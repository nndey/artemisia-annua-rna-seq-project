#!/usr/bin/env Rscript
# =============================================================================
# scripts/deseq2.R
# Run differential expression analysis using DESeq2
# Analysis code borrowed from KAUST Academy 
# (https://bioinfo-kaust.github.io/academy-stage3-2026/html/lab5.html)
#
# WHY:
# Identify differentially expressed genes between control and treatments
# Understand the impact of different light conditions on gene expression
#
# INPUTS:
# - counts/tximport_object.rds       — the tximport object with gene counts
# - samples.csv                      — sample metadata with conditions
#
# OUTPUTS:
# - deseq2_results.csv          — table of DESeq2 results (log2FC, p-value)
# - deseq2_results.rds          — the full DESeq2 object for downstream analysis
# - deseq2_summary.txt          — summary of DESeq2 results (number of DE
#   genes, top hits, etc.)
#
# Usage (called by run_pipeline.sh):
#   Rscript scripts/deseq2.R \
#    --rds           counts/tximport_object.rds \
#    --samples_csv   samples.csv \
#    --output_dir    results/
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
#   option   : the flag name (e.g. "--samples_dir")
#   type     : expected data type ("character", "integer", "double")
#   default  : value used if the flag is not provided (NULL = required)
#   help     : description shown when --help is run
option_list <- list(

    make_option("--rds",
        type    = "character",
        default = NULL,
        help    = "Directory containing tximport object with gene counts" 
    ),

    make_option("--samples_csv",
        type    = "character",
        default = NULL,
        help    = "Path to samples.csv with columns: sample_id, condition, r1, r2" 
    ),

    make_option("--output_dir",
        type    = "character",
        default = "results/",
        help    = "Output directory for deseq2 results"
    )
)

# parse_args() reads the actual command-line arguments and matches them
# to the option_list definitions above.
# OptionParser() builds the parser object from the option list.
opt <- parse_args(OptionParser(option_list = option_list))

# Validate that all required arguments were provided.
# We stop() with a message if any are missing — stop() is R's way of
# exiting with an error, equivalent to 'echo "ERROR..." & exit 1' in bash.
if (is.null(opt$rds)) stop("--rds is required")
if (is.null(opt$samples_csv)) stop("--samples_csv is required")
if (is.null(opt$output_dir)) stop("--output_dir is required")


# =============================================================================
# SECTION 2: LOAD LIBRARIES
# All libraries needed for this script are loaded here, after argument
# parsing — this way we still get the --help message even if a library
# is missiong, rather than a cryptic "package not found" error first.
# =============================================================================

suppressPackageStartupMessages({
    library(DESeq2)      # performs differential gene expression analysis
    library(tximport)    # loads and reads tximport object
    library(tidyverse)   # string manipulation
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

log_msg("Starting DESeq2 analysis")
log_msg(paste("Tximport object :",  opt$rds))
log_msg(paste("Samples CSV      :", opt$samples_csv))
log_msg(paste("Output directory :", opt$output_dir))


# =============================================================================
# SECTION 4: LOAD DATA
# Read tximport object and load sample metadata.
# =============================================================================

log_msg("Loading tximport object and sample metadata...")

# read_csv() reads a CSV file into a tibble (tidyverse data frame).
# A tibble is like a regular R data.frame but prints more cleanly.
txi <- readRDS(opt$rds)
sample_info <- read.csv(opt$samples_csv, header = TRUE, sep = ",") %>%
    column_to_rownames("sample_id")

# Set factor levels (white light as reference)
sample_info$condition <- factor(
    sample_info$condition, 
    levels=c("white", "red", "far_red", "blue")
)

# =============================================================================
# SECTION 5: CREATE DESEQ2 DATASET AND PRE-FILTER
# Generate a dataset using the tximport counts data and sample metadata
#
# WHY: Consolidates counts data and sample metadata for ease
# in differential gene expression analysis
# =============================================================================

log_msg("Creating DESeq2 dataset...")

# creates a DESeq2 dataset object from tximport data
dds <- DESeqDataSetFromTximport(
    txi, 
    colData = sample_info,   # samples.csv becomes the metadata
    design = ~condition      # 'condition' is a column in samples.csv
)

# NOTE: condition is the grouping variable DESeq2 uses for differential
# expression models. replicate is a useful metadata to have. r1 and r2
# are ignored by DESeq2, it only cares about non-path columns
# Batch correction or additional covariates like ~ batch + condition,
# should be added as columns to samples.csv before running 
# DESeq2 analysis. 

# Pre-filtering: Remove genes with very low counts
keep <- rowSums(counts(dds) >= 10) >= 3
dds <- dds[keep, ]
cat(paste0("Genes after filtering (>=10 counts in >=3 samples): ", nrow(dds), "\n"))


# =============================================================================
# SECTION 6: RUN DESeq2
# Get results from differential gene expression analysis
# =============================================================================

log_msg("Running DESeq2...")

# Begin running DESeq on the DESeq dataset object
dds <- DESeq(dds)

# --- Obtain results from desired comparisons ---

# White versus red
res_wl_vs_red     <- results(
    dds, contrast = c("condition", "red", "white"), 
    name = "condition_white_vs_red"
)
res_wl_vs_red     <- res_wl_vs_red[order(res_wl_vs_red$padj), ]

# White versus blue
res_wl_vs_blue    <- results(
    dds,
    contrast = c("condition", "blue", "white"),
    name = "condition_white_vs_blue"
)
res_wl_vs_blue    <- res_wl_vs_blue[order(res_wl_vs_blue$padj), ]

# White versus far-red
res_wl_vs_far_red <- results(
    dds,
    contrast = c("condition", "far_red", "white"),
    name = "condition_white_vs_far_red"
)
res_wl_vs_far_red <- res_wl_vs_far_red[order(res_wl_vs_far_red$padj), ]

# Place results into a list
comparison_list <- list(res_wl_vs_red, res_wl_vs_blue, res_wl_vs_far_red)

# Log and save significance results
for (i in comparison_list) {
    # Significant: padj < 0.05 and |log2FC| > 1
    sig_genes <- subset(i, padj < 0.05 & abs(log2FoldChange) > 1)
    sig_genes <- sig_genes[order(sig_genes$padj), ]

    sig_res <- as.data.frame(sig_genes)
    sig_res$gene_id <- rownames(sig_res)
    sig_res <- sig_res[, c("gene_id", "baseMean", "log2FoldChange", "lfcSE", "stat", "pvalue", "padj")]
    write.csv(
        sig_res,
        glue("{opt$output_dir}/tables/deseq2_significant_{i$name}.csv"),
        row.names = FALSE
    )

    cat(paste0("Total significant genes: ", nrow(sig_genes), "\n"))
    cat(paste0("Upregulated in ",  str_extract(i$name, "_*$"), ":", sum(sig_genes$log2FoldChange > 0, na.rm = TRUE), "\n"))
    cat(paste0("Downregulated in ",str_extract(i$name, "_*$"), ":", sum(sig_genes$log2FoldChange < 0, na.rm = TRUE), "\n"))
}

# =============================================================================
# SECTION 7: SAVE RESULTS
# =============================================================================

log_msg("Saving outputs...")

# All results
for (i in comparison_list) {
    all_res <- as.data.frame(i)
    all_res$gene_id <- rownames(all_res)
    all_res <- all_res[, c("gene_id", "baseMean", "log2FoldChange", "lfcSE", "stat", "pvalue", "padj")]
    write.csv(
        all_res,
        glue("{opt$output_dir}/tables/deseq2_all_results_{i$name}.csv"), 
        row.names = FALSE
    )
}
log_msg(paste("Results saved to:", glue("{opt$output_dir}/tables")))

# Normalized counts
norm_counts <- as.data.frame(counts(dds, normalized = TRUE))
norm_counts$gene_id <- rownames(norm_counts)
write.csv(
    norm_counts,
    glue("{opt$output_dir}/tables/normalized_counts.csv"),
    row.names = FALSE
)
log_msg(paste("Normalized counts saved to:", glue("{opt$output_dir}/tables")))

# Save DESeq2 object for later use
saveRDS(dds, glue("{opt$output_dir}/deseq2_object.rds"))
log_msg(paste("dds object saved to:", opt$output_dir))


# =============================================================================
# SECTION 8: SUMMARY
# Print a summary so the log shows key numbers at a glance.
# =============================================================================

n_genes   <- nrow(txi$counts)
n_samples <- nrow(sample_info)

summary_text <- paste0(
    "=== DESeq2 import summary ===\n",
    "Samples        : ", n_samples,    "\n",
    "Genes          : ", n_genes,  "\n",
    "Conditions : ",
        paste(levels(sample_info$condition),
        collapse = " vs "), "\n",
    "========================\n"
)

cat(summary_text)

# Save the summary to a text file for the log record.
summary_path <- file.path(opt$output_dir, "deseq2_import_summary.txt")
writeLines(summary_text, summary_path)

log_msg("DESeq2 complete.")