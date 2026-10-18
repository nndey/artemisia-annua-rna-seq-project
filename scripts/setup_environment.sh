#!/usr/bin/env bash
# ==============================================================================
# setup_environment.sh — Create the genomics conda/mamba environment
# ==============================================================================
# This script installs all tools required to run the RNA-seq pipeline
# into a conda environment named 'genomics'.
#
# Run this ONCE before using the pipeline for the first time.
#
# Prerequisites:
#   - conda, mamba, or micromamba must already be installed
#   - Quarto must be installed separately (it is NOT part of this environment);
#     it is needed to render the notebooks in notebooks/
#   - Run from the root of the project directory
#
# Usage:
#   bash scripts/setup_environment.sh                    # auto-detects conda/mamba/micromamba
#   bash scripts/setup_environment.sh --manager mamba    # specify a package manager explicitly
#   bash scripts/setup_environment.sh --name genomics_test   # build into a scratch env to test this script
#
# Re-running on an existing environment does NOT recreate it: the create step
# is skipped and the install steps run against the existing environment.
# ==============================================================================

set -euo pipefail

ENV_NAME="genomics"
MANAGER=""   # will be auto-detected below if not passed via --manager


# ------------------------------------------------------------------------------
# Argument parsing
# ------------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
    case "$1" in
        --manager)
            MANAGER="$2"
            shift 2
            ;;
        --name)
            ENV_NAME="$2"
            shift 2
            ;;
        --help | -h)
            echo "Usage: bash scripts/setup_environment.sh [--manager conda|mamba|micromamba] [--name ENV_NAME]"

            exit 0
            ;;
        *)
            echo "ERROR: Unknown argument: $1"
            exit 1
            ;;
    esac
done

# ------------------------------------------------------------------------------
# Auto-detect package manager if not specified
# 'command -v' returns the path of a command if it exists, or fails silently.
# We prefer micromamba > mamba > conda (fastest to slowest solver).
# ------------------------------------------------------------------------------

if [[ -z "$MANAGER" ]]; then
    if command -v micromamba &> /dev/null; then
        MANAGER="micromamba"
    elif command -v mamba &> /dev/null; then
        MANAGER="mamba"
    elif command -v conda &> /dev/null; then
        MANAGER="conda"
    else
        echo "ERROR: No conda, mamba, or micromamba installation found."
        echo "Install one first: https://github.com/conda-forge/miniforge/releases/latest"
        exit 1
    fi
fi

echo "Using package manager: ${MANAGER}"


# ------------------------------------------------------------------------------
# Check if the environment already exists
# ------------------------------------------------------------------------------

# Capture the env list first, then grep it. Piping straight into 'grep -q'
# can fail under 'set -o pipefail' (grep exits early and the upstream command
# gets a broken pipe), which would wrongly report the env as missing.
# The pattern requires the name to be a whole whitespace-delimited word, so it
# won't match a path that merely contains the name.
ENV_LIST="$($MANAGER env list)"
ENV_EXISTS=false
if grep -qE "(^|[[:space:]])${ENV_NAME}([[:space:]]|$)" <<< "$ENV_LIST"; then
    ENV_EXISTS=true
fi


# ------------------------------------------------------------------------------
# Create the environment and install tools
# Source: Bioinformatics Specialization Program 2026 - KAUST Academy
# (https://bioinfo-kaust.github.io/academy-stage3-2026/html/setup.html)

# Tools are pinned to the versions used during development wherever the
# version is known. A few are left unpinned; see the comments next to them.
# Channels: bioconda (bioinformatics tools), conda-forge (dependencies)
# ------------------------------------------------------------------------------

if [[ "$ENV_EXISTS" == true ]]; then
    echo ""
    echo "Environment '${ENV_NAME}' already exists. Skipping creation."
    echo "Installing/updating packages into the existing environment."
    echo "To recreate it from scratch instead, remove it first with:"
    echo "  ${MANAGER} env remove -n ${ENV_NAME}"
    echo ""
else
    echo "Creating environment '${ENV_NAME}'..."
    echo "This may take several minutes."
    echo ""

    # --- Python ---
    $MANAGER create \
        --name "$ENV_NAME" \
        --channel bioconda \
        --channel conda-forge \
        --yes \
        python=3.11
fi

# ---- QC ----
$MANAGER install -n "$ENV_NAME" --channel bioconda --channel conda-forge --yes \
    fastqc=0.12.1 \
    fastp=1.1.0 \
    multiqc=1.33

# ---- Alignment ----
$MANAGER install -n "$ENV_NAME" --channel bioconda --channel conda-forge --yes \
    star=2.7.11b \
    samtools=1.22.1

# ---- Quantification ----
# salmon 2.1.1 (and fastp 1.1.0 above) are the versions the project's results
# were actually produced with, as read from the working environment with
# `mamba list`. An earlier version of this script pinned fastp 1.3.0 and
# salmon 1.10.3, which did not match what was installed.
$MANAGER install -n "$ENV_NAME" --channel bioconda --channel conda-forge --yes \
    salmon=2.1.1 \
    igv=2.19.7 \
    openjdk=21.0.9
# openjdk is pinned because IGV 2.19 expects a recent Java. An unpinned fresh
# install resolved to openjdk 11.0.1; the working environment has 21.0.9.

# ---- Subsampling ----
# seqkit is not used by any pipeline step; it was installed for the KAUST course labs.
$MANAGER install -n "$ENV_NAME" --channel bioconda --channel conda-forge --yes \
    seqtk=1.5.0 \
    seqkit=2.13.0

# ---- Download tools ----
$MANAGER install -n "$ENV_NAME" --channel bioconda --channel conda-forge --yes \
    sra-tools=3.2.1 \
    wget

# ---- Functional annotation ----
# Used by scripts/annotate.sh. Previously installed by setup_annotation.sh;
# now installed here so the whole environment is defined in one place.
# setup_annotation.sh only needs to download the eggNOG database.
# diamond is pinned to 2.2.2, the version eggNOG-mapper reported when the
# project's annotation was generated. An unpinned fresh install resolved to
# 2.2.8, and the search engine version can affect annotation hits.
$MANAGER install -n "$ENV_NAME" --channel bioconda --channel conda-forge --yes \
    gffread=0.12.9 \
    eggnog-mapper=2.1.13 \
    diamond=2.2.2

# ---- Python analysis libraries ----
$MANAGER install -n "$ENV_NAME" --channel bioconda --channel conda-forge --yes \
    pandas=3.0.1 \
    numpy=2.4.3 \
    matplotlib=3.10.8 \
    seaborn=0.13.2 \
    scipy=1.17.1 \
    scikit-learn=1.8.0 \
    openpyxl=3.1.5

# ---- Notebook support ----
# The original environment has ipykernel 7.3.0 (plus its Jupyter dependencies)
# installed via pip. Here it comes from conda-forge, which pulls in the same
# dependencies. The working environment has 7.3.0; a fresh conda-forge install
# resolved to 7.4.0, which is pinned here. This only affects the notebook
# kernel, not any analysis results.
$MANAGER install -n "$ENV_NAME" --channel bioconda --channel conda-forge --yes \
    ipykernel=7.4.0

# ---- R base ----
$MANAGER install -n "$ENV_NAME" --channel bioconda --channel conda-forge --yes \
    r-base=4.4.3

# ---- R analysis packages ----
# clusterProfiler is pinned to the 4.14 series (matches Bioconductor 3.20,
# the release GO.db 3.20.0 and KEGGREST 1.46.0 come from).
# GO.db, KEGGREST and knitr are used directly by the notebooks, so they are
# listed explicitly rather than relying on them arriving as dependencies.
$MANAGER install -n "$ENV_NAME" --channel bioconda --channel conda-forge --yes \
    r-tidyverse=2.0.0 \
    r-biocmanager=1.30.27 \
    bioconductor-deseq2=1.46.0 \
    bioconductor-tximport=1.34.0 \
    bioconductor-rtracklayer=1.66.0 \
    "bioconductor-clusterprofiler=4.14.*" \
    bioconductor-enrichplot=1.26.1 \
    bioconductor-go.db=3.20.0 \
    bioconductor-keggrest=1.46.0 \
    r-knitr=1.51 \
    r-pheatmap=1.0.13 \
    r-ggrepel=0.9.8 \
    r-ggplot2=4.0.2 \
    r-rcolorbrewer=1.1.3

# ---- Course leftovers (not used by the pipeline) ----
# Installed for the KAUST course labs. org.hs.eg.db is the HUMAN annotation
# package and gprofiler-official is for g:Profiler, which doesn't support
# this genome. Safe to remove if you also update scripts/check_python_libs.py
# and scripts/check_R_libs.R so they stop checking for them.
$MANAGER install -n "$ENV_NAME" --channel bioconda --channel conda-forge --yes \
    bioconductor-org.hs.eg.db=3.20.0 \
    gprofiler-official=1.0.0

# ---- Utilities ----
$MANAGER install -n "$ENV_NAME" --channel bioconda --channel conda-forge --yes \
    jq \
    yq=3.4.3 \
    tree


echo ""
echo "Environment '${ENV_NAME}' is ready."


# ------------------------------------------------------------------------------
# Verify key tools installed correctly
# ------------------------------------------------------------------------------

echo ""
echo "Verifying installations..."

# Activate the environment so we can call the tools.
# We source the shell hook for the detected manager so 'activate' works
# inside this non-interactive script.
if [[ "$MANAGER" == "micromamba" ]]; then
    eval "$(micromamba shell hook --shell bash)"
    micromamba activate "$ENV_NAME"
elif [[ "$MANAGER" == "mamba" || "$MANAGER" == "conda" ]]; then
    # shellcheck disable=SC1091
    source "$(conda info --base)/etc/profile.d/conda.sh"
    conda activate "$ENV_NAME"
fi

# Check each key tool and print its version.
# The || line ensures a failed check prints a warning instead of
# stopping the whole script (we want to check all tools, not stop at first failure).
# emapper.py is not checked here: its --version flag errors unless it is also
# given --data_dir pointing at the eggNOG database.
echo ""
printf "%-20s %s\n" "Tool" "Version"
printf "%-20s %s\n" "----" "-------"

check_tool_shell() {
    tools=("fastqc" "fastp" "STAR" "salmon" "samtools" "multiqc" "seqkit" "gffread")

    for tool in  "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
          if [[ "$tool" == "seqkit" ]]; then
            version=$($tool version 2>&1 | head -1) || version="(version check failed)"
          else
            # Run the version command and grab the first line of output.
            version=$($tool --version 2>&1 | head -1) || version="(version check failed)"
          fi
          printf "%-20s %s\n" "$tool" "$version"
        else
          printf "%-20s %s\n" "$tool" "NOT FOUND — check installation"
        fi
    done

}

check_tool_python() {
    python scripts/check_python_libs.py
}

check_tool_R() {
    Rscript scripts/check_R_libs.R
}

check_tool_shell
check_tool_python
check_tool_R



# ------------------------------------------------------------------------------
# Print activation instructions
# ------------------------------------------------------------------------------

echo ""
echo "================================================================"
echo "Setup complete."
echo ""
echo " Activate the environment before running the pipeline:"
echo ""
if [[ "$MANAGER" == "micromamba" ]]; then
    echo "   micromamba activate ${ENV_NAME}"
else
    echo "   conda activate ${ENV_NAME}   (or: mamba activate ${ENV_NAME})"
fi
echo ""
echo " Then download the eggNOG database (one-time):"
echo "   bash scripts/setup_annotation.sh reference/eggnog_db/"
echo ""
echo " Then run the pipeline:"
echo "   bash run_pipeline.sh"
echo "================================================================"