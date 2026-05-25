# (WIP) _Artemisia annua_ RNA Seq Analysis Pipeline

This project implements a reproducible RNA-seq analysis workflow to investigate transcriptional regulation of artemisinin biosynthesis in _Artemisia annua_ under different light conditions. 

The analysis is based on the experimental design described in 

- [Zhang et al. 2018 Artemisia annua transcriptome study](https://doi.org/10.3390/molecules23061329)

Rather than reproducing the exact computational environment from the original study, this project reimplements the workflow using modern RNA-seq tools and emphasizes modularity, reproducibility, and pipeline organization. 

## Project Highlights
- Modular RNA-seq pipeline implemented as reusable Bash scripts
- Separation of code, data, and results following best practices
- Reproducible environment management using Conda
- End-to-end workflow: raw data -> QC -> alignment -> quantification -> differential expression -> enrichment
- Application to a real biological dataset (_Artemisia annua_)

## Tools and Technologies
- **Sequence Processing:** SeqKit
- **Quality Control:** FastQC, MultiQC
- **Read Trimming:** fastp
- **Alignment:** STAR
- **Quantification:** Salmon
- **Differential Expression** DESeq2
- **Visualization:** seaborn, IGV
- **Functional Enrichment:**  ClusterProfiler

## Pipeline Overview
1. Download RNA-seq data from SRA
2. Perform quality control (FastQC, MultiQC)
3. Trim reads (fastp)
4. Align reads to reference genome (STAR)
5. Quantify transcript abundance (Salmon)
6. Perform differential expression analysis (DESeq2)
7. Functional enrichment analysis (ClusterProfiler)

## Reproducibility

Raw sequencing data is not stored in this repository. 

To reproduce the workflow analysis:

### 1. Setup the environment
```bash
# 1. First time only — set up the environment
bash setup_environment.sh

# 2. Every time — activate before running
micromamba activate genomics
```

### 2. Download data
```bash
bash scripts/get_fastq_files.sh
bash scrpts/get_reference_genome.sh
```

### 3. Run pipeline

```bash
# Run everything
bash run_pipeline.sh

# Run only specific steps
bash run_pipeline.sh --steps trim align quantify

# Run on specific samples
bash run_pipeline.sh --samples ctrl_1 treat_1

# Combine both — useful for re-running a failed sample
bash run_pipeline.sh --steps align quantify --samples treat_2

# Preview all commands without running anything
bash run_pipeline.sh --dry-run

# Use a different config
bash run_pipeline.sh --config path/to/config.sh

# Check QC before committing to a full alignment run
bash run_pipeline.sh --steps qc_raw trim qc_trimmed multiqc
```

## Repository Structure
```
/artemisia-annua-rna-seq-project
├── config.sh        # main config
├── config.yaml      # main config (yaml version)
├── samples.csv      # sample manifest
├── pipeline.py      # main runner
├── scripts/
│   ├── get_fastq_files.sh
│   ├── get_reference_genome.sh
│   ├── transcript_to_gene_mapping.sh
│   ├── build_star_index.sh
│   ├── build_salmon_index.sh
│   ├── infer_strandedness.sh
│   └── deseq2.R
├── raw_data/
├── subsampled_data/
├── trimmed_data/
├── references/
├── qc_reports/
│   ├── fastqc_raw/
│   ├── fastqc_trimmed/
│   ├── fastp/
├── alignment/
├── salmon_quant/
├── results/
│   ├── tables/
│   ├── figures/
│   ├── enrichment/
├── logs/
├── README.md
└── .gitignore
```

## Outputs
This pipeline produces:
- Quality control reports (FastQC, MultiQC)
- Aligned reads (STAR)
- Transcript quantification (Salmon)
- Differential expression results (DESeq2)
- Functional enrichment analysis (ClusterProfiler)

## Acknowledgements

This project was developed using publicly available RNA-seq training materials from the KAUST Academy Bioinformatics Specialization Program:

[https://bioinfo-kaust.github.io/academy-stage3-2026/index.html](https://bioinfo-kaust.github.io/academy-stage3-2026/index.html)

These materials were used for self-study and provided step-by-step instructional code for RNA-seq analysis. In this project, those components were reorganized and adapted into a modular, script-based pipeline to improve automation, reproducibility, and usability. 

Additional contributions including applying the workflow to a new biological dataset (_Artemisia annua_) and structuring the project as a reproducible research repository. 