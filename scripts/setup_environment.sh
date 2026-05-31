#!/usr/bin/env bash
# ==============================================================================
# setup_environnment.sh — Create the genomics conda/mamba environment
# ==============================================================================
# This script installs all tools required to run the RNA-seq pipeline
# into a conda environment named 'genomics'.
#
# Run this ONCE before using the pipeline for the first time.
#
# Prerequisites:
#   - conda, mamba, or micromamba must already be installed
#   - Run from the root of the project directory
#
# Usage:
#   bash setup_environment.sh                 # auto-detects conda/mamba/micromamba
#   bash setup_environment.sh --manager mamba # specify a package manager explicitly
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
        --help | -h)
            echo "Usage: bash setup_environment.sh [--manager conda|mamba|micromamba]"

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

# We check by listing environments and grepping for the env name.
# '|| true' prevents set -e from exiting if grep finds no match.
if $MANAGER env list | grep -q "^${ENV_NAME}"; then
    echo ""
    echo "Environment '${ENV_NAME}' already exists."
    echo "To recreate it from scratch, remove it first with:"
    echo "  ${MANAGER} env remove -n ${ENV_NAME}"
    echo ""
    echo "To update it with any missing packages, re-run this script"
    echo "and it will install into the existing environment."
    echo ""
fi


# ------------------------------------------------------------------------------
# Create the environment and install tools
# Source: Bioinformatics Specialization Program 2026 - KAUST Academy 
# (https://bioinfo-kaust.github.io/academy-stage3-2026/html/setup.html)

# All tools are pinned to the versions used during development.
# Channels: bioconda (bioinformatics tools), conda-forge (dependencies)
# ------------------------------------------------------------------------------

echo "Creating environment '${ENV_NAME}'..."
echo "This may take several minutes."
echo ""

$MANAGER create \
    --name "$ENV_NAME" \
    --channel bioconda \
    --channel conda-forge \
    --yes \
    \
    # --- Python ---
    python=3.11 \
    \
    # ---- QC ----
    fastqc=0.12.1 \
    fastp=1.3.0 \
    multiqc=1.33 \
    \
    # ---- Alignment ----
    star=2.7.11b \
    samtools=1.22.1 \
    \
    # ---- Quantification ----
    salmon=1.10.3 \
    igv=2.19.7 \
    \
    # ---- Subsampling ----
    seqtk \ # TODO: will need to update with version once i remake the environment
    seqkit=2.13.0 \
    \
    # ---- Download tools ----
    sra-tools=3.2.1 \
    wget \
    \
    # ---- Python analysis libraries ----
    pandas=3.0.1 \
    numpy=2.4.3 \
    matplotlib=3.10.8 \
    seaborn=0.13.2 \
    scipy=1.17.1 \
    scikit-learn=1.8.0 \
    openpyxl=3.1.5 \
    gprofiler-official=1.0.0 \
    \
    # ---- R base ----
    r-base=4.4.3 \
    \
    # ---- R analysis packages ----
    r-tidyverse=2.0.0 \
    r-biocmanager=1.30.27 \
    bioconductor-deseq2=1.46.0 \
    bioconductor-tximport=1.34.0 \
    bioconductor-clusterprofiler \
    bioconductor-enrichplot=1.26.1 \
    bioconductor-org.hs.eg.db=3.20.0 \
    r-pheatmap=1.0.13 \
    r-ggrepel=0.9.8 \
    r-ggplot2=4.0.2 \
    r-colorbrewer=1.1.3 \
    \
    # ---- Utilities ----
    jq \
    yq \
    tree

    echo ""
    echo "Environment '${ENV_NAME}' created successfully."


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
# The || echo line ensures a failed check prints a warning instead of 
# stopping the whole script (we want to check all tools, not stop at first failure).
echo ""
printf "%-20s %s\n" "Tool" "Version"
printf "%-20s %s\n" "----" "-------"

check_tool_shell() {
    tools=("fastqc" "fastp" "STAR" "salmon" "samtools" "multiqc" "seqkit")
    
    for tool in  "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
          # Run the version command and grab the first line of output.
          version=$($tool $version_flag 2>&1 | head -1) || version="(version check failed)"

          printf "%-20s %s\n" "$tool" "$version"
        else
          printf "%-20s %s\n" "$tool" "NOT FOUND — check installation"
        fi
    done

}

check_tool_python() {
    python -c "
    import sys
    packages = {
        'pandas': 'pd',
        'numpy': 'np',
        'matplotlib': 'mpl',
        'seaborn': 'sns'
    }
    for pkg, alias in packages.items():
        try:
            __import__(alias)
            version = getattr(sys.modules[alias], '__version__', 'unknown')
            print(f'{pkg:20} {version}')
        except ImportError:
            print(f'{pkg:20} NOT FOUND — check installation')
    "
}

check_tool_R() {
    Rscript -e "
    packages <- c('DESeq2', 'clusterProfiler', 'tximport', 'ggplot2')
    for (pkg in packages) {
        if (requireNamespace(pkg, quietly = TRUE)) {
            version <- as.character(packageVersion(pkg))
            cat(sprintf('%-20s %s\n', pkg, version))
        } else {
            cat(sprintf('%-20s NOT FOUND — check installation\n', pkg))
        }
    }
    "
}

check_tool_shell  "fastqc"             "--version"
check_tool_shell  "fastp"              "--version"
check_tool_shell  "STAR"               "--version"
check_tool_shell  "salmon"             "--version"
check_tool_shell  "samtools"           "--version"
check_tool_shell  "multiqc"            "--version"
check_tool_shell  "seqkit"             "--version"
check_tool_python "pandas"             "--version"
check_tool_python "numpy"              "--version"
check_tool_python "matplotlib"         "--version"
check_tool_python "seaborn"            "--version"
check_tool_R      "DESeq2"             "--version"
check_tool_R      "clusterProfiler"    "--version"
check_tool_R      "tximport"           "--version"
check_tool_R      "ggplot2"            "--version"



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
echo " Then run the pipeline:"
echo "   bash run_pipeline.sh"
echo "================================================================"
