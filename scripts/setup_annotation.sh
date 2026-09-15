#!/usr/bin/env bash
# scripts/setup_annotation.sh
# ==============================================================================
# One-time setup for functional annotation: installs required tools and
# downloads the eggNOG-mapper reference database.
#
# WHY: gffread and eggnog-mapper are not yet installed in the genomics env,
# and eggNOG-mapper requires its reference database (DIAMOND/HMMER data,
# several GB) downloaded locally before it can annotate anything. Both are
# one-time setup costs — this script is run once manually, not by
# run_pipeline.sh, and not gated by should_run_step.
#
# NOTE ON DIRECT DOWNLOAD (not using download_eggnog_data.py):
# The eggnog-mapper package (bioconda, v2.1.13 as of this writing) ships
# with a broken download_eggnog_data.py — it points at the old domain
# eggnogdb.embl.de, which no longer resolves. The current domain is
# eggnog5.embl.de. This is a known upstream issue (see eggnogdb/eggnog-mapper
# GitHub issues #589, #600, #578) affecting many users, not something
# specific to this environment. Rather than depend on a broken script, this
# step downloads the required files directly from the correct domain.
#
# If eggnog5.embl.de also becomes stale in the future, check the current
# downloads page for the live URL: http://eggnog5.embl.de/#/app/downloads
#
# NOTE ON aria2c vs wget:
# Single-threaded wget against this server was measured at ~130KB/s
# (14+ hour ETA for the 6.3GB eggnog.db.gz). aria2c with 16 parallel
# connections (-x16 -s16) cut that to ~45 minutes — the bottleneck is
# per-connection throttling, not actual available bandwidth. aria2c is
# installed automatically as a dependency of eggnog-mapper via bioconda.
#
# IDEMPOTENT: each database file is checked for existence before download,
# since these are multi-GB files and shouldn't be re-fetched on every re-run.
#
# Arguments:
#   $1    EGGNOG_DB_DIR : path where the eggNOG database will be stored
# ==============================================================================

set -euo pipefail

EGGNOG_DB_DIR="$1"
EGGNOG_DB_DIR="$(realpath "${EGGNOG_DB_DIR}")"

mkdir -p "${EGGNOG_DB_DIR}"

echo "Installing gffread and eggnog-mapper..."
mamba install -c bioconda -c conda-forge gffread eggnog-mapper -y

BASE_URL="http://eggnog5.embl.de/download/emapperdb-5.0.2"
ARIA2_OPTS="-x16 -s16"

# ---- eggnog.db (main annotation database) ----
if [[ -s "${EGGNOG_DB_DIR}/eggnog.db" ]]; then
    echo "eggnog.db already exists, skipping download."
else
    echo "Downloading eggnog.db..."
    aria2c ${ARIA2_OPTS} -d "${EGGNOG_DB_DIR}" -o eggnog.db.gz "${BASE_URL}/eggnog.db.gz"
    gunzip "${EGGNOG_DB_DIR}/eggnog.db.gz"
fi

# ---- eggnog.taxa.db (taxonomy database) ----
if [[ -s "${EGGNOG_DB_DIR}/eggnog.taxa.db" ]]; then
    echo "eggnog.taxa.db already exists, skipping download."
else
    echo "Downloading eggnog.taxa.tar.gz..."
    aria2c ${ARIA2_OPTS} -d "${EGGNOG_DB_DIR}" -o eggnog.taxa.tar.gz "${BASE_URL}/eggnog.taxa.tar.gz"
    tar -zxf "${EGGNOG_DB_DIR}/eggnog.taxa.tar.gz" -C "${EGGNOG_DB_DIR}"
    rm "${EGGNOG_DB_DIR}/eggnog.taxa.tar.gz"
fi

# ---- eggnog_proteins.dmnd (DIAMOND search database) ----
if [[ -s "${EGGNOG_DB_DIR}/eggnog_proteins.dmnd" ]]; then
    echo "eggnog_proteins.dmnd already exists, skipping download."
else
    echo "Downloading eggnog_proteins.dmnd.gz..."
    aria2c ${ARIA2_OPTS} -d "${EGGNOG_DB_DIR}" -o eggnog_proteins.dmnd.gz "${BASE_URL}/eggnog_proteins.dmnd.gz"
    gunzip "${EGGNOG_DB_DIR}/eggnog_proteins.dmnd.gz"
fi

echo "eggNOG database setup complete: ${EGGNOG_DB_DIR}"