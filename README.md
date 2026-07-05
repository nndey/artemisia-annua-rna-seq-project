# (WIP) _Artemisia annua_ RNA-seq Analysis Pipeline

This project implements a reproducible RNA-seq analysis workflow to investigate transcriptional regulation of artemisinin biosynthesis in _Artemisia annua_ under different light conditions.

The analysis is based on the experimental design described in:

- Zhang et al. (2018). [Red and Blue Light Promote the Accumulation of Artemisinin in *Artemisia annua* L.](https://doi.org/10.3390/molecules23061329) *Molecules.*

Rather than reproducing the exact computational environment from the original study, this project reimplements the workflow using modern RNA-seq tools and emphasizes modularity, reproducibility, and pipeline organization.

---

## Project Highlights

- Modular RNA-seq pipeline implemented as reusable Bash scripts
- Separation of code, data, and results following best practices
- Reproducible environment management using Conda/micromamba
- Semi-automated workflow: raw data → QC → alignment → quantification steps are automated via `run_pipeline.sh`. Downstream analysis (differential expression, visualization, enrichment) is done in Quarto notebooks
- Application to a real biological dataset (*Artemisia annua*) with a non-model organism genome
- Documented architectural decisions and known tool quirks for full transparency

---

## Tools and Technologies

| Category | Tools |
|---|---|
| **Sequence processing** | SeqKit, seqtk |
| **Quality control** | FastQC, MultiQC |
| **Read trimming** | fastp |
| **Alignment** | STAR |
| **Quantification** | Salmon |
| **Count aggregation** | tximport (R) |
| **Differential expression** | DESeq2 (R) |
| **Visualization** | ggplot2, seaborn, IGV |
| **Functional enrichment** | ClusterProfiler |
| **Notebooks** | Quarto |

---

## System Requirements

| Resource | Minimum | Recommended |
|---|---|---|
| RAM | 20 GB | 32 GB+ |
| CPU cores | 4 | 8+ |
| Disk space | ~50 GB | ~100 GB |

> **STAR memory note:** The *A. annua* genome (GCA_003112345.1) is ~1.79 Gb with
> ~190,477 scaffolds. STAR genome indexing requires ~16–18 GB RAM for this assembly
> due to genome size plus fragmentation overhead. Users on machines with less than
> 20 GB RAM should add `--genomeSAsparseD 2` to STAR parameters in `config.sh`
> to reduce memory usage (~30–40% reduction, minor speed cost).
>
> RAM resets between pipeline steps — STAR loads and releases the genome per sample
> (`NoSharedMemory` mode). Peak usage occurs only during alignment.

---

## Pipeline Overview

```
raw_data/
    ↓ subsample        (seqtk — 1M reads for dev/testing)
subsampled_data/
    ↓ qc_raw           (FastQC — baseline quality check)
qc_reports/fastqc_raw/
    ↓ trim             (fastp — adapter removal, quality trimming)
trimmed_data/
    ↓ qc_trimmed       (FastQC — confirm trimming worked)
qc_reports/fastqc_trimmed/
    ↓ align            (STAR — splice-aware genome alignment)
alignment/
    ↓ quantify         (Salmon — transcript-level expression)
salmon_quant/
    ↓ tximport         (R/tximport — gene-level aggregation for DESeq2)
    ↓ count            (Python/pandas — lightweight counts matrix)
counts/
    ↓ multiqc          (MultiQC — aggregate all QC reports)
results/multiqc/
    ↓ deseq2           (Quarto notebook — differential expression)
    ↓ visualization    (Quarto notebook — plots and figures)
    ↓ enrichment       (Quarto notebook — functional enrichment)
results/
```

---

## Reproducibility

Raw sequencing data and reference genome files are not stored in this repository.

### 1. Set up the environment

```bash
# First time only — creates the 'genomics' conda environment
bash scripts/setup_environment.sh

# Every time — activate before running anything
micromamba activate genomics
# or: conda activate genomics
```

> The pipeline checks that the `genomics` environment is active before running.
> If it isn't, you'll get a clear error message with activation instructions.

### 2. Download data and build indexes

```bash
bash scripts/get_fastq_files.sh
bash scripts/get_reference_genome.sh
bash scripts/build_star_index.sh
```

See the [Data Availability](#data-availability) section for accession numbers and direct download links.

### 3. Configure the pipeline

Edit `config.sh` to set paths, tool names, and parameters for your system:

```bash
# Key settings to review:
THREADS=8                         # match to your available CPU cores
SUBSAMPLE_N=1000000               # reads per sample for dev/testing
STAR_GENOME_LOAD="NoSharedMemory" # safe for laptops; see RAM note above
SALMON_LIB_TYPE="A"               # auto-detect strandedness from data
```

### 4. Run the automated pipeline steps

```bash
# Run everything
bash run_pipeline.sh

# Run specific steps only
bash run_pipeline.sh --steps trim align quantify

# Run on specific samples only
bash run_pipeline.sh --samples SRR6808226 SRR6808227

# Combine — useful for re-running a failed sample
bash run_pipeline.sh --steps align quantify tximport --samples SRR6808226

# Preview all commands without running anything
bash run_pipeline.sh --dry-run

# Use a different config (e.g. for a test run)
bash run_pipeline.sh --config path/to/config.sh

# Check QC before committing to a full alignment run
bash run_pipeline.sh --steps qc_raw trim qc_trimmed multiqc
```

**Valid step names (in order):**
```
subsample → qc_raw → trim → qc_trimmed → align → quantify → tximport → count → multiqc
```

### 5. Run downstream analysis

Open and run the Quarto notebooks in the `notebooks/` directory:

```
notebooks/deseq2.qmd              # differential expression analysis
notebooks/visualization.qmd       # plots and figures
notebooks/enrichment_analysis.qmd # functional enrichment (ClusterProfiler)
```

---

## Outputs

### Automated pipeline outputs

| File | Location | Description |
|---|---|---|
| FastQC reports | `qc_reports/fastqc_raw/`, `qc_reports/fastqc_trimmed/` | Per-sample read quality |
| fastp reports | `qc_reports/fastp/` | Trimming statistics |
| BAM files | `alignment/<sample_id>/` | STAR alignments |
| Salmon output | `salmon_quant/<sample_id>/quant.sf` | Transcript-level counts + TPM |
| counts matrix | `counts/counts_matrix.csv` | Transcript-level raw NumReads (inspection only) |
| gene counts | `counts/gene_counts_matrix.csv` | Gene-level, length-corrected (DESeq2 input) |
| TPM matrix | `counts/gene_tpm_matrix.csv` | Gene-level TPM (visualisation) |
| tximport object | `counts/tximport_object.rds` | Full txi object (preferred DESeq2 input) |
| tx2gene map | `counts/tx2gene.csv` | Transcript → gene mapping from GTF |
| MultiQC report | `results/multiqc/multiqc_report.html` | Aggregated QC across all steps |

### Notebook outputs

| File | Location | Description |
|---|---|---|
| DESeq2 results | `results/tables/` | Differential expression tables |
| Figures | `results/figures/` | Volcano plots, heatmaps, PCA |
| Enrichment | `results/enrichment/` | ClusterProfiler output |

---

## Key Architectural Decisions

**Why pure bash (not Snakemake/Nextflow)?**
The pipeline is implemented as modular bash scripts orchestrated by a wrapper (`run_pipeline.sh`). Each step script is standalone — runnable directly from the terminal with explicit arguments for debugging without needing the wrapper. This makes individual step testing straightforward and the pipeline logic transparent.

**Why `config.sh` instead of `config.yaml`?**
A bash-native config file eliminates the need for a YAML parser in the wrapper. All settings load with a single `source config.sh` call — no Python or external parsing dependencies required for configuration.

**Why Salmon in alignment-based mode?**
STAR alignments feed directly into Salmon (`--alignments`) rather than Salmon performing its own mapping. This keeps alignments consistent between the STAR BAM and Salmon's quantification — important for comparing alignment statistics and expression estimates.

**Why `lengthScaledTPM` in tximport?**
The *A. annua* genome is highly fragmented (~190K scaffolds) and isoform usage may differ across light conditions. `lengthScaledTPM` corrects for transcript length differences across samples before DESeq2 modelling — the current best-practice recommendation for Salmon → DESeq2 workflows (Love et al. 2018).

**Why `NoSharedMemory` for STAR genome loading?**
STAR loads and releases the genome index per sample. This is the safest mode for a local machine — no manual memory cleanup required, no shared memory segments left behind between runs. The tradeoff is reloading the genome for each sample (~few minutes), which is acceptable given the sample count.

**Why auto-detect library type (`--libType A`)?**
Salmon infers strandedness from the data rather than requiring manual specification. The detected type is logged to `salmon_quant/<sample_id>/logs/` and can be independently verified with `infer_experiment.py` from RSeQC.

---

## Known Quirks

**STAR startup logs land in the working directory**
STAR writes `Log.out` and `Log.progress.out` to the current working directory at startup, before processing `--outFileNamePrefix`. This is a known STAR behaviour — `align.sh` handles this by changing into the sample output directory before running STAR so all logs land in `alignment/<sample_id>/`.

**This genome's transcript IDs contain pipe characters (`|`)**
GCA_003112345.1 uses NCBI WGS transcript IDs in the format `gnl|WGS:PKPP|mrna.AA000410.t1`. The IDs in `quant.sf` and the GTF annotation match exactly — neither `ignoreTxVersion` nor `ignoreAfterBar` should be set in `tximport()` for this assembly, as both flags actively break ID matching.

**`count.sh` vs `tximport.R` outputs**
Two count files are produced intentionally:
- `counts/counts_matrix.csv` — transcript-level, raw NumReads from `count.sh`. Quick inspection only, not suitable for DESeq2.
- `counts/gene_counts_matrix.csv` — gene-level, length-corrected from `tximport.R`. Correct DESeq2 input.

---

## Data Availability

### RNA-seq Data

Raw sequencing data are publicly available from NCBI SRA under BioProject [PRJNA435470](https://www.ncbi.nlm.nih.gov/bioproject/PRJNA435470) (SRP133983).

**Original study:** Zhang et al. (2018). Red and Blue Light Promote the Accumulation of Artemisinin in *Artemisia annua* L. *Molecules.* https://doi.org/10.3390/molecules23061329

**Experimental design:** *A. annua* seedlings exposed to five light quality conditions for 2 days at 50 ± 5 μmol/m²s intensity. Samples were collected from aboveground parts and sequenced with Illumina paired-end RNA-seq.

| Condition | Description | Replicates | SRR Accessions |
|---|---|---|---|
| Blue | LED blue light (470 nm) | 3 | SRR6808226, SRR6808227, SRR6808228 |
| Red | LED red light (670 nm) | 3 | SRR6808229, SRR6808230, SRR6808240 |
| White | White light | 3 | SRR6808231, SRR6808232, SRR6808239 |
| Far-red | LED far-red light (735 nm) | 3 | SRR6808233, SRR6808234, SRR6808236 |
| Dark | Dark (no light) | 3 | SRR6808235, SRR6808237, SRR6808238 |

See `scripts/get_fastq_files.sh` for the download script, or download manually:

```bash
micromamba activate genomics

prefetch --output-directory raw_data/sra_downloads/ \
    SRR6808226 SRR6808227 SRR6808228 \
    SRR6808229 SRR6808230 SRR6808240 \
    SRR6808231 SRR6808232 SRR6808239 \
    SRR6808233 SRR6808234 SRR6808236 \
    SRR6808235 SRR6808237 SRR6808238

for SRR in SRR6808226 SRR6808227 SRR6808228 SRR6808229 SRR6808230 \
           SRR6808231 SRR6808232 SRR6808233 SRR6808234 SRR6808235 \
           SRR6808236 SRR6808237 SRR6808238 SRR6808239 SRR6808240; do
    fasterq-dump \
        --threads 8 \
        --mem 2G \
        --split-files \
        --outdir raw_data/ \
        raw_data/sra_downloads/${SRR}/${SRR}.sra
done
```

### Reference Genome

| Resource | Accession | Source |
|---|---|---|
| Genome assembly | GCA_003112345.1 (ASM311234v1) | [NCBI](https://www.ncbi.nlm.nih.gov/datasets/genome/GCA_003112345.1/) |
| Annotation (GTF) | GCA_003112345.1 | Included with genome download |

See `scripts/get_reference_genome.sh` for the download script, or download manually:

```bash
wget -P reference/ \
    "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/003/112/345/GCA_003112345.1_ASM311234v1/GCA_003112345.1_ASM311234v1_genomic.fna.gz"

wget -P reference/ \
    "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/003/112/345/GCA_003112345.1_ASM311234v1/GCA_003112345.1_ASM311234v1_genomic.gtf.gz"

gunzip reference/*.gz
```

---

## Environment

All tools are managed via conda/mamba in the `genomics` environment. See `scripts/setup_environment.sh` for the full tool list and installation instructions. Run the setup script rather than installing tools manually — it verifies each installation and prints a version table.

| Tool | Version | Role |
|---|---|---|
| FastQC | 0.12.1 | Read quality assessment |
| fastp | 1.3.0 | Adapter trimming |
| STAR | 2.7.11b | Splice-aware alignment |
| Salmon | 1.10.3 | Transcript quantification |
| MultiQC | 1.33 | QC aggregation |
| seqtk | — | Read subsampling |
| R | 4.4.3 | tximport, DESeq2, ClusterProfiler |
| tximport | 1.34.0 | Transcript → gene aggregation |
| DESeq2 | 1.46.0 | Differential expression |
| ClusterProfiler | 4.14.0 | Functional enrichment |

---

## Repository Structure

```
artemisia-annua-rna-seq-project/
├── run_pipeline.sh              # wrapper — entry point for the pipeline
├── config.sh                    # all paths, tools, and parameters
├── samples.csv                  # sample manifest
├── README.md
├── .gitignore
├── scripts/
│   ├── setup_environment.sh     # one-time environment setup
│   ├── get_fastq_files.sh       # download raw FASTQ files from SRA
│   ├── get_reference_genome.sh  # download genome and GTF from NCBI
│   ├── build_star_index.sh      # build STAR genome index (run once)
│   ├── check_python_libs.py     # verify Python package installations
│   ├── check_R_libs.R           # verify R package installations
│   ├── subsample.sh             # step 1: subsample reads for testing
│   ├── qc_raw.sh                # step 2: FastQC on raw reads
│   ├── trim.sh                  # step 3: fastp trimming
│   ├── qc_trimmed.sh            # step 4: FastQC on trimmed reads
│   ├── align.sh                 # step 5: STAR alignment
│   ├── quantify.sh              # step 6: Salmon quantification
│   ├── tximport.R               # step 7: transcript → gene aggregation
│   ├── count.sh                 # step 8: lightweight counts matrix
│   └── multiqc.sh               # step 9: aggregate QC reports
├── notebooks/
│   ├── deseq2.qmd               # differential expression analysis
│   ├── visualization.qmd        # plots and figures
│   └── enrichment_analysis.qmd  # functional enrichment
├── raw_data/
├── subsampled_data/
├── trimmed_data/
├── reference/
├── qc_reports/
│   ├── fastqc_raw/
│   ├── fastqc_trimmed/
│   └── fastp/
├── alignment/
├── salmon_quant/
├── counts/
├── results/
│   ├── tables/
│   ├── figures/
│   └── enrichment/
└── logs/
```

---

## Acknowledgements

This project was developed following publicly available RNA-seq training materials from the KAUST Academy Bioinformatics Specialization Program:

[https://bioinfo-kaust.github.io/academy-stage3-2026/index.html](https://bioinfo-kaust.github.io/academy-stage3-2026/index.html)

These materials were used for self-study and provided step-by-step instructional code for RNA-seq analysis. In this project, those instructional code references were used as needed when developing this modular, script-based pipeline to aid in improved automation, reproducibility, and usability.

Additional contributions include applying the workflow to a new biological dataset (*Artemisia annua*), structuring the project as a reproducible research repository, and extending the pipeline with architectural decisions documented above.