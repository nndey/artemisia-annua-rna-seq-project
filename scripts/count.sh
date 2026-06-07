#!/usr/bin/env bash
# scripts/count.sh
# ==============================================================================
# Merge all per-sample Salmon quant.sf files into one counts matrix CSV.
#
# WHY: Salmon produces one quant.sf file per sample. DESeq2 (and most
# downstream tools) expect a single matrix with genes as rows and samples
# as columns. This script does that merge using an inline Python one-liner.
# 
# Output: counts/counts_matrix.csv
#   Rows    = transcript/gene names
#   Columns = one per sample (named by sample ID)
#   Values  = NumReads (estimated read counts from Salmon)
#
# Note: For production DESeq2 analysis, use tximport or tximeta in R,
# which applies proper length-bias correction when importing Salmon output.
# This script produces a quick inspection-ready CSV.
#
# Arguments (passed by run_pipeline.sh):
#   $1  SALMON_DIR  : directory containing per-sample Salmon output (salmon_quant/)
#   $2  COUNTS_DIR  : output directory for the merged matrix (counts/)
# ==============================================================================

set -euo pipefail

SALMON_DIR="$1"
COUNTS_DIR="$2"

# Call Python inline to do the merge.
# Bash is not well-suited for tabular data manipulation — Python with pandas
# is the right tool here. We pass the directory paths as variables into
# the Python heredoc using shell variable expansion.
python3 << EOF
import glob
import pandas as pd

# glob.glob findas all quant.sf files across all sample subdirectories.
# The * wildcard matches any sample directory name.
# sorted() ensures consistent column ordering across runs.
files = sorted(glob.glob("${SALMON_DIR}/*/quant.sf"))

if not files:
    raise FileNotFoundError("No quant.sf files found in ${SALMON_DIR}/")

dfs = []
for f in files:
    # Extract the sample ID from the path.
    # e.g. "salmon_quant/ctrl_1/quant.sf".split("/") = ["salmon_quant", "ctrl_1", "quant.sf"]

    # [-2] gets the second-to-last element = "ctrl_1"
    sample_id = f.split("/")[-2]

    # Read the quant.sf file (tab-separated) and keep only NumReads.
    # index_col="Name" sets the transcript/gene name as the row index.
    df = pd.read_csv(f, sep="\t", index_col="Name")[["NumReads"]]

    # Rename the NumReads column to the sample ID so columns are labelled.
    df = df.rename(columns={"NumReads": sample_id})
    dfs.append(df)

# pd.concat joins all per-sample DataFrames side by side (axis=1 = columns).
# Transcripts that appear in all files will align automatically by index.
counts_matrix = pd.concat(dfs, axis=1)

output_path = "${COUNTS_DIR}/counts_matrix.csv"
counts_matrix.to_csv(output_path)
print(f"Counts matrix written to {output_path} ({counts_matrix.shape[0]} genes x {counts_matrix.shape[1]} samples)")
EOF

echo "[count] done"