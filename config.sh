# config.sh
# Source this file to load all pipeline settings into the shell environment.
# Usage in run_pipeline.sh: source config.sh

# --- Paths ---
SAMPLES_CSV="samples.csv"
RAW_DIR="raw_data/"
SRA_DIR="raw_data/sra_downloads"
FASTERQ_TEMP="raw_data/tmp/fasterq_temp"
SUBSAMPLED_DIR="subsampled_data/"
TRIMMED_DIR="trimmed_data/"
REF_DIR="reference/"
REF_GENOME="reference/GCA_003112345.1_ASM311234v1_genomic.fna"
REF_TRANSCRIPTOME="reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna"
REF_GTF="reference/GCA_003112345.1_ASM311234v1_genomic.gtf"
STAR_INDEX="reference/star_index/"
QC_RAW_DIR="qc_reports/fastqc_raw/"
QC_TRIMMED_DIR="qc_reports/fastqc_trimmed/"
QC_FASTP_DIR="qc_reports/fastp"
ALIGNMENT_DIR="alignment/"
SALMON_DIR="salmon_quant"
COUNTS_DIR="counts/"
RESULTS_DIR="results/"
LOGS_DIR="logs/"

# --- Environment (Tools) ---
# Full path to the genomics conda/mamba environment bin directory.
# This means the pipeline doesn't depend on 'conda activate' being available
# in the shell — tools are called directly by their absolute epath.
FASTQC="fastqc"
FASTP="fastp"
STAR="STAR"
SALMON="salmon"
MULTIQC="multiqc"
RSCRIPT="Rscript"

# --- Parameters ---
THREADS=8
FASTERQ_THREADS=16
FASTERQ_MEM=32G
SUBSAMPLE_n=1000000
FASTP_MIN_LEN=36
FASTP_QUAL=20
FASTP_UNQUAL_PCT=40
STAR_SAM_TYPE="BAM SortedByCoordinate"
STAR_SAM_ATTR="NH HI AS NM"
STAR_GENOME_LOAD="NoSharedMemory"
SALMON_LIB_TYPE="A"
DESEQ2_PADJ=0.05
DESEQ2_LFC=1.0