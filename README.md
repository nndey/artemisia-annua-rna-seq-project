# (WIP) _Artemisia annua_ RNA Seq Analysis Pipeline

This project implements a reproducible RNA-seq analysis workflow to investigate transcriptional regulation of artemisinin biosynthesis in _Artemisia annua_ under different light conditions. 

The analysis is based on the experimental design described in 

- [Zhang et al. 2018 Artemisia annua transcriptome study](https://doi.org/10.1016/j.jphotobiol.2014.08.013)

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

### 1. Download data
```bash
bash scripts/get_fastq_files.sh
bash scrpts/get_reference_genome.sh
```

### 2. Run pipeline

Each step of the workflow is modularized into scripts: 

```bash

# These scripts are still a WIP as of 5/8/2026
bash run_fastqc.sh
bash run_STAR.sh
bash run_IGV.sh
bash run_Salmon.sh
```

> Downstream statistical analysis and visualization (DESeq2, enrichment analysis) are implemented in Jupyter notebooks located in `notebooks/`. This directory is still a WIP as of 5/8/2026.

## Repository Structure
```
/artemisia-annua-rna-seq-project
├── env/             # Conda environments
├── scripts/         # Pipeline scripts
├── notebooks/       # Analysis and exploration. (WIP as of 5/8/2026)
├── data
| └── metadata/      # Sample metadata (tracked)
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