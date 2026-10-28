# _Artemisia annua_ RNA-seq Analysis Pipeline

This project implements a reproducible RNA-seq analysis workflow to investigate transcriptional regulation of artemisinin biosynthesis in _Artemisia annua_ under different light conditions.

The analysis is based on the experimental design described in:

- Zhang et al. (2018). [Red and Blue Light Promote the Accumulation of Artemisinin in *Artemisia annua* L.](https://doi.org/10.3390/molecules23061329) *Molecules.*

Rather than reproducing the exact computational environment from the original study, this project reimplements the workflow using modern RNA-seq tools and emphasizes modularity, reproducibility, and pipeline organization.

---

## Project Highlights

- Modular RNA-seq pipeline implemented as reusable Bash scripts
- Separation of code, data, and results following best practices
- Reproducible environment management using Conda/micromamba
- Semi-automated workflow: reference annotation → raw data → QC → alignment → quantification steps are automated via `run_pipeline.sh`. Downstream analysis (differential expression, visualization, enrichment) is done in Quarto notebooks
- Application to a real biological dataset (*Artemisia annua*) with a non-model organism genome
- **Functional annotation built from scratch** with eggNOG-mapper, because this assembly ships with no GO/KEGG annotation and is not supported by common enrichment web tools (see [Key Architectural Decisions](#key-architectural-decisions))
- Documented architectural decisions and known tool quirks for full transparency

---

## Tools and Technologies

| Category | Tools |
|---|---|
| **Read subsampling** | seqtk |
| **Quality control** | FastQC, MultiQC |
| **Read trimming** | fastp |
| **Alignment** | STAR |
| **Quantification** | Salmon |
| **Count aggregation** | tximport (R) |
| **Differential expression** | DESeq2 (R) |
| **Protein extraction** | gffread |
| **Functional annotation** | eggNOG-mapper |
| **Functional enrichment** | clusterProfiler (using the eggNOG-mapper annotations) |
| **Visualization** | ggplot2, seaborn, IGV |
| **Notebooks** | Quarto |

---

## System Requirements

| Resource | Minimum | Recommended |
|---|---|---|
| RAM | 20 GB | 32 GB+ |
| CPU cores | 4 | 8+ |
| Disk space | ~500 GB (measured, full 15-sample run) | 600 GB+ (headroom) |

> **Disk note:** a complete run of all 15 samples used ~501 GB in total, as measured with
> `du -sh` on the project directory. Of that, the eggNOG-mapper database (emapperdb-5.0.2)
> is ~48 GB once unzipped (the `eggnog.db.gz` download alone is ~6.3 GB compressed).
> Breakdown by directory: `raw_data/` ~293 GB (uncompressed FASTQs), `reference/` ~76 GB
> (including the eggNOG database and STAR index), `alignment/` ~69 GB, `trimmed_data/` ~59 GB,
> and everything else (subsampled data, QC reports, counts, results, logs) under ~3 GB combined.
> Intermediate files such as `trimmed_data/` can be deleted once downstream steps have finished
> if space is tight.

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

The pipeline has two independent branches. The **reference branch** (`annotate`) runs once and depends only on the genome and GTF. The **per-sample branch** runs for every sample. Both feed the downstream notebooks.

```
REFERENCE BRANCH (runs once, independent of samples)

reference/ (genome .fna + GTF)
    ↓ annotate         (gffread → protein FASTA; eggNOG-mapper → GO/KEGG/orthology)
reference/proteins.faa
reference/eggnog_annotation/
    └──────────────────────────────────────────────┐
                                                   │
PER-SAMPLE BRANCH                                  │
                                                   │
raw_data/                                          │
    ↓ subsample        (seqtk — 1M reads for dev/testing)
subsampled_data/                                   │
    ↓ qc_raw           (FastQC — baseline quality check)
qc_reports/fastqc_raw/                             │
    ↓ trim             (fastp — adapter removal, quality trimming)
trimmed_data/                                      │
    ↓ qc_trimmed       (FastQC — confirm trimming worked)
qc_reports/fastqc_trimmed/                         │
    ↓ align            (STAR — splice-aware genome alignment)
alignment/                                         │
    ↓ quantify         (Salmon — transcript-level expression)
salmon_quant/                                      │
    ↓ tximport         (R/tximport — gene-level aggregation for DESeq2)
    ↓ count            (Python/pandas — lightweight counts matrix)
counts/                                            │
    ↓ multiqc          (MultiQC — aggregate all QC reports)
results/multiqc/                                   │
    ↓ deseq2           (Quarto notebook — differential expression)
    ↓ visualization    (Quarto notebook — plots and figures)
    ↓ enrichment       (Quarto notebook — functional enrichment) ←──┘
results/                                  (uses eggNOG annotations)
```

---

## Reproducibility

Raw sequencing data, reference genome files, and annotation databases are not stored in this repository.

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

**Exact reproduction:** `setup_environment.sh` pins the tools the pipeline uses, but their dependencies resolve to newer releases over time. To recreate the exact environment the results were produced with (Linux x86_64), use the lockfile instead:

```bash
mamba env create -f environment.yml
```

### 2. Download data, build indexes, and set up annotation

```bash
bash scripts/get_fastq_files.sh
bash scripts/get_reference_genome.sh
bash scripts/build_star_index.sh
bash scripts/setup_annotation.sh reference/eggnog_db/   # one-time: downloads the eggNOG database
```

> `setup_annotation.sh` only downloads the database. gffread and eggnog-mapper are installed by `setup_environment.sh`, so run it with `genomics` activated (it uses the `aria2c` that comes with eggnog-mapper). The download takes roughly 45 minutes (see [Known Quirks](#known-quirks)).

See the [Data Availability](#data-availability) section for accession numbers and direct download links.

### 3. Configure the pipeline

Edit `config.sh` to set paths, tool names, and parameters for your system:

```bash
# Key settings to review:
THREADS=8                         # match to your available CPU cores
SUBSAMPLE_N=1000000               # reads per sample for dev/testing
STAR_GENOME_LOAD="NoSharedMemory" # safe for laptops; see RAM note above
SALMON_LIB_TYPE="A"               # auto-detect strandedness from data
EGGNOG_DB_DIR="reference/eggnog_db/"   # where setup_annotation.sh put the database
```

Tools are called by name (`STAR`, `salmon`, `emapper.py`, etc.) and resolved from the active `genomics` environment.

### 4. Run the automated pipeline steps

```bash
# Run everything
bash run_pipeline.sh

# Run specific steps only
bash run_pipeline.sh --steps trim align quantify

# Run only the reference annotation step
bash run_pipeline.sh --steps annotate

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

**Valid step names:**
```
annotate → subsample → qc_raw → trim → qc_trimmed → align → quantify → count → tximport → multiqc
```

> `annotate` is a reference-level step: it runs once per invocation, before the per-sample loop, and ignores `--samples`.
> It skips any output that already exists, so re-running the full pipeline does not repeat the eggNOG-mapper run (which takes hours on ~66,900 proteins). To force a re-run, delete the relevant outputs: `reference/proteins.faa` and/or `reference/eggnog_annotation/artemisia_annotation.emapper.annotations`.

### 5. Run downstream analysis

Open and run the Quarto notebooks in the `notebooks/` directory:

```
notebooks/deseq2.qmd              # differential expression analysis
notebooks/visualization.qmd       # plots and figures
notebooks/enrichment_analysis.qmd # functional enrichment (clusterProfiler + eggNOG annotations)
```

Rendering requires Quarto 1.9.38, installed system-wide (it is not part of the conda environment; see [Environment](#environment)). Activate `genomics` first so Quarto picks up the environment's R and its pinned packages:

```bash
conda activate genomics
quarto check                          # "Checking R installation" should point inside the genomics env
quarto render notebooks/deseq2.qmd    # repeat for the other notebooks
```

---

## Outputs

### Automated pipeline outputs

| File | Location | Description |
|---|---|---|
| Filtered GTF | `reference/GCA_003112345.1_ASM311234v1_genomic.no_gene.gtf` | GTF with `gene` records removed so gffread can parse it (see [Known Quirks](#known-quirks)) |
| Protein FASTA | `reference/proteins.faa` | Protein sequences extracted from the genome + GTF with gffread (66,918 transcript-level proteins) |
| eggNOG annotations | `reference/eggnog_annotation/artemisia_annotation.emapper.annotations` | Per-protein GO, KEGG, and orthology assignments from eggNOG-mapper |
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
| Figures | `results/figures/` | Volcano plots, heatmaps, PCA, and enrichment dot plots (`dotplot_<set>_<BP\|MF\|CC\|KEGG>.png`) |
| Enrichment tables | `results/enrichment/` | GO and KEGG over-representation results (`go_ora_*.tsv`, `kegg_ora_*.tsv`), `enrichment_summary.tsv`, `top_hits.tsv`, plus the gene-to-GO/KEGG tables, gene sets, and background universes used for each test |
| Gene-to-GO table | `reference/gene2go.tsv` | Gene-level GO mapping built from the eggNOG-mapper output, before ontology annotation |

---

## Key Architectural Decisions

**Why pure bash (not Snakemake/Nextflow)?**
The pipeline is implemented as modular bash scripts orchestrated by a wrapper (`run_pipeline.sh`). Each step script is standalone — runnable directly from the terminal with explicit arguments for debugging without needing the wrapper. This makes individual step testing straightforward and the pipeline logic transparent.

**Why `config.sh` instead of `config.yaml`?**
A bash-native config file eliminates the need for a YAML parser in the wrapper. All settings load with a single `source config.sh` call — no Python or external parsing dependencies required for configuration.

**Why eggNOG-mapper instead of g:Profiler (or another web-based enrichment tool)?**
The *A. annua* assembly (GCA_003112345.1) ships with a structural annotation only — no GO, KEGG, or other functional terms — and web-based enrichment tools such as g:Profiler do not support it as an organism. Rather than mapping to a different species and losing species-specific genes, the pipeline generates its own functional annotation: gffread extracts the protein sequences, and eggNOG-mapper assigns orthology-based GO/KEGG terms. These feed clusterProfiler as a custom annotation, which works for any non-model organism with a genome and GTF.

**Why is `annotate` a reference-level step outside the sample loop?**
Annotation depends only on the genome and GTF, not on any sample. It runs once, before the per-sample loop, and skips existing outputs — so a full pipeline run doesn't pay the eggNOG-mapper cost twice.

**How is enrichment run on a custom annotation?**
`enrichment_analysis.qmd` runs over-representation analysis (ORA) with clusterProfiler's `enricher()` (hypergeometric test, Benjamini-Hochberg correction) against GO Biological Process, Molecular Function, and Cellular Component, and against KEGG pathways. Transcript-level eggNOG annotations are mapped to genes through `tx2gene.csv`, and GO terms or pathways are unioned per gene. The background universe is the set of genes DESeq2 tested (non-NA `padj`) that carry at least one annotation in the system being tested, with separate GO and KEGG universes. GO terms are limited to 10–500 genes and KEGG pathways to 5–500; giant KEGG overview maps (e.g. "Metabolic pathways") are excluded. The terpenoid pathways ko00900 and ko00909 are reported regardless of significance, because artemisinin is a terpenoid. Enrichment is run separately for upregulated, downregulated, and all significant genes. The significance thresholds (`padj` < 0.05, |log2FC| > 1) must match `deseq2.qmd`, and the notebook checks its significant-gene count against `deseq2_significant.csv`.

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

**STAR must output a transcriptome BAM for Salmon**
Salmon's alignment mode needs reads grouped by name, but the coordinate-sorted genome BAM is not. `align.sh` therefore also requests `--quantMode TranscriptomeSAM` (`STAR_QUANT_MODE` in `config.sh`), and `quantify.sh` uses that output.

**This genome's transcript IDs contain pipe characters (`|`)**
GCA_003112345.1 uses NCBI WGS transcript IDs in the format `gnl|WGS:PKPP|mrna.AA000410.t1`. The IDs in `quant.sf` and the GTF annotation match exactly — neither `ignoreTxVersion` nor `ignoreAfterBar` should be set in `tximport()` for this assembly, as both flags actively break ID matching.

**`count.sh` vs `tximport.R` outputs**
Two count files are produced intentionally:
- `counts/counts_matrix.csv` — transcript-level, raw NumReads from `count.sh`. Quick inspection only, not suitable for DESeq2.
- `counts/gene_counts_matrix.csv` — gene-level, length-corrected from `tximport.R`. Correct DESeq2 input.

**NCBI GTF `gene` records break gffread**
NCBI GenBank-derived GTFs attach an empty `transcript_id ""` attribute to every `gene`-type record. gffread tries to use that empty value as the record ID and fails with "no valid ID found for GFF record." Protein extraction doesn't need `gene` lines (proteins are built from CDS/exon records grouped under the real `transcript_id`), so `annotate.sh` writes a filtered copy (`*.no_gene.gtf`, next to the original GTF) with `gene` lines dropped and hands that to gffread. The original GTF is never modified, and the filtered copy is what's used only for protein extraction.

**The eggNOG-mapper download script is broken upstream**
The bioconda `eggnog-mapper` package (v2.1.13 at the time of writing) ships a `download_eggnog_data.py` that points at the retired domain `eggnogdb.embl.de`. This is a known upstream issue (eggnogdb/eggnog-mapper issues #589, #600, #578). `setup_annotation.sh` downloads the database files directly from `eggnog5.embl.de` instead. If that domain goes stale too, check the [eggNOG downloads page](http://eggnog5.embl.de/#/app/downloads) for the live URL.

**Use `aria2c`, not `wget`, for the database download**
Single-connection `wget` against the eggNOG server ran at ~130 KB/s (a 14+ hour ETA for the 6.3 GB `eggnog.db.gz`). The server throttles per connection, not total bandwidth, so `aria2c` with 16 parallel connections (`-x16 -s16`) cut the download to ~45 minutes. `aria2c` is installed automatically as a dependency of `eggnog-mapper`.

**`annotate` skips existing outputs**
If `reference/proteins.faa` or the eggNOG-mapper annotations file already exist (non-empty), `annotate.sh` logs "already exists, skipping" and moves on. This protects the expensive eggNOG-mapper run, but it means a changed GTF or genome will *not* trigger re-annotation automatically — delete the old outputs first, including the `*.no_gene.gtf` filtered copy, which is also only built if missing.

**KEGG pathway names need internet access**
The enrichment notebook fetches KEGG pathway names from the KEGG REST API at run time (via `KEGGREST`). If the lookup fails, it falls back to showing raw pathway IDs (e.g. `ko00900`) instead of names. The enrichment itself is unaffected.

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

See `scripts/get_fastq_files.sh` for the download script.

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

### Functional Annotation Database

| Resource | Source |
|---|---|
| eggNOG-mapper database (emapperdb-5.0.2) | Downloaded by `scripts/setup_annotation.sh` from `eggnog5.embl.de` into `reference/eggnog_db/` (files: `eggnog.db`, `eggnog.taxa.db`, `eggnog_proteins.dmnd`). See [eggNOG-mapper](https://github.com/eggnogdb/eggnog-mapper). |

---

## Environment

All tools are managed via conda/mamba in the `genomics` environment. See `scripts/setup_environment.sh` for the full tool list and installation instructions. Run the setup script rather than installing tools manually — it verifies each installation and prints a version table.

gffread and eggnog-mapper are installed by `scripts/setup_environment.sh`; `scripts/setup_annotation.sh` only downloads the eggNOG database.

**Not managed by conda:** Quarto 1.9.38 (system-wide install from <https://quarto.org/docs/download/>) is used to render the `.qmd` notebooks. It is deliberately left out of `environment.yml` so there is a single Quarto on the system rather than a second copy inside the environment. Quarto locates R through `PATH`, so always activate `genomics` before rendering (see [step 5](#5-run-downstream-analysis)).

| Tool | Version | Role |
|---|---|---|
| Quarto | 1.9.38 | Notebook rendering (system install, not in conda) |
| FastQC | 0.12.1 | Read quality assessment |
| fastp | 1.1.0 | Adapter trimming |
| STAR | 2.7.11b | Splice-aware alignment |
| Salmon | 2.1.1 | Transcript quantification |
| MultiQC | 1.33 | QC aggregation |
| seqtk | 1.5 | Read subsampling |
| SeqKit | 2.13.0 | Installed for the KAUST course labs; not used by any pipeline step |
| gffread | 0.12.9 | Protein sequence extraction from genome + GTF |
| eggNOG-mapper | 2.1.13 | Functional annotation (GO/KEGG/orthology), database emapperdb-5.0.2 |
| DIAMOND | 2.2.2 | Protein search engine used by eggNOG-mapper |
| R | 4.4.3 | tximport, DESeq2, clusterProfiler |
| tximport | 1.34.0 | Transcript → gene aggregation |
| DESeq2 | 1.46.0 | Differential expression |
| clusterProfiler | 4.14.0 | Functional enrichment |

---

## Repository Structure

```
artemisia-annua-rna-seq-project/
├── run_pipeline.sh              # wrapper — entry point for the pipeline
├── config.sh                    # all paths, tools, and parameters
├── environment.yml              # exact environment lockfile (conda export)
├── samples.csv                  # sample manifest
├── README.md
├── .gitignore
├── scripts/
│   ├── setup_environment.sh     # one-time environment setup
│   ├── setup_annotation.sh      # one-time eggNOG-mapper database download
│   ├── get_fastq_files.sh       # download raw FASTQ files from SRA
│   ├── get_reference_genome.sh  # download genome and GTF from NCBI
│   ├── build_star_index.sh      # build STAR genome index (run once)
│   ├── check_python_libs.py     # verify Python package installations
│   ├── check_R_libs.R           # verify R package installations
│   ├── annotate.sh              # reference step: protein FASTA + eggNOG-mapper annotation
│   ├── subsample.sh             # step: subsample reads for testing
│   ├── qc_raw.sh                # step: FastQC on raw reads
│   ├── trim.sh                  # step: fastp trimming
│   ├── qc_trimmed.sh            # step: FastQC on trimmed reads
│   ├── align.sh                 # step: STAR alignment
│   ├── quantify.sh              # step: Salmon quantification
│   ├── tximport.R               # step: transcript → gene aggregation
│   ├── count.sh                 # step: lightweight counts matrix
│   └── multiqc.sh               # step: aggregate QC reports
├── notebooks/
│   ├── deseq2.qmd               # differential expression analysis
│   ├── visualization.qmd        # plots and figures
│   └── enrichment_analysis.qmd  # functional enrichment
├── raw_data/
├── subsampled_data/
├── trimmed_data/
├── reference/
│   ├── star_index/
│   ├── eggnog_db/               # eggNOG-mapper database (large, not tracked)
│   ├── eggnog_annotation/       # eggNOG-mapper output
│   ├── proteins.faa             # extracted protein sequences
│   ├── *.no_gene.gtf            # GTF with gene records removed (gffread input)
│   └── gene2go.tsv              # gene-to-GO table (written by the enrichment notebook)
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

Additional contributions include applying the workflow to a new biological dataset (*Artemisia annua*), structuring the project as a reproducible research repository, building a from-scratch functional annotation step (eggNOG-mapper) so that enrichment analysis works for a non-model organism, and extending the pipeline with architectural decisions documented above.