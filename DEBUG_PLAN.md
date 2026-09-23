# RNA-seq Pipeline — Debug & Testing Plan

A bottom-up testing approach: verify each individual script works before testing the wrapper that calls them. This isolates problems — if something breaks later, you'll already know it's not the underlying logic, it's the wiring (argument passing, paths, variable scoping).

**The rule for every phase: the bar for "done" is narrow and binary.** Did it run without error, and does the expected output file exist? That's it. Not "is it perfect."

---

## Phase 1 — One script, one sample, manually

Run each script directly from the terminal with one sample's values, no wrapper involved. Check off each one as it produces its expected output. Do this across as many sessions as needed — there's no requirement to batch them.

- [x] `setup_environment.sh` — ran, output exists in bioinformatics manager environment on around 6/21/2026
- [x] `get_fastq_files.sh` — ran, output exists in `raw_data/` on around 6/21/2026
- [x] `get_reference_genome.sh` — ran, output exists in `reference/` on around 6/21/2026
- [x] `subsample.sh` — ran, output exists in `subsampled_data/`
- [x] `setup_annotation.sh` — ran, output exists in `reference/eggnog_db`on 9/12/2026
  - [x] successfully ran with the command on 6/22/2026: 

        ```bash
        bash scripts/subsample.sh SRR6808226 ~/artemisia-annua-rna-seq-project/raw_data/SRR6808226_1.fastq ~/artemisia-annua-rna-seq-project/raw_data/SRR6808226_2.fastq ~/artemisia-annua-rna-seq-project/subsampled_data/ 1000000
        ```

- [x] `qc_raw.sh` — ran, output exists in `qc_reports/fastqc_raw/`
  - [x] successfully ran with the command on 6/23/2026: 
    
        ```bash
        bash scripts/qc_raw.sh SRR6808226 ~/artemisia-annua-rna-seq-project/raw_data/SRR6808226_1.fastq ~/artemisia-annua-rna-seq-project/raw_data/SRR6808226_2.fastq ~/artemisia-annua-rna-seq-project/qc_reports/fastqc_raw 8 /home/nyssa/miniforge3/envs/genomics/bin/fastqc
        ```
  - find the executable path:  `mamba run -n genomics which fastqc
/home/nyssa/miniforge3/envs/genomics/bin/fastqc`

- [x] `trim.sh` — ran, output exists in `trimmed_data/` and `qc_reports/fastp/`
  - [x] successfully ran with this command on 6/23/2026: 

        ```bash
        bash scripts/trim.sh SRR6808226 ~/artemisia-annua-rna-seq-project/raw_data/SRR6808226_1.fastq ~/artemisia-annua-rna-seq-project/raw_data/SRR6808226_2.fastq ~/artemisia-annua-rna-seq-project/trimmed_data  ~/artemisia-annua-rna-seq-project/qc_reports/fastp 8 36 20 40 /home/nyssa/miniforge3/envs/genomics/bin/fastp
        ```

        output: 

        ```bash
        (genomics) nyssa@nyssa-laptop:~/artemisia-annua-rna-seq-project$ bash scripts/trim.sh SRR6808226 ~/artemisia-annua-rna-seq-project/raw_data/SRR6808226_1.fastq ~/artemisia-annua-rna-seq-project/raw_data/SRR6808226_2.fastq ~/artemisia-annua-rna-seq-project/trimmed_data  ~/artemisia-annua-rna-seq-project/qc_reports/fastp 8 36 20 40 /home/nyssa/miniforge3/envs/genomics/bin/fastp
        
        Detecting adapter sequence for read1...
        No adapter detected for read1

        Detecting adapter sequence for read2...
        No adapter detected for read2

        Read1 before filtering:                                                          
        total reads: 26458482
        total bases: 3968772300
        Q20 bases: 3896022392(98.1669%)
        Q30 bases: 3763560116(94.8293%)
        Q40 bases: 3155988585(79.5205%)

        Read2 before filtering:
        total reads: 26458482
        total bases: 3968772300
        Q20 bases: 3849831861(97.0031%)
        Q30 bases: 3665700609(92.3636%)
        Q40 bases: 2978293069(75.0432%)

        Read1 after filtering:
        total reads: 26263528
        total bases: 3932457808
        Q20 bases: 3866649658(98.3265%)
        Q30 bases: 3741221905(95.137%)
        Q40 bases: 3145365420(79.9847%)

        Read2 after filtering:
        total reads: 26263528
        total bases: 3932457808
        Q20 bases: 3828585235(97.3586%)
        Q30 bases: 3653215723(92.899%)
        Q40 bases: 2973570096(75.6161%)

        Filtering result:
        reads passed filter: 52527056
        reads failed due to low quality: 379768
        reads failed due to too many N: 0
        reads failed due to too short: 10140
        reads failed due to adapter dimer: 0
        reads with adapter trimmed: 584098
        bases trimmed due to adapters: 15337078

        Duplication rate: 13.2205%

        Insert size peak (evaluated by paired-end reads): 256

        JSON report: /home/nyssa/artemisia-annua-rna-seq-project/qc_reports/fastp/SRR6808226_fastp.json
        HTML report: /home/nyssa/artemisia-annua-rna-seq-project/qc_reports/fastp/SRR6808226_fastp.html
        ```

- [x] `qc_trimmed.sh` — ran, output exists in `qc_reports/fastqc_trimmed/`
   - [x] successfully ran with this command on 6/27/2026: 

         ```bash
         bash scripts/qc_trimmed.sh SRR6808226 ~/artemisia-annua-rna-seq-project/trimmed_data/ ~/artemisia-annua-rna-seq-project/qc_reports/fastqc_trimmed/ 8 /home/nyssa/miniforge3/envs/genomics/bin/fastqc
         ```
- [x] `build_star_index.sh` - ran, index files exists in `reference/star_index`
   - [x] ran successfuly with this command on 6/27/2026: 

         ```bash
         bash scripts/build_star_index.sh ~/artemisia-annua-rna-seq-project/reference/star_index  ~/artemisia-annua-rna-seq-project/reference/GCA_003112345.1_ASM311234v1_genomic.fna ~/artemisia-annua-rna-seq-project/reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 149 14 /home/nyssa/miniforge3/envs/genomics/bin/STAR
         ```
- [x] `align.sh` — ran, BAM exists in `alignment/<sample_id>/`
   - [x] ran successfully with this command on 6/27/2026: 

         ```bash
         bash scripts/align.sh SRR6808226 ~/artemisia-annua-rna-seq-project/trimmed_data/ ~/artemisia-annua-rna-seq-project/alignment ~/artemisia-annua-rna-seq-project/reference/star_index ~/artemisia-annua-rna-seq-project/reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 "BAM SortedByCoordinate" "NH HI AS NM" "NoSharedMemory" /home/nyssa/miniforge3/envs/genomics/bin/STAR
         ```
   - [x] re-ran successfully with this command on 6/30/2026: 

        ```bash
        bash scripts/align.sh SRR6808226 ~/artemisia-annua-rna-seq-project/trimmed_data/ ~/arte
        misia-annua-rna-seq-project/alignment ~/artemisia-annua-rna-seq-project/reference/star_index ~/artemisia-annua-rna-seq-project/reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 "BAM SortedByCoordinate" "NH HI AS NM" "NoSharedMemory" "TranscriptomeSAM"  /home/nyssa/miniforge3/envs/genomics/bin/STAR
        ```

        had to do so because of this error: 

        ```bash
        (genomics) nyssa@nyssa-laptop:~/artemisia-annua-rna-seq-project$ bash scripts/quantify.sh SRR6808226 ~/artemisia-annua-rna-seq-project/alignment/ ~/artemisia-annua-rna-seq-project/salmon_quant/ ~/artemisia-annua-rna-seq-project/reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna ~/artemisia-annua-rna-seq-project/reference/GCA_003112345.1_ASM311234v1_genomic.gtf A 8 /home/nyssa/miniforge3/envs/genomics/bin/salmon
        2026-06-30T18:28:37.008457Z  WARN salmon: --validateMappings has no effect (deprecated in salmon too): selective alignment is the default mapping mode; pass --sketch for pseudoalignment.
        Error: alignment-based quantification failed
        Caused by:
        the input BAM/SAM appears to be coordinate-sorted (@HD SO:coordinate) and is not grouped by read name (GO:query). Alignment-mode quantification requires that all alignment records of a read (or read pair) are adjacent in the file. Please collate it by read name first, e.g. samtools collate or samtools sort -n.
        ```
        troubleshooted here: [https://claude.ai/chat/fd4922c2-4bb4-47bb-b41b-2c16ef95e54c](https://claude.ai/chat/fd4922c2-4bb4-47bb-b41b-2c16ef95e54c)

- [x] `quantify.sh` — ran, `quant.sf` exists in `salmon_quant/<sample_id>/`
   - [x] ran successfully with this command on 6/30/2026:

         ```bash
         bash scripts/quantify.sh SRR6808226 ~/artemisia-annua-rna-seq-project/alignment/ ~/artemisia-annua-rna-seq-project/salmon_quant/ ~/artemisia-annua-rna-seq-project/reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna ~/artemisia-annua-rna-seq-project/reference/GCA_003112345.1_ASM311234v1_genomic.gtf A 8 /home/nyssa/miniforge3/envs/genomics/bin/salmon
         ```
- [x] `count.sh` — ran, counts matrix exists (if using the lightweight merge instead of/alongside tximport)
   - [x] ran successfully on 6/30/2026 with this command: 

     ```bash
     bash scripts/count.sh ~/artemisia-annua-rna-seq-project/salmon_quant/ ~/artemisia-annua-rna-seq-project/counts/
     ```
- [x] `tximport.R` — ran, `gene_counts_matrix.csv` and `.rds` exist in `counts/`
   - [x] ran successfully on 7/5/2026 with this command: 

     ```bash
     (genomics) nyssa@nyssa-laptop:~/artemisia-annua-rna-seq-project$ Rscript scripts/tximport.R     --salmon_dir  ~/artemisia-annua-rna-seq-project/salmon_quant/     --gtf         ~/artemisia-annua-rna-seq-project/reference/GCA_003112345.1_ASM311234v1_genomic.gtf     --samples_csv ~/artemisia-annua-rna-seq-project/samples.csv  --samples SRR6808226     --counts_csv  ~/artemisia-annua-rna-seq-project/counts/counts_matrix.csv     --output_dir  ~/artemisia-annua-rna-seq-project/counts/
     [2026-07-05 13:37:36] Starting tximport aggregation 
     [2026-07-05 13:37:36] Salmon directory : /home/nyssa/artemisia-annua-rna-seq-project/salmon_quant/ 
     [2026-07-05 13:37:36] GTF file         : /home/nyssa/artemisia-annua-rna-seq-project/reference/GCA_003112345.1_ASM311234v1_genomic.gtf 
     [2026-07-05 13:37:36] Samples CSV      : /home/nyssa/artemisia-annua-rna-seq-project/samples.csv 
     [2026-07-05 13:37:36] counts_matrix.csv: /home/nyssa/artemisia-annua-rna-seq-project/counts/counts_matrix.csv 
     [2026-07-05 13:37:36] Output directory : /home/nyssa/artemisia-annua-rna-seq-project/counts/ 
     [2026-07-05 13:37:36] Loading sample manifest... 
     [2026-07-05 13:37:36] Filtering to 1 requested sample(s): SRR6808226 
     [2026-07-05 13:37:36] Found quant.sf files for 1 samples: SRR6808226 
     [2026-07-05 13:37:36] Cross-checking against count.sh counts_matrix.csv... 
     [2026-07-05 13:37:36] Cross-checking against count.sh counts_matrix.csv... 
     [2026-07-05 13:37:36] Cross-check passed: both sources agree on 1 samples 
     [2026-07-05 13:37:36] Building tx2gene mapping from GTF... 
     [2026-07-05 13:37:36] (This may take a few minutes for large or fragmented GTF files) 
     [2026-07-05 13:37:43] tx2gene built: 66918 transcripts → 63226 unique genes 
     [2026-07-05 13:37:43] tx2gene saved: /home/nyssa/artemisia-annua-rna-seq-project/counts//tx2gene.csv 
     [2026-07-05 13:37:43] Running tximport... 
     reading in files with read_tsv
     1 
     summarizing abundance
     summarizing counts
     summarizing length
     [2026-07-05 13:37:44] Saving outputs... 
     [2026-07-05 13:37:44] Gene counts matrix saved: /home/nyssa/artemisia-annua-rna-seq-project/counts//gene_counts_matrix.csv 
     [2026-07-05 13:37:44] TPM matrix saved: /home/nyssa/artemisia-annua-rna-seq-project/counts//gene_tpm_matrix.csv 
     [2026-07-05 13:37:45] tximport object (.rds) saved: /home/nyssa/artemisia-annua-rna-seq-project/counts//tximport_object.rds 
     === tximport summary ===
     Genes            : 63226
     Samples          : 1
     Genes all-zero   : 49.9% (filtered automatically in DESeq2)
     Scaling method   : lengthScaledTPM

     Outputs (in /home/nyssa/artemisia-annua-rna-seq-project/counts/):
       gene_counts_matrix.csv  — gene-level counts for DESeq2 (CSV)
       gene_tpm_matrix.csv     — gene-level TPM for visualisation (CSV)
       tximport_object.rds     — full txi object (preferred DESeq2 input)
       tx2gene.csv             — transcript → gene mapping used
       tximport_summary.txt    — this summary

     Relationship to count.sh output:
       counts_matrix.csv       — transcript-level, raw NumReads (inspection only)
       gene_counts_matrix.csv  — gene-level, length-corrected (DESeq2 input)
     ========================
     [2026-07-05 13:37:45] tximport complete. 

- [x] `multiqc.sh` — ran, HTML report exists in `results/multiqc/`
   - [x] ran successfully with this command on 7/5/2026: 

         ```bash
         bash scripts/multiqc.sh ~/artemisia-annua-rna-seq-project/qc_reports/fastqc_raw/ ~/artemisia-annua-rna-seq-project/qc_reports/fastqc_trimmed/ ~/artemisia-annua-rna-seq-project/qc_reports/fastp/ ~/artemisia-annua-rna-seq-project/alignment/ ~/artemisia-annua-rna-seq-project/salmon_quant/ ~/artemisia-annua-rna-seq-project/results/tables/ /home/nyssa/miniforge3/envs/genomics/bin/multiqc

         /// MultiQC 🔍 v1.33

         version_check | MultiQC Version v1.35 now available!
           file_search | Search path: /home/nyssa/artemisia-annua-rna-seq-project/qc_reports/fastqc_raw
           file_search | Search path: /home/nyssa/artemisia-annua-rna-seq-project/qc_reports/fastqc_trimmed
           file_search | Search path: /home/nyssa/artemisia-annua-rna-seq-project/qc_reports/fastp
           file_search | Search path: /home/nyssa/artemisia-annua-rna-seq-project/alignment
           file_search | Search path: /home/nyssa/artemisia-annua-rna-seq-project/salmon_quant
             searching | ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100% 39/39  
                salmon | Found 1 meta reports
                salmon | Found 1 fragment length distributions
                star | Found 1 reports
                fastp | Found 1 reports
                fastqc | Found 4 reports
          write_results | Data        : results/multiqc/multiqc_data
          write_results | Report      : results/multiqc/multiqc_report.html
            multiqc | MultiQC complete
         [multiqc] report written to /home/nyssa/artemisia-annua-rna-seq-project/results/multiqc
        ```

- [x] `annotate.sh` — ran, HTML report exists in `results/multiqc/`
   - [x] ran successfully with this command on 9/12/2026: 

        ```bash
        
        ```

**Example command for this phase** (adjust args per script):
```bash
bash scripts/qc_raw.sh ctrl_1 raw_data/ctrl_1_R1.fastq.gz raw_data/ctrl_1_R2.fastq.gz qc_reports/fastqc_raw/ 8 fastqc
```

> If a script fails here, the debugging scope is just that script with hardcoded inputs — not "something's wrong with my whole pipeline." Keep the scope contained to the one script in front of you.

### Notes: 
- no inline # comments inside any \ continuation block, ever — applies to STAR, mamba, or any multi-line command.

---

## Phase 2 — Dry run the wrapper (zero risk)

Nothing executes here — only commands get printed. Nothing can break.

```bash
bash run_pipeline.sh --dry-run
```

**Check:** do the printed commands match what you ran manually in Phase 1? Look at paths and argument order specifically.

- [x] Dry run completes without error
- [x] Printed commands for each step match what worked manually in Phase 1

      ```bash
      (genomics) nyssa@nyssa-laptop:~/artemisia-annua-rna-seq-project$ bash run_pipeline.sh --dry-run
      2026-07-10 16:45:40 [INFO] Config sourced: config.sh
      2026-07-10 16:45:40 [INFO] Log file: logs//pipeline.log
      2026-07-10 16:45:40 [INFO] Loaded 15 samples(s) from samples.csv
      2026-07-10 16:45:40 [INFO] --- DRY RUN: commands will be printed but not executed ---
      2026-07-10 16:45:41 [INFO] Steps    : all
      2026-07-10 16:45:41 [INFO] Samples  : SRR6808226 SRR6808227 SRR6808228 SRR6808229 SRR6808230 SRR6808231 SRR6808232 SRR6808233 SRR6808234 SRR6808235 SRR6808236 SRR6808237 SRR6808238 SRR6808239 SRR6808240
      2026-07-10 16:45:41 [INFO] --- Sample: SRR6808226 (blue) ---
      2026-07-10 16:45:41 [INFO] >>> [subsample] SRR6808226
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/subsample.sh SRR6808226 raw_data/SRR6808226_2.fastq  subsampled_data/ 1000000
      2026-07-10 16:45:41 [INFO] >>> [qc_raw] SRR6808226
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/qc_raw.sh SRR6808226 raw_data/SRR6808226_2.fastq  qc_reports/fastqc_raw/ 8 fastqc
      2026-07-10 16:45:41 [INFO] >>> [trim] SRR6808226
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/trim.sh SRR6808226 raw_data/SRR6808226_2.fastq  trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
      2026-07-10 16:45:41 [INFO] >>> [qc_trimmed] SRR6808226
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/qc_trimmed.sh SRR6808226 trimmed_data/ qc_reports/fastqc_trimmed/ 8 fastqc
      2026-07-10 16:45:41 [INFO] >>> [align] SRR6808226
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/align.sh SRR6808226 trimmed_data/ alignment/ reference/star_index/ reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 "BAM SortedByCoordinate" NH HI AS NM NoSharedMemory TranscriptomeSAM STAR
      2026-07-10 16:45:41 [INFO] >>> [quantify] SRR6808226
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/quantify.sh SRR6808226 alignment/ salmon_quant reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna reference/GCA_003112345.1_ASM311234v1_genomic.gtf A 8 salmon
      2026-07-10 16:45:41 [INFO] --- Sample: SRR6808227 (blue) ---
      2026-07-10 16:45:41 [INFO] >>> [subsample] SRR6808227
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/subsample.sh SRR6808227 raw_data/SRR6808227_2.fastq  subsampled_data/ 1000000
      2026-07-10 16:45:41 [INFO] >>> [qc_raw] SRR6808227
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/qc_raw.sh SRR6808227 raw_data/SRR6808227_2.fastq  qc_reports/fastqc_raw/ 8 fastqc
      2026-07-10 16:45:41 [INFO] >>> [trim] SRR6808227
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/trim.sh SRR6808227 raw_data/SRR6808227_2.fastq  trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
      2026-07-10 16:45:41 [INFO] >>> [qc_trimmed] SRR6808227
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/qc_trimmed.sh SRR6808227 trimmed_data/ qc_reports/fastqc_trimmed/ 8 fastqc
      2026-07-10 16:45:41 [INFO] >>> [align] SRR6808227
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/align.sh SRR6808227 trimmed_data/ alignment/ reference/star_index/ reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 "BAM SortedByCoordinate" NH HI AS NM NoSharedMemory TranscriptomeSAM STAR
      2026-07-10 16:45:41 [INFO] >>> [quantify] SRR6808227
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/quantify.sh SRR6808227 alignment/ salmon_quant reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna reference/GCA_003112345.1_ASM311234v1_genomic.gtf A 8 salmon
      2026-07-10 16:45:41 [INFO] --- Sample: SRR6808228 (blue) ---
      2026-07-10 16:45:41 [INFO] >>> [subsample] SRR6808228
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/subsample.sh SRR6808228 raw_data/SRR6808228_2.fastq  subsampled_data/ 1000000
      2026-07-10 16:45:41 [INFO] >>> [qc_raw] SRR6808228
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/qc_raw.sh SRR6808228 raw_data/SRR6808228_2.fastq  qc_reports/fastqc_raw/ 8 fastqc
      2026-07-10 16:45:41 [INFO] >>> [trim] SRR6808228
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/trim.sh SRR6808228 raw_data/SRR6808228_2.fastq  trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
      2026-07-10 16:45:41 [INFO] >>> [qc_trimmed] SRR6808228
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/qc_trimmed.sh SRR6808228 trimmed_data/ qc_reports/fastqc_trimmed/ 8 fastqc
      2026-07-10 16:45:41 [INFO] >>> [align] SRR6808228
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/align.sh SRR6808228 trimmed_data/ alignment/ reference/star_index/ reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 "BAM SortedByCoordinate" NH HI AS NM NoSharedMemory TranscriptomeSAM STAR
      2026-07-10 16:45:41 [INFO] >>> [quantify] SRR6808228
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/quantify.sh SRR6808228 alignment/ salmon_quant reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna reference/GCA_003112345.1_ASM311234v1_genomic.gtf A 8 salmon
      2026-07-10 16:45:41 [INFO] --- Sample: SRR6808229 (red) ---
      2026-07-10 16:45:41 [INFO] >>> [subsample] SRR6808229
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/subsample.sh SRR6808229 raw_data/SRR6808229_2.fastq  subsampled_data/ 1000000
      2026-07-10 16:45:41 [INFO] >>> [qc_raw] SRR6808229
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/qc_raw.sh SRR6808229 raw_data/SRR6808229_2.fastq  qc_reports/fastqc_raw/ 8 fastqc
      2026-07-10 16:45:41 [INFO] >>> [trim] SRR6808229
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/trim.sh SRR6808229 raw_data/SRR6808229_2.fastq  trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
      2026-07-10 16:45:41 [INFO] >>> [qc_trimmed] SRR6808229
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/qc_trimmed.sh SRR6808229 trimmed_data/ qc_reports/fastqc_trimmed/ 8 fastqc
      2026-07-10 16:45:41 [INFO] >>> [align] SRR6808229
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/align.sh SRR6808229 trimmed_data/ alignment/ reference/star_index/ reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 "BAM SortedByCoordinate" NH HI AS NM NoSharedMemory TranscriptomeSAM STAR
      2026-07-10 16:45:41 [INFO] >>> [quantify] SRR6808229
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/quantify.sh SRR6808229 alignment/ salmon_quant reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna reference/GCA_003112345.1_ASM311234v1_genomic.gtf A 8 salmon
      2026-07-10 16:45:41 [INFO] --- Sample: SRR6808230 (red) ---
      2026-07-10 16:45:41 [INFO] >>> [subsample] SRR6808230
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/subsample.sh SRR6808230 raw_data/SRR6808230_2.fastq  subsampled_data/ 1000000
      2026-07-10 16:45:41 [INFO] >>> [qc_raw] SRR6808230
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/qc_raw.sh SRR6808230 raw_data/SRR6808230_2.fastq  qc_reports/fastqc_raw/ 8 fastqc
      2026-07-10 16:45:41 [INFO] >>> [trim] SRR6808230
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/trim.sh SRR6808230 raw_data/SRR6808230_2.fastq  trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
      2026-07-10 16:45:41 [INFO] >>> [qc_trimmed] SRR6808230
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/qc_trimmed.sh SRR6808230 trimmed_data/ qc_reports/fastqc_trimmed/ 8 fastqc
      2026-07-10 16:45:41 [INFO] >>> [align] SRR6808230
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/align.sh SRR6808230 trimmed_data/ alignment/ reference/star_index/ reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 "BAM SortedByCoordinate" NH HI AS NM NoSharedMemory TranscriptomeSAM STAR
      2026-07-10 16:45:41 [INFO] >>> [quantify] SRR6808230
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/quantify.sh SRR6808230 alignment/ salmon_quant reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna reference/GCA_003112345.1_ASM311234v1_genomic.gtf A 8 salmon
      2026-07-10 16:45:41 [INFO] --- Sample: SRR6808231 (white) ---
      2026-07-10 16:45:41 [INFO] >>> [subsample] SRR6808231
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/subsample.sh SRR6808231 raw_data/SRR6808231_2.fastq  subsampled_data/ 1000000
      2026-07-10 16:45:41 [INFO] >>> [qc_raw] SRR6808231
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/qc_raw.sh SRR6808231 raw_data/SRR6808231_2.fastq  qc_reports/fastqc_raw/ 8 fastqc
      2026-07-10 16:45:41 [INFO] >>> [trim] SRR6808231
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/trim.sh SRR6808231 raw_data/SRR6808231_2.fastq  trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
      2026-07-10 16:45:41 [INFO] >>> [qc_trimmed] SRR6808231
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/qc_trimmed.sh SRR6808231 trimmed_data/ qc_reports/fastqc_trimmed/ 8 fastqc
      2026-07-10 16:45:41 [INFO] >>> [align] SRR6808231
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/align.sh SRR6808231 trimmed_data/ alignment/ reference/star_index/ reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 "BAM SortedByCoordinate" NH HI AS NM NoSharedMemory TranscriptomeSAM STAR
      2026-07-10 16:45:41 [INFO] >>> [quantify] SRR6808231
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/quantify.sh SRR6808231 alignment/ salmon_quant reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna reference/GCA_003112345.1_ASM311234v1_genomic.gtf A 8 salmon
      2026-07-10 16:45:41 [INFO] --- Sample: SRR6808232 (white) ---
      2026-07-10 16:45:41 [INFO] >>> [subsample] SRR6808232
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/subsample.sh SRR6808232 raw_data/SRR6808232_2.fastq  subsampled_data/ 1000000
      2026-07-10 16:45:41 [INFO] >>> [qc_raw] SRR6808232
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/qc_raw.sh SRR6808232 raw_data/SRR6808232_2.fastq  qc_reports/fastqc_raw/ 8 fastqc
      2026-07-10 16:45:41 [INFO] >>> [trim] SRR6808232
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/trim.sh SRR6808232 raw_data/SRR6808232_2.fastq  trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
      2026-07-10 16:45:41 [INFO] >>> [qc_trimmed] SRR6808232
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/qc_trimmed.sh SRR6808232 trimmed_data/ qc_reports/fastqc_trimmed/ 8 fastqc
      2026-07-10 16:45:41 [INFO] >>> [align] SRR6808232
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/align.sh SRR6808232 trimmed_data/ alignment/ reference/star_index/ reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 "BAM SortedByCoordinate" NH HI AS NM NoSharedMemory TranscriptomeSAM STAR
      2026-07-10 16:45:41 [INFO] >>> [quantify] SRR6808232
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/quantify.sh SRR6808232 alignment/ salmon_quant reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna reference/GCA_003112345.1_ASM311234v1_genomic.gtf A 8 salmon
      2026-07-10 16:45:41 [INFO] --- Sample: SRR6808233 (far_red) ---
      2026-07-10 16:45:41 [INFO] >>> [subsample] SRR6808233
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/subsample.sh SRR6808233 raw_data/SRR6808233_2.fastq  subsampled_data/ 1000000
      2026-07-10 16:45:41 [INFO] >>> [qc_raw] SRR6808233
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/qc_raw.sh SRR6808233 raw_data/SRR6808233_2.fastq  qc_reports/fastqc_raw/ 8 fastqc
      2026-07-10 16:45:41 [INFO] >>> [trim] SRR6808233
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/trim.sh SRR6808233 raw_data/SRR6808233_2.fastq  trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
      2026-07-10 16:45:41 [INFO] >>> [qc_trimmed] SRR6808233
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/qc_trimmed.sh SRR6808233 trimmed_data/ qc_reports/fastqc_trimmed/ 8 fastqc
      2026-07-10 16:45:41 [INFO] >>> [align] SRR6808233
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/align.sh SRR6808233 trimmed_data/ alignment/ reference/star_index/ reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 "BAM SortedByCoordinate" NH HI AS NM NoSharedMemory TranscriptomeSAM STAR
      2026-07-10 16:45:41 [INFO] >>> [quantify] SRR6808233
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/quantify.sh SRR6808233 alignment/ salmon_quant reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna reference/GCA_003112345.1_ASM311234v1_genomic.gtf A 8 salmon
      2026-07-10 16:45:41 [INFO] --- Sample: SRR6808234 (far_red) ---
      2026-07-10 16:45:41 [INFO] >>> [subsample] SRR6808234
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/subsample.sh SRR6808234 raw_data/SRR6808234_2.fastq  subsampled_data/ 1000000
      2026-07-10 16:45:41 [INFO] >>> [qc_raw] SRR6808234
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/qc_raw.sh SRR6808234 raw_data/SRR6808234_2.fastq  qc_reports/fastqc_raw/ 8 fastqc
      2026-07-10 16:45:41 [INFO] >>> [trim] SRR6808234
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/trim.sh SRR6808234 raw_data/SRR6808234_2.fastq  trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
      2026-07-10 16:45:41 [INFO] >>> [qc_trimmed] SRR6808234
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/qc_trimmed.sh SRR6808234 trimmed_data/ qc_reports/fastqc_trimmed/ 8 fastqc
      2026-07-10 16:45:41 [INFO] >>> [align] SRR6808234
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/align.sh SRR6808234 trimmed_data/ alignment/ reference/star_index/ reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 "BAM SortedByCoordinate" NH HI AS NM NoSharedMemory TranscriptomeSAM STAR
      2026-07-10 16:45:41 [INFO] >>> [quantify] SRR6808234
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/quantify.sh SRR6808234 alignment/ salmon_quant reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna reference/GCA_003112345.1_ASM311234v1_genomic.gtf A 8 salmon
      2026-07-10 16:45:41 [INFO] --- Sample: SRR6808235 (dark) ---
      2026-07-10 16:45:41 [INFO] >>> [subsample] SRR6808235
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/subsample.sh SRR6808235 raw_data/SRR6808235_2.fastq  subsampled_data/ 1000000
      2026-07-10 16:45:41 [INFO] >>> [qc_raw] SRR6808235
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/qc_raw.sh SRR6808235 raw_data/SRR6808235_2.fastq  qc_reports/fastqc_raw/ 8 fastqc
      2026-07-10 16:45:41 [INFO] >>> [trim] SRR6808235
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/trim.sh SRR6808235 raw_data/SRR6808235_2.fastq  trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
      2026-07-10 16:45:41 [INFO] >>> [qc_trimmed] SRR6808235
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/qc_trimmed.sh SRR6808235 trimmed_data/ qc_reports/fastqc_trimmed/ 8 fastqc
      2026-07-10 16:45:41 [INFO] >>> [align] SRR6808235
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/align.sh SRR6808235 trimmed_data/ alignment/ reference/star_index/ reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 "BAM SortedByCoordinate" NH HI AS NM NoSharedMemory TranscriptomeSAM STAR
      2026-07-10 16:45:41 [INFO] >>> [quantify] SRR6808235
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/quantify.sh SRR6808235 alignment/ salmon_quant reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna reference/GCA_003112345.1_ASM311234v1_genomic.gtf A 8 salmon
      2026-07-10 16:45:41 [INFO] --- Sample: SRR6808236 (far_red) ---
      2026-07-10 16:45:41 [INFO] >>> [subsample] SRR6808236
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/subsample.sh SRR6808236 raw_data/SRR6808236_2.fastq  subsampled_data/ 1000000
      2026-07-10 16:45:41 [INFO] >>> [qc_raw] SRR6808236
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/qc_raw.sh SRR6808236 raw_data/SRR6808236_2.fastq  qc_reports/fastqc_raw/ 8 fastqc
      2026-07-10 16:45:41 [INFO] >>> [trim] SRR6808236
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/trim.sh SRR6808236 raw_data/SRR6808236_2.fastq  trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
      2026-07-10 16:45:41 [INFO] >>> [qc_trimmed] SRR6808236
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/qc_trimmed.sh SRR6808236 trimmed_data/ qc_reports/fastqc_trimmed/ 8 fastqc
      2026-07-10 16:45:41 [INFO] >>> [align] SRR6808236
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/align.sh SRR6808236 trimmed_data/ alignment/ reference/star_index/ reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 "BAM SortedByCoordinate" NH HI AS NM NoSharedMemory TranscriptomeSAM STAR
      2026-07-10 16:45:41 [INFO] >>> [quantify] SRR6808236
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/quantify.sh SRR6808236 alignment/ salmon_quant reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna reference/GCA_003112345.1_ASM311234v1_genomic.gtf A 8 salmon
      2026-07-10 16:45:41 [INFO] --- Sample: SRR6808237 (dark) ---
      2026-07-10 16:45:41 [INFO] >>> [subsample] SRR6808237
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/subsample.sh SRR6808237 raw_data/SRR6808237_2.fastq  subsampled_data/ 1000000
      2026-07-10 16:45:41 [INFO] >>> [qc_raw] SRR6808237
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/qc_raw.sh SRR6808237 raw_data/SRR6808237_2.fastq  qc_reports/fastqc_raw/ 8 fastqc
      2026-07-10 16:45:41 [INFO] >>> [trim] SRR6808237
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/trim.sh SRR6808237 raw_data/SRR6808237_2.fastq  trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
      2026-07-10 16:45:41 [INFO] >>> [qc_trimmed] SRR6808237
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/qc_trimmed.sh SRR6808237 trimmed_data/ qc_reports/fastqc_trimmed/ 8 fastqc
      2026-07-10 16:45:41 [INFO] >>> [align] SRR6808237
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/align.sh SRR6808237 trimmed_data/ alignment/ reference/star_index/ reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 "BAM SortedByCoordinate" NH HI AS NM NoSharedMemory TranscriptomeSAM STAR
      2026-07-10 16:45:41 [INFO] >>> [quantify] SRR6808237
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/quantify.sh SRR6808237 alignment/ salmon_quant reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna reference/GCA_003112345.1_ASM311234v1_genomic.gtf A 8 salmon
      2026-07-10 16:45:41 [INFO] --- Sample: SRR6808238 (dark) ---
      2026-07-10 16:45:41 [INFO] >>> [subsample] SRR6808238
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/subsample.sh SRR6808238 raw_data/SRR6808238_2.fastq  subsampled_data/ 1000000
      2026-07-10 16:45:41 [INFO] >>> [qc_raw] SRR6808238
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/qc_raw.sh SRR6808238 raw_data/SRR6808238_2.fastq  qc_reports/fastqc_raw/ 8 fastqc
      2026-07-10 16:45:41 [INFO] >>> [trim] SRR6808238
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/trim.sh SRR6808238 raw_data/SRR6808238_2.fastq  trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
      2026-07-10 16:45:41 [INFO] >>> [qc_trimmed] SRR6808238
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/qc_trimmed.sh SRR6808238 trimmed_data/ qc_reports/fastqc_trimmed/ 8 fastqc
      2026-07-10 16:45:41 [INFO] >>> [align] SRR6808238
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/align.sh SRR6808238 trimmed_data/ alignment/ reference/star_index/ reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 "BAM SortedByCoordinate" NH HI AS NM NoSharedMemory TranscriptomeSAM STAR
      2026-07-10 16:45:41 [INFO] >>> [quantify] SRR6808238
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/quantify.sh SRR6808238 alignment/ salmon_quant reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna reference/GCA_003112345.1_ASM311234v1_genomic.gtf A 8 salmon
      2026-07-10 16:45:41 [INFO] --- Sample: SRR6808239 (white) ---
      2026-07-10 16:45:41 [INFO] >>> [subsample] SRR6808239
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/subsample.sh SRR6808239 raw_data/SRR6808239_2.fastq  subsampled_data/ 1000000
      2026-07-10 16:45:41 [INFO] >>> [qc_raw] SRR6808239
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/qc_raw.sh SRR6808239 raw_data/SRR6808239_2.fastq  qc_reports/fastqc_raw/ 8 fastqc
      2026-07-10 16:45:41 [INFO] >>> [trim] SRR6808239
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/trim.sh SRR6808239 raw_data/SRR6808239_2.fastq  trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
      2026-07-10 16:45:41 [INFO] >>> [qc_trimmed] SRR6808239
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/qc_trimmed.sh SRR6808239 trimmed_data/ qc_reports/fastqc_trimmed/ 8 fastqc
      2026-07-10 16:45:41 [INFO] >>> [align] SRR6808239
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/align.sh SRR6808239 trimmed_data/ alignment/ reference/star_index/ reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 "BAM SortedByCoordinate" NH HI AS NM NoSharedMemory TranscriptomeSAM STAR
      2026-07-10 16:45:41 [INFO] >>> [quantify] SRR6808239
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/quantify.sh SRR6808239 alignment/ salmon_quant reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna reference/GCA_003112345.1_ASM311234v1_genomic.gtf A 8 salmon
      2026-07-10 16:45:41 [INFO] --- Sample: SRR6808240 (red) ---
      2026-07-10 16:45:41 [INFO] >>> [subsample] SRR6808240
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/subsample.sh SRR6808240 raw_data/SRR6808240_2.fastq  subsampled_data/ 1000000
      2026-07-10 16:45:41 [INFO] >>> [qc_raw] SRR6808240
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/qc_raw.sh SRR6808240 raw_data/SRR6808240_2.fastq  qc_reports/fastqc_raw/ 8 fastqc
      2026-07-10 16:45:41 [INFO] >>> [trim] SRR6808240
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/trim.sh SRR6808240 raw_data/SRR6808240_2.fastq  trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
      2026-07-10 16:45:41 [INFO] >>> [qc_trimmed] SRR6808240
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/qc_trimmed.sh SRR6808240 trimmed_data/ qc_reports/fastqc_trimmed/ 8 fastqc
      2026-07-10 16:45:41 [INFO] >>> [align] SRR6808240
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/align.sh SRR6808240 trimmed_data/ alignment/ reference/star_index/ reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 "BAM SortedByCoordinate" NH HI AS NM NoSharedMemory TranscriptomeSAM STAR
      2026-07-10 16:45:41 [INFO] >>> [quantify] SRR6808240
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/quantify.sh SRR6808240 alignment/ salmon_quant reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna reference/GCA_003112345.1_ASM311234v1_genomic.gtf A 8 salmon
      2026-07-10 16:45:41 [INFO] >>> [count]
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/count.sh salmon_quant counts/
      2026-07-10 16:45:41 [INFO] >>> [tximport]
      2026-07-10 16:45:41 [INFO] CMD: Rscript scripts/tximport.R             --salmon_dir  salmon_quant             --gtf         reference/GCA_003112345.1_ASM311234v1_genomic.gtf             --samples_csv samples.csv             --samples     SRR6808226,SRR6808227,SRR6808228,SRR6808229,SRR6808230,SRR6808231,SRR6808232,SRR6808233,SRR6808234,SRR6808235,SRR6808236,SRR6808237,SRR6808238,SRR6808239,SRR6808240             --counts_csv  counts//counts_matrix.csv             --output_dir  counts/
      2026-07-10 16:45:41 [INFO] >>> [multiqc]
      2026-07-10 16:45:41 [INFO] CMD: bash scripts/multiqc.sh qc_reports/fastqc_raw/ qc_reports/fastqc_trimmed/ qc_reports/fastp alignment/ salmon_quant results//tables/ multiqc
      2026-07-10 16:45:41 [INFO] Pipeline complete.
      ```

> If something looks off here, you're debugging string construction in the wrapper (`config.sh` values, argument order) — not bioinformatics.

---

## Phase 3 — Wrapper, one step, one sample

Same narrow scope as Phase 1, just routed through the wrapper now.

```bash
bash run_pipeline.sh --steps qc_raw --samples ctrl_1
```

- [x] Each step runs correctly through the wrapper for one sample
  - [x] subsample
        ran succesfully on 7/11/2026:

        ```bash
        (genomics) nyssa@nyssa-laptop:~/artemisia-annua-rna-seq-project$ bash run_
        pipeline.sh --steps subsample --samples SRR6808226
        2026-07-11 18:12:35 [INFO] Config sourced: config.sh
        2026-07-11 18:12:35 [INFO] Log file: logs//pipeline.log
        2026-07-11 18:12:35 [INFO] Loaded 15 samples(s) from samples.csv
        2026-07-11 18:12:35 [INFO] Filtered to 1 sample(s): SRR6808226
        2026-07-11 18:12:35 [INFO] Steps    : subsample
        2026-07-11 18:12:35 [INFO] Samples  : SRR6808226
        2026-07-11 18:12:35 [INFO] --- Sample: SRR6808226 (blue) ---
        2026-07-11 18:12:35 [INFO] >>> [subsample] SRR6808226
        2026-07-11 18:12:35 [INFO] CMD: bash scripts/subsample.sh "SRR6808226" "raw_data/SRR6808226_1.fastq" "raw_data/SRR6808226_2.fastq" "subsampled_data/" "1000000"
        2026-07-11 18:13:49 [INFO] Pipeline complete.
        ```
  - [x] qc_raw
        ran successfully on 7/11/2026: 

        ```bash
        (genomics) nyssa@nyssa-laptop:~/artemisia-annua-rna-seq-project$ bash run_pipeline.sh --steps qc_raw --samples SRR6808226
        2026-07-11 18:18:04 [INFO] Config sourced: config.sh
        2026-07-11 18:18:04 [INFO] Log file: logs//pipeline.log
        2026-07-11 18:18:04 [INFO] Loaded 15 samples(s) from samples.csv
        2026-07-11 18:18:04 [INFO] Filtered to 1 sample(s): SRR6808226
        2026-07-11 18:18:04 [INFO] Steps    : qc_raw
        2026-07-11 18:18:04 [INFO] Samples  : SRR6808226
        2026-07-11 18:18:04 [INFO] --- Sample: SRR6808226 (blue) ---
        2026-07-11 18:18:04 [INFO] >>> [qc_raw] SRR6808226
        2026-07-11 18:18:04 [INFO] CMD: bash scripts/qc_raw.sh SRR6808226 raw_data/SRR6808226_1.fastq raw_data/SRR6808226_2.fastq qc_reports/fastqc_raw/ 8 fastqc
        2026-07-11 18:19:56 [INFO] Pipeline complete.
        ```
  - [x] trim
        ran successfully on 7/11/2026: 

        ```bash
        (genomics) nyssa@nyssa-laptop:~/artemisia-annua-rna-seq-project$ bash run_pipeline.sh --steps trim --samples SRR6808226
        2026-07-11 18:22:04 [INFO] Config sourced: config.sh
        2026-07-11 18:22:04 [INFO] Log file: logs//pipeline.log
        2026-07-11 18:22:04 [INFO] Loaded 15 samples(s) from samples.csv
        2026-07-11 18:22:05 [INFO] Filtered to 1 sample(s): SRR6808226
        2026-07-11 18:22:05 [INFO] Steps    : trim
        2026-07-11 18:22:05 [INFO] Samples  : SRR6808226
        2026-07-11 18:22:05 [INFO] --- Sample: SRR6808226 (blue) ---
        2026-07-11 18:22:05 [INFO] >>> [trim] SRR6808226
        2026-07-11 18:22:05 [INFO] CMD: bash scripts/trim.sh SRR6808226 raw_data/SRR6808226_1.fastq raw_data/SRR6808226_2.fastq trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
        2026-07-11 18:25:04 [INFO] Pipeline complete.
        ```
  - [x] qc_trimmed
        ran successfully on 7/11/2026: 

        ```bash
        (genomics) nyssa@nyssa-laptop:~/artemisia-annua-rna-seq-project$ bash run_pipeline.sh --steps qc_trimmed --samples SRR680
        8226
        2026-07-11 18:39:04 [INFO] Config sourced: config.sh
        2026-07-11 18:39:04 [INFO] Log file: logs//pipeline.log
        2026-07-11 18:39:04 [INFO] Loaded 15 samples(s) from samples.csv
        2026-07-11 18:39:04 [INFO] Filtered to 1 sample(s): SRR6808226
        2026-07-11 18:39:04 [INFO] Steps    : qc_trimmed
        2026-07-11 18:39:04 [INFO] Samples  : SRR6808226
        2026-07-11 18:39:04 [INFO] --- Sample: SRR6808226 (blue) ---
        2026-07-11 18:39:04 [INFO] >>> [qc_trimmed] SRR6808226
        2026-07-11 18:39:04 [INFO] CMD: bash scripts/qc_trimmed.sh SRR6808226 trimmed_data/ qc_reports/fastqc_trimmed/ 8 fastqc
        2026-07-11 18:41:23 [INFO] Pipeline complete.
        ```
  - [x] align
        ran successfully on 7/11/2026: 

        ```bash
        (genomics) nyssa@nyssa-laptop:~/artemisia-annua-rna-seq-project$ bash run_pipeline.sh --steps align --samples SRR6808226
        2026-07-11 22:14:22 [INFO] Config sourced: config.sh
        2026-07-11 22:14:22 [INFO] Log file: logs//pipeline.log
        2026-07-11 22:14:22 [INFO] Loaded 15 samples(s) from samples.csv
        2026-07-11 22:14:22 [INFO] Filtered to 1 sample(s): SRR6808226
        2026-07-11 22:14:22 [INFO] Steps    : align
        2026-07-11 22:14:22 [INFO] Samples  : SRR6808226
        2026-07-11 22:14:22 [INFO] --- Sample: SRR6808226 (blue) ---
        2026-07-11 22:14:22 [INFO] >>> [align] SRR6808226
        2026-07-11 22:14:22 [INFO] CMD: bash scripts/align.sh SRR6808226 trimmed_data/ alignment/ reference/star_index/ reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 "BAM SortedByCoordinate" "NH HI AS NM" NoSharedMemory TranscriptomeSAM STAR
        2026-07-11 22:30:35 [INFO] Pipeline complete.
        ```
  - [x] quantify
        ran successfully on 7/11/2026: 

        ```bash
        (genomics) nyssa@nyssa-laptop:~/artemisia-annua-rna-seq-project$ bash run_pipeline.sh --steps quantify --samples SRR6808226
        2026-07-11 22:34:15 [INFO] Config sourced: config.sh
        2026-07-11 22:34:15 [INFO] Log file: logs//pipeline.log
        2026-07-11 22:34:15 [INFO] Loaded 15 samples(s) from samples.csv
        2026-07-11 22:34:15 [INFO] Filtered to 1 sample(s): SRR6808226
        2026-07-11 22:34:15 [INFO] Steps    : quantify
        2026-07-11 22:34:15 [INFO] Samples  : SRR6808226
        2026-07-11 22:34:15 [INFO] --- Sample: SRR6808226 (blue) ---
        2026-07-11 22:34:15 [INFO] >>> [quantify] SRR6808226
        2026-07-11 22:34:15 [INFO] CMD: bash scripts/quantify.sh SRR6808226 alignment/ salmon_quant reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna reference/GCA_003112345.1_ASM311234v1_genomic.gtf A 8 salmon
        2026-07-11 22:34:26 [INFO] Pipeline complete.
        ```
  - [x] tximport
        ran successfully on 7/11/2026: 

        ```bash
        (genomics) nyssa@nyssa-laptop:~/artemisia-annua-rna-seq-project$ bash run_pipeline.sh --steps tximport --samples SRR6808226
        2026-07-11 22:36:42 [INFO] Config sourced: config.sh
        2026-07-11 22:36:42 [INFO] Log file: logs//pipeline.log
        2026-07-11 22:36:42 [INFO] Loaded 15 samples(s) from samples.csv
        2026-07-11 22:36:42 [INFO] Filtered to 1 sample(s): SRR6808226
        2026-07-11 22:36:42 [INFO] Steps    : tximport
        2026-07-11 22:36:42 [INFO] Samples  : SRR6808226
        2026-07-11 22:36:42 [INFO] --- Sample: SRR6808226 (blue) ---
        2026-07-11 22:36:42 [INFO] >>> [tximport]
        2026-07-11 22:36:42 [INFO] CMD: Rscript scripts/tximport.R             --salmon_dir  salmon_quant             --gtf         reference/GCA_003112345.1_ASM311234v1_genomic.gtf             --samples_csv samples.csv             --samples     SRR6808226             --counts_csv  counts//counts_matrix.csv             --output_dir  counts/
        2026-07-11 22:36:58 [INFO] Pipeline complete.
        ```
  - [x] count
        ran successfully on 7/11/2026: 

        ```bash
        (genomics) nyssa@nyssa-laptop:~/artemisia-annua-rna-seq-project$ bash run_pipeline.sh --steps count --samples SRR6808226
        2026-07-11 22:38:35 [INFO] Config sourced: config.sh
        2026-07-11 22:38:35 [INFO] Log file: logs//pipeline.log
        2026-07-11 22:38:35 [INFO] Loaded 15 samples(s) from samples.csv
        2026-07-11 22:38:35 [INFO] Filtered to 1 sample(s): SRR6808226
        2026-07-11 22:38:35 [INFO] Steps    : count
        2026-07-11 22:38:35 [INFO] Samples  : SRR6808226
        2026-07-11 22:38:35 [INFO] --- Sample: SRR6808226 (blue) ---
        2026-07-11 22:38:35 [INFO] >>> [count]
        2026-07-11 22:38:35 [INFO] CMD: bash scripts/count.sh salmon_quant counts/
        2026-07-11 22:38:36 [INFO] Pipeline complete.
        ```
  - [x] multiqc
        ran successfully on 7/11/2026:

        ```bash
        (genomics) nyssa@nyssa-laptop:~/artemisia-annua-rna-seq-project$ bash run_pipeline.sh --steps multiqc --samples SRR6808226
        2026-07-11 22:39:55 [INFO] Config sourced: config.sh
        2026-07-11 22:39:55 [INFO] Log file: logs//pipeline.log
        2026-07-11 22:39:55 [INFO] Loaded 15 samples(s) from samples.csv
        2026-07-11 22:39:55 [INFO] Filtered to 1 sample(s): SRR6808226
        2026-07-11 22:39:55 [INFO] Steps    : multiqc
        2026-07-11 22:39:55 [INFO] Samples  : SRR6808226
        2026-07-11 22:39:55 [INFO] --- Sample: SRR6808226 (blue) ---
        2026-07-11 22:39:55 [INFO] >>> [multiqc]
        2026-07-11 22:39:55 [INFO] CMD: bash scripts/multiqc.sh qc_reports/fastqc_raw/ qc_reports/fastqc_trimmed/ qc_reports/fastp alignment/ salmon_quant results//tables/ multiqc
        2026-07-11 22:40:00 [INFO] Pipeline complete.
        ```

---

## Phase 4 — Expand gradually

Only widen scope once Phase 3 works. Change **one variable at a time** — don't add a step and a sample in the same test.

- [x] Add a second sample to one step: `bash run_pipeline.sh --steps trim --samples ctrl_1 ctrl_2`
      ran successfully on 7/25/2026: 

      ```bash
      (genomics) nyssa@nyssa-laptop:~/artemisia-annua-rna-seq-project$ bash run_pipeline.sh --steps trim --samples SRR6808226 SRR6808227
      2026-07-25 12:12:10 [INFO] Config sourced: config.sh
      2026-07-25 12:12:10 [INFO] Log file: logs//pipeline.log
      2026-07-25 12:12:10 [INFO] Loaded 15 samples(s) from samples.csv
      2026-07-25 12:12:10 [INFO] Filtered to 2 sample(s): SRR6808226 SRR6808227
      2026-07-25 12:12:10 [INFO] Steps    : trim
      2026-07-25 12:12:10 [INFO] Samples  : SRR6808226 SRR6808227
      2026-07-25 12:12:10 [INFO] --- Sample: SRR6808226 (blue) ---
      2026-07-25 12:12:10 [INFO] >>> [trim] SRR6808226
      2026-07-25 12:12:10 [INFO] CMD: bash scripts/trim.sh SRR6808226 raw_data/SRR6808226_1.fastq raw_data/SRR6808226_2.fastq trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
      2026-07-25 12:15:10 [INFO] --- Sample: SRR6808227 (blue) ---
      2026-07-25 12:15:10 [INFO] >>> [trim] SRR6808227
      2026-07-25 12:15:10 [INFO] CMD: bash scripts/trim.sh SRR6808227 raw_data/SRR6808227_1.fastq raw_data/SRR6808227_2.fastq trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
      2026-07-25 12:18:37 [INFO] Pipeline complete.
      ```

- [x] Run two consecutive steps for one sample: `bash run_pipeline.sh --steps trim qc_trimmed --samples ctrl_1`

      ran successfully on 7/25/2026: 

      ```bash
      (genomics) nyssa@nyssa-laptop:~/artemisia-annua-rna-seq-project$ bash run_pipeline.sh --steps trim qc_trimmed --samples SRR6808226
      2026-07-25 12:21:49 [INFO] Config sourced: config.sh
      2026-07-25 12:21:49 [INFO] Log file: logs//pipeline.log
      2026-07-25 12:21:49 [INFO] Loaded 15 samples(s) from samples.csv
      2026-07-25 12:21:50 [INFO] Filtered to 1 sample(s): SRR6808226
      2026-07-25 12:21:50 [INFO] Steps    : trim qc_trimmed
      2026-07-25 12:21:50 [INFO] Samples  : SRR6808226
      2026-07-25 12:21:50 [INFO] --- Sample: SRR6808226 (blue) ---
      2026-07-25 12:21:50 [INFO] >>> [trim] SRR6808226
      2026-07-25 12:21:50 [INFO] CMD: bash scripts/trim.sh SRR6808226 raw_data/SRR6808226_1.fastq raw_data/SRR6808226_2.fastq trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
      2026-07-25 12:24:53 [INFO] >>> [qc_trimmed] SRR6808226
      2026-07-25 12:24:53 [INFO] CMD: bash scripts/qc_trimmed.sh SRR6808226 trimmed_data/ qc_reports/fastqc_trimmed/ 8 fastqc
      2026-07-25 12:27:04 [INFO] Pipeline complete.
      ```

- [x] Run all steps for one sample: `bash run_pipeline.sh --samples ctrl_1`

      ran successfully on 8/31/2026:

      ```bash
      (genomics) nyssa@nyssa-laptop:~/artemisia-annua-rna-seq-project$ bash run_pipeline.sh --samples SRR6808226
      2026-08-31 16:30:25 [INFO] Config sourced: config.sh
      2026-08-31 16:30:25 [INFO] Log file: logs//pipeline.log
      2026-08-31 16:30:25 [INFO] Loaded 15 samples(s) from samples.csv
      2026-08-31 16:30:26 [INFO] Filtered to 1 sample(s): SRR6808226
      2026-08-31 16:30:26 [INFO] Steps    : all
      2026-08-31 16:30:26 [INFO] Samples  : SRR6808226
      2026-08-31 16:30:26 [INFO] --- Sample: SRR6808226 (blue) ---
      2026-08-31 16:30:26 [INFO] >>> [subsample] SRR6808226
      2026-08-31 16:30:26 [INFO] CMD: bash scripts/subsample.sh "SRR6808226" "raw_data/SRR6808226_1.fastq" "raw_data/SRR6808226_2.fastq" "subsampled_data/" "1000000"
      2026-08-31 16:31:42 [INFO] >>> [qc_raw] SRR6808226
      2026-08-31 16:31:42 [INFO] CMD: bash scripts/qc_raw.sh SRR6808226 raw_data/SRR6808226_1.fastq raw_data/SRR6808226_2.fastq qc_reports/fastqc_raw/ 8 fastqc
      2026-08-31 16:33:48 [INFO] >>> [trim] SRR6808226
      2026-08-31 16:33:48 [INFO] CMD: bash scripts/trim.sh SRR6808226 raw_data/SRR6808226_1.fastq raw_data/SRR6808226_2.fastq trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
      2026-08-31 16:36:55 [INFO] >>> [qc_trimmed] SRR6808226
      2026-08-31 16:36:55 [INFO] CMD: bash scripts/qc_trimmed.sh SRR6808226 trimmed_data/ qc_reports/fastqc_trimmed/ 8 fastqc
      2026-08-31 16:39:36 [INFO] >>> [align] SRR6808226
      2026-08-31 16:39:36 [INFO] CMD: bash scripts/align.sh SRR6808226 trimmed_data/ alignment/ reference/star_index/ reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 "BAM SortedByCoordinate" "NH HI AS NM" NoSharedMemory TranscriptomeSAM STAR
      2026-08-31 16:58:57 [INFO] >>> [quantify] SRR6808226
      2026-08-31 16:58:57 [INFO] CMD: bash scripts/quantify.sh SRR6808226 alignment/ salmon_quant reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna reference/GCA_003112345.1_ASM311234v1_genomic.gtf A 8 salmon
      2026-08-31 16:59:16 [INFO] >>> [count]
      2026-08-31 16:59:16 [INFO] CMD: bash scripts/count.sh salmon_quant counts/
      2026-08-31 16:59:17 [INFO] >>> [tximport]
      2026-08-31 16:59:17 [INFO] CMD: Rscript scripts/tximport.R             --salmon_dir  salmon_quant             --gtf         reference/GCA_003112345.1_ASM311234v1_genomic.gtf             --samples_csv samples.csv             --samples     SRR6808226             --counts_csv  counts//counts_matrix.csv             --output_dir  counts/
      2026-08-31 16:59:33 [INFO] >>> [multiqc]
      2026-08-31 16:59:33 [INFO] CMD: bash scripts/multiqc.sh qc_reports/fastqc_raw/ qc_reports/fastqc_trimmed/ qc_reports/fastp alignment/ salmon_quant results//tables/ multiqc
      2026-08-31 16:59:37 [INFO] Pipeline complete.
      ```

- [ ] Run one step for all samples: `bash run_pipeline.sh --steps align`

      ran successfuly on 9/1/2026: 

      ```bash
      (genomics) nyssa@nyssa-laptop:~/artemisia-annua-rna-seq-project$ bash run_pipeline.sh --steps subsample
      2026-09-01 15:50:59 [INFO] Config sourced: config.sh
      2026-09-01 15:50:59 [INFO] Log file: logs//pipeline.log
      2026-09-01 15:51:00 [INFO] Loaded 15 samples(s) from samples.csv
      2026-09-01 15:51:00 [INFO] Steps    : subsample
      2026-09-01 15:51:00 [INFO] Samples  : SRR6808226 SRR6808227 SRR6808228 SRR6808229 SRR6808230 SRR6808231 SRR6808232 SRR6808233 SRR6808234 SRR6808235 SRR6808236 SRR6808237 SRR6808238 SRR6808239 SRR6808240
      2026-09-01 15:51:00 [INFO] --- Sample: SRR6808226 (blue) ---
      2026-09-01 15:51:00 [INFO] >>> [subsample] SRR6808226
      2026-09-01 15:51:00 [INFO] CMD: bash scripts/subsample.sh "SRR6808226" "raw_data/SRR6808226_1.fastq" "raw_data/SRR6808226_2.fastq" "subsampled_data/" "1000000"
      2026-09-01 15:52:24 [INFO] --- Sample: SRR6808227 (blue) ---
      2026-09-01 15:52:24 [INFO] >>> [subsample] SRR6808227
      2026-09-01 15:52:24 [INFO] CMD: bash scripts/subsample.sh "SRR6808227" "raw_data/SRR6808227_1.fastq" "raw_data/SRR6808227_2.fastq" "subsampled_data/" "1000000"
      2026-09-01 15:53:48 [INFO] --- Sample: SRR6808228 (blue) ---
      2026-09-01 15:53:48 [INFO] >>> [subsample] SRR6808228
      2026-09-01 15:53:48 [INFO] CMD: bash scripts/subsample.sh "SRR6808228" "raw_data/SRR6808228_1.fastq" "raw_data/SRR6808228_2.fastq" "subsampled_data/" "1000000"
      2026-09-01 15:55:12 [INFO] --- Sample: SRR6808229 (red) ---
      2026-09-01 15:55:12 [INFO] >>> [subsample] SRR6808229
      2026-09-01 15:55:12 [INFO] CMD: bash scripts/subsample.sh "SRR6808229" "raw_data/SRR6808229_1.fastq" "raw_data/SRR6808229_2.fastq" "subsampled_data/" "1000000"
      2026-09-01 15:56:30 [INFO] --- Sample: SRR6808230 (red) ---
      2026-09-01 15:56:30 [INFO] >>> [subsample] SRR6808230
      2026-09-01 15:56:30 [INFO] CMD: bash scripts/subsample.sh "SRR6808230" "raw_data/SRR6808230_1.fastq" "raw_data/SRR6808230_2.fastq" "subsampled_data/" "1000000"
      2026-09-01 15:57:52 [INFO] --- Sample: SRR6808231 (white) ---
      2026-09-01 15:57:52 [INFO] >>> [subsample] SRR6808231
      2026-09-01 15:57:52 [INFO] CMD: bash scripts/subsample.sh "SRR6808231" "raw_data/SRR6808231_1.fastq" "raw_data/SRR6808231_2.fastq" "subsampled_data/" "1000000"
      2026-09-01 15:59:13 [INFO] --- Sample: SRR6808232 (white) ---
      2026-09-01 15:59:13 [INFO] >>> [subsample] SRR6808232
      2026-09-01 15:59:13 [INFO] CMD: bash scripts/subsample.sh "SRR6808232" "raw_data/SRR6808232_1.fastq" "raw_data/SRR6808232_2.fastq" "subsampled_data/" "1000000"
      2026-09-01 16:00:29 [INFO] --- Sample: SRR6808233 (far_red) ---
      2026-09-01 16:00:29 [INFO] >>> [subsample] SRR6808233
      2026-09-01 16:00:29 [INFO] CMD: bash scripts/subsample.sh "SRR6808233" "raw_data/SRR6808233_1.fastq" "raw_data/SRR6808233_2.fastq" "subsampled_data/" "1000000"
      2026-09-01 16:01:53 [INFO] --- Sample: SRR6808234 (far_red) ---
      2026-09-01 16:01:53 [INFO] >>> [subsample] SRR6808234
      2026-09-01 16:01:53 [INFO] CMD: bash scripts/subsample.sh "SRR6808234" "raw_data/SRR6808234_1.fastq" "raw_data/SRR6808234_2.fastq" "subsampled_data/" "1000000"
      2026-09-01 16:03:15 [INFO] --- Sample: SRR6808235 (dark) ---
      2026-09-01 16:03:15 [INFO] >>> [subsample] SRR6808235
      2026-09-01 16:03:15 [INFO] CMD: bash scripts/subsample.sh "SRR6808235" "raw_data/SRR6808235_1.fastq" "raw_data/SRR6808235_2.fastq" "subsampled_data/" "1000000"
      2026-09-01 16:04:30 [INFO] --- Sample: SRR6808236 (far_red) ---
      2026-09-01 16:04:30 [INFO] >>> [subsample] SRR6808236
      2026-09-01 16:04:30 [INFO] CMD: bash scripts/subsample.sh "SRR6808236" "raw_data/SRR6808236_1.fastq" "raw_data/SRR6808236_2.fastq" "subsampled_data/" "1000000"
      2026-09-01 16:05:47 [INFO] --- Sample: SRR6808237 (dark) ---
      2026-09-01 16:05:47 [INFO] >>> [subsample] SRR6808237
      2026-09-01 16:05:47 [INFO] CMD: bash scripts/subsample.sh "SRR6808237" "raw_data/SRR6808237_1.fastq" "raw_data/SRR6808237_2.fastq" "subsampled_data/" "1000000"
      2026-09-01 16:07:07 [INFO] --- Sample: SRR6808238 (dark) ---
      2026-09-01 16:07:07 [INFO] >>> [subsample] SRR6808238
      2026-09-01 16:07:07 [INFO] CMD: bash scripts/subsample.sh "SRR6808238" "raw_data/SRR6808238_1.fastq" "raw_data/SRR6808238_2.fastq" "subsampled_data/" "1000000"
      2026-09-01 16:08:34 [INFO] --- Sample: SRR6808239 (white) ---
      2026-09-01 16:08:34 [INFO] >>> [subsample] SRR6808239
      2026-09-01 16:08:34 [INFO] CMD: bash scripts/subsample.sh "SRR6808239" "raw_data/SRR6808239_1.fastq" "raw_data/SRR6808239_2.fastq" "subsampled_data/" "1000000"
      2026-09-01 16:10:02 [INFO] --- Sample: SRR6808240 (red) ---
      2026-09-01 16:10:02 [INFO] >>> [subsample] SRR6808240
      2026-09-01 16:10:02 [INFO] CMD: bash scripts/subsample.sh "SRR6808240" "raw_data/SRR6808240_1.fastq" "raw_data/SRR6808240_2.fastq" "subsampled_data/" "1000000"
      2026-09-01 16:11:31 [INFO] Pipeline complete.
      ```

- [x] Run the full pipeline, all steps, all samples: `bash run_pipeline.sh`

      ran successfully on 9/6/2026: 
      
      ```bash
      (genomics) nyssa@nyssa-laptop:~/artemisia-annua-rna-seq-project$ bash run_pipeline.sh 
      2026-09-06 13:20:12 [INFO] Config sourced: config.sh
      2026-09-06 13:20:12 [INFO] Log file: logs//pipeline.log
      2026-09-06 13:20:12 [INFO] Loaded 15 samples(s) from samples.csv
      2026-09-06 13:20:12 [INFO] Steps    : all
      2026-09-06 13:20:12 [INFO] Samples  : SRR6808226 SRR6808227 SRR6808228 SRR6808229 SRR6808230 SRR6808231 SRR6808232 SRR6808233 SRR6808234 SRR6808235 SRR6808236 SRR6808237 SRR6808238 SRR6808239 SRR6808240
      2026-09-06 13:20:12 [INFO] --- Sample: SRR6808226 (blue) ---
      2026-09-06 13:20:12 [INFO] >>> [subsample] SRR6808226
      2026-09-06 13:20:12 [INFO] CMD: bash scripts/subsample.sh "SRR6808226" "raw_data/SRR6808226_1.fastq" "raw_data/SRR6808226_2.fastq" "subsampled_data/" "1000000"
      2026-09-06 13:21:22 [INFO] >>> [qc_raw] SRR6808226
      2026-09-06 13:21:22 [INFO] CMD: bash scripts/qc_raw.sh SRR6808226 raw_data/SRR6808226_1.fastq raw_data/SRR6808226_2.fastq qc_reports/fastqc_raw/ 8 fastqc
      2026-09-06 13:23:09 [INFO] >>> [trim] SRR6808226
      2026-09-06 13:23:09 [INFO] CMD: bash scripts/trim.sh SRR6808226 raw_data/SRR6808226_1.fastq raw_data/SRR6808226_2.fastq trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
      2026-09-06 13:25:56 [INFO] >>> [qc_trimmed] SRR6808226
      2026-09-06 13:25:56 [INFO] CMD: bash scripts/qc_trimmed.sh SRR6808226 trimmed_data/ qc_reports/fastqc_trimmed/ 8 fastqc
      2026-09-06 13:28:21 [INFO] >>> [align] SRR6808226
      2026-09-06 13:28:21 [INFO] CMD: bash scripts/align.sh SRR6808226 trimmed_data/ alignment/ reference/star_index/ reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 "BAM SortedByCoordinate" "NH HI AS NM" NoSharedMemory TranscriptomeSAM STAR
      2026-09-06 13:46:29 [INFO] >>> [quantify] SRR6808226
      2026-09-06 13:46:29 [INFO] CMD: bash scripts/quantify.sh SRR6808226 alignment/ salmon_quant reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna reference/GCA_003112345.1_ASM311234v1_genomic.gtf A 8 salmon
      2026-09-06 13:46:49 [INFO] --- Sample: SRR6808227 (blue) ---
      2026-09-06 13:46:49 [INFO] >>> [subsample] SRR6808227
      2026-09-06 13:46:49 [INFO] CMD: bash scripts/subsample.sh "SRR6808227" "raw_data/SRR6808227_1.fastq" "raw_data/SRR6808227_2.fastq" "subsampled_data/" "1000000"
      2026-09-06 13:48:03 [INFO] >>> [qc_raw] SRR6808227
      2026-09-06 13:48:03 [INFO] CMD: bash scripts/qc_raw.sh SRR6808227 raw_data/SRR6808227_1.fastq raw_data/SRR6808227_2.fastq qc_reports/fastqc_raw/ 8 fastqc
      2026-09-06 13:50:14 [INFO] >>> [trim] SRR6808227
      2026-09-06 13:50:14 [INFO] CMD: bash scripts/trim.sh SRR6808227 raw_data/SRR6808227_1.fastq raw_data/SRR6808227_2.fastq trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
      2026-09-06 13:53:29 [INFO] >>> [qc_trimmed] SRR6808227
      2026-09-06 13:53:29 [INFO] CMD: bash scripts/qc_trimmed.sh SRR6808227 trimmed_data/ qc_reports/fastqc_trimmed/ 8 fastqc
      2026-09-06 13:56:02 [INFO] >>> [align] SRR6808227
      2026-09-06 13:56:02 [INFO] CMD: bash scripts/align.sh SRR6808227 trimmed_data/ alignment/ reference/star_index/ reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 "BAM SortedByCoordinate" "NH HI AS NM" NoSharedMemory TranscriptomeSAM STAR
      2026-09-06 14:15:30 [INFO] >>> [quantify] SRR6808227
      2026-09-06 14:15:30 [INFO] CMD: bash scripts/quantify.sh SRR6808227 alignment/ salmon_quant reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna reference/GCA_003112345.1_ASM311234v1_genomic.gtf A 8 salmon
      2026-09-06 14:15:48 [INFO] --- Sample: SRR6808228 (blue) ---
      2026-09-06 14:15:48 [INFO] >>> [subsample] SRR6808228
      2026-09-06 14:15:48 [INFO] CMD: bash scripts/subsample.sh "SRR6808228" "raw_data/SRR6808228_1.fastq" "raw_data/SRR6808228_2.fastq" "subsampled_data/" "1000000"
      2026-09-06 14:16:59 [INFO] >>> [qc_raw] SRR6808228
      2026-09-06 14:16:59 [INFO] CMD: bash scripts/qc_raw.sh SRR6808228 raw_data/SRR6808228_1.fastq raw_data/SRR6808228_2.fastq qc_reports/fastqc_raw/ 8 fastqc
      2026-09-06 14:18:55 [INFO] >>> [trim] SRR6808228
      2026-09-06 14:18:55 [INFO] CMD: bash scripts/trim.sh SRR6808228 raw_data/SRR6808228_1.fastq raw_data/SRR6808228_2.fastq trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
      2026-09-06 14:21:52 [INFO] >>> [qc_trimmed] SRR6808228
      2026-09-06 14:21:52 [INFO] CMD: bash scripts/qc_trimmed.sh SRR6808228 trimmed_data/ qc_reports/fastqc_trimmed/ 8 fastqc
      2026-09-06 14:24:15 [INFO] >>> [align] SRR6808228
      2026-09-06 14:24:15 [INFO] CMD: bash scripts/align.sh SRR6808228 trimmed_data/ alignment/ reference/star_index/ reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 "BAM SortedByCoordinate" "NH HI AS NM" NoSharedMemory TranscriptomeSAM STAR
      2026-09-06 14:42:14 [INFO] >>> [quantify] SRR6808228
      2026-09-06 14:42:14 [INFO] CMD: bash scripts/quantify.sh SRR6808228 alignment/ salmon_quant reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna reference/GCA_003112345.1_ASM311234v1_genomic.gtf A 8 salmon
      2026-09-06 14:42:31 [INFO] --- Sample: SRR6808229 (red) ---
      2026-09-06 14:42:31 [INFO] >>> [subsample] SRR6808229
      2026-09-06 14:42:31 [INFO] CMD: bash scripts/subsample.sh "SRR6808229" "raw_data/SRR6808229_1.fastq" "raw_data/SRR6808229_2.fastq" "subsampled_data/" "1000000"
      2026-09-06 14:43:44 [INFO] >>> [qc_raw] SRR6808229
      2026-09-06 14:43:44 [INFO] CMD: bash scripts/qc_raw.sh SRR6808229 raw_data/SRR6808229_1.fastq raw_data/SRR6808229_2.fastq qc_reports/fastqc_raw/ 8 fastqc
      2026-09-06 14:45:32 [INFO] >>> [trim] SRR6808229
      2026-09-06 14:45:32 [INFO] CMD: bash scripts/trim.sh SRR6808229 raw_data/SRR6808229_1.fastq raw_data/SRR6808229_2.fastq trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
      2026-09-06 14:48:09 [INFO] >>> [qc_trimmed] SRR6808229
      2026-09-06 14:48:09 [INFO] CMD: bash scripts/qc_trimmed.sh SRR6808229 trimmed_data/ qc_reports/fastqc_trimmed/ 8 fastqc
      2026-09-06 14:50:14 [INFO] >>> [align] SRR6808229
      2026-09-06 14:50:15 [INFO] CMD: bash scripts/align.sh SRR6808229 trimmed_data/ alignment/ reference/star_index/ reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 "BAM SortedByCoordinate" "NH HI AS NM" NoSharedMemory TranscriptomeSAM STAR
      2026-09-06 15:03:32 [INFO] >>> [quantify] SRR6808229
      2026-09-06 15:03:32 [INFO] CMD: bash scripts/quantify.sh SRR6808229 alignment/ salmon_quant reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna reference/GCA_003112345.1_ASM311234v1_genomic.gtf A 8 salmon
      2026-09-06 15:03:48 [INFO] --- Sample: SRR6808230 (red) ---
      2026-09-06 15:03:48 [INFO] >>> [subsample] SRR6808230
      2026-09-06 15:03:48 [INFO] CMD: bash scripts/subsample.sh "SRR6808230" "raw_data/SRR6808230_1.fastq" "raw_data/SRR6808230_2.fastq" "subsampled_data/" "1000000"
      2026-09-06 15:04:58 [INFO] >>> [qc_raw] SRR6808230
      2026-09-06 15:04:58 [INFO] CMD: bash scripts/qc_raw.sh SRR6808230 raw_data/SRR6808230_1.fastq raw_data/SRR6808230_2.fastq qc_reports/fastqc_raw/ 8 fastqc
      2026-09-06 15:06:31 [INFO] >>> [trim] SRR6808230
      2026-09-06 15:06:31 [INFO] CMD: bash scripts/trim.sh SRR6808230 raw_data/SRR6808230_1.fastq raw_data/SRR6808230_2.fastq trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
      2026-09-06 15:08:51 [INFO] >>> [qc_trimmed] SRR6808230
      2026-09-06 15:08:51 [INFO] CMD: bash scripts/qc_trimmed.sh SRR6808230 trimmed_data/ qc_reports/fastqc_trimmed/ 8 fastqc
      2026-09-06 15:10:49 [INFO] >>> [align] SRR6808230
      2026-09-06 15:10:49 [INFO] CMD: bash scripts/align.sh SRR6808230 trimmed_data/ alignment/ reference/star_index/ reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 "BAM SortedByCoordinate" "NH HI AS NM" NoSharedMemory TranscriptomeSAM STAR
      2026-09-06 15:23:32 [INFO] >>> [quantify] SRR6808230
      2026-09-06 15:23:32 [INFO] CMD: bash scripts/quantify.sh SRR6808230 alignment/ salmon_quant reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna reference/GCA_003112345.1_ASM311234v1_genomic.gtf A 8 salmon
      2026-09-06 15:23:48 [INFO] --- Sample: SRR6808231 (white) ---
      2026-09-06 15:23:48 [INFO] >>> [subsample] SRR6808231
      2026-09-06 15:23:48 [INFO] CMD: bash scripts/subsample.sh "SRR6808231" "raw_data/SRR6808231_1.fastq" "raw_data/SRR6808231_2.fastq" "subsampled_data/" "1000000"
      2026-09-06 15:24:57 [INFO] >>> [qc_raw] SRR6808231
      2026-09-06 15:24:57 [INFO] CMD: bash scripts/qc_raw.sh SRR6808231 raw_data/SRR6808231_1.fastq raw_data/SRR6808231_2.fastq qc_reports/fastqc_raw/ 8 fastqc
      2026-09-06 15:26:29 [INFO] >>> [trim] SRR6808231
      2026-09-06 15:26:29 [INFO] CMD: bash scripts/trim.sh SRR6808231 raw_data/SRR6808231_1.fastq raw_data/SRR6808231_2.fastq trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
      2026-09-06 15:28:48 [INFO] >>> [qc_trimmed] SRR6808231
      2026-09-06 15:28:48 [INFO] CMD: bash scripts/qc_trimmed.sh SRR6808231 trimmed_data/ qc_reports/fastqc_trimmed/ 8 fastqc
      2026-09-06 15:30:44 [INFO] >>> [align] SRR6808231
      2026-09-06 15:30:44 [INFO] CMD: bash scripts/align.sh SRR6808231 trimmed_data/ alignment/ reference/star_index/ reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 "BAM SortedByCoordinate" "NH HI AS NM" NoSharedMemory TranscriptomeSAM STAR
      2026-09-06 15:47:13 [INFO] >>> [quantify] SRR6808231
      2026-09-06 15:47:13 [INFO] CMD: bash scripts/quantify.sh SRR6808231 alignment/ salmon_quant reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna reference/GCA_003112345.1_ASM311234v1_genomic.gtf A 8 salmon
      2026-09-06 15:47:27 [INFO] --- Sample: SRR6808232 (white) ---
      2026-09-06 15:47:27 [INFO] >>> [subsample] SRR6808232
      2026-09-06 15:47:27 [INFO] CMD: bash scripts/subsample.sh "SRR6808232" "raw_data/SRR6808232_1.fastq" "raw_data/SRR6808232_2.fastq" "subsampled_data/" "1000000"
      2026-09-06 15:48:34 [INFO] >>> [qc_raw] SRR6808232
      2026-09-06 15:48:34 [INFO] CMD: bash scripts/qc_raw.sh SRR6808232 raw_data/SRR6808232_1.fastq raw_data/SRR6808232_2.fastq qc_reports/fastqc_raw/ 8 fastqc
      2026-09-06 15:49:54 [INFO] >>> [trim] SRR6808232
      2026-09-06 15:49:54 [INFO] CMD: bash scripts/trim.sh SRR6808232 raw_data/SRR6808232_1.fastq raw_data/SRR6808232_2.fastq trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
      2026-09-06 15:51:54 [INFO] >>> [qc_trimmed] SRR6808232
      2026-09-06 15:51:54 [INFO] CMD: bash scripts/qc_trimmed.sh SRR6808232 trimmed_data/ qc_reports/fastqc_trimmed/ 8 fastqc
      2026-09-06 15:53:32 [INFO] >>> [align] SRR6808232
      2026-09-06 15:53:32 [INFO] CMD: bash scripts/align.sh SRR6808232 trimmed_data/ alignment/ reference/star_index/ reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 "BAM SortedByCoordinate" "NH HI AS NM" NoSharedMemory TranscriptomeSAM STAR
      2026-09-06 16:07:10 [INFO] >>> [quantify] SRR6808232
      2026-09-06 16:07:10 [INFO] CMD: bash scripts/quantify.sh SRR6808232 alignment/ salmon_quant reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna reference/GCA_003112345.1_ASM311234v1_genomic.gtf A 8 salmon
      2026-09-06 16:07:23 [INFO] --- Sample: SRR6808233 (far_red) ---
      2026-09-06 16:07:23 [INFO] >>> [subsample] SRR6808233
      2026-09-06 16:07:23 [INFO] CMD: bash scripts/subsample.sh "SRR6808233" "raw_data/SRR6808233_1.fastq" "raw_data/SRR6808233_2.fastq" "subsampled_data/" "1000000"
      2026-09-06 16:08:32 [INFO] >>> [qc_raw] SRR6808233
      2026-09-06 16:08:32 [INFO] CMD: bash scripts/qc_raw.sh SRR6808233 raw_data/SRR6808233_1.fastq raw_data/SRR6808233_2.fastq qc_reports/fastqc_raw/ 8 fastqc
      2026-09-06 16:10:01 [INFO] >>> [trim] SRR6808233
      2026-09-06 16:10:01 [INFO] CMD: bash scripts/trim.sh SRR6808233 raw_data/SRR6808233_1.fastq raw_data/SRR6808233_2.fastq trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
      2026-09-06 16:12:18 [INFO] >>> [qc_trimmed] SRR6808233
      2026-09-06 16:12:18 [INFO] CMD: bash scripts/qc_trimmed.sh SRR6808233 trimmed_data/ qc_reports/fastqc_trimmed/ 8 fastqc
      2026-09-06 16:14:08 [INFO] >>> [align] SRR6808233
      2026-09-06 16:14:08 [INFO] CMD: bash scripts/align.sh SRR6808233 trimmed_data/ alignment/ reference/star_index/ reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 "BAM SortedByCoordinate" "NH HI AS NM" NoSharedMemory TranscriptomeSAM STAR
      2026-09-06 16:27:24 [INFO] >>> [quantify] SRR6808233
      2026-09-06 16:27:24 [INFO] CMD: bash scripts/quantify.sh SRR6808233 alignment/ salmon_quant reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna reference/GCA_003112345.1_ASM311234v1_genomic.gtf A 8 salmon
      2026-09-06 16:27:39 [INFO] --- Sample: SRR6808234 (far_red) ---
      2026-09-06 16:27:39 [INFO] >>> [subsample] SRR6808234
      2026-09-06 16:27:39 [INFO] CMD: bash scripts/subsample.sh "SRR6808234" "raw_data/SRR6808234_1.fastq" "raw_data/SRR6808234_2.fastq" "subsampled_data/" "1000000"
      2026-09-06 16:28:50 [INFO] >>> [qc_raw] SRR6808234
      2026-09-06 16:28:50 [INFO] CMD: bash scripts/qc_raw.sh SRR6808234 raw_data/SRR6808234_1.fastq raw_data/SRR6808234_2.fastq qc_reports/fastqc_raw/ 8 fastqc
      2026-09-06 16:30:31 [INFO] >>> [trim] SRR6808234
      2026-09-06 16:30:31 [INFO] CMD: bash scripts/trim.sh SRR6808234 raw_data/SRR6808234_1.fastq raw_data/SRR6808234_2.fastq trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
      2026-09-06 16:33:07 [INFO] >>> [qc_trimmed] SRR6808234
      2026-09-06 16:33:07 [INFO] CMD: bash scripts/qc_trimmed.sh SRR6808234 trimmed_data/ qc_reports/fastqc_trimmed/ 8 fastqc
      2026-09-06 16:35:13 [INFO] >>> [align] SRR6808234
      2026-09-06 16:35:13 [INFO] CMD: bash scripts/align.sh SRR6808234 trimmed_data/ alignment/ reference/star_index/ reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 "BAM SortedByCoordinate" "NH HI AS NM" NoSharedMemory TranscriptomeSAM STAR
      2026-09-06 16:50:22 [INFO] >>> [quantify] SRR6808234
      2026-09-06 16:50:22 [INFO] CMD: bash scripts/quantify.sh SRR6808234 alignment/ salmon_quant reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna reference/GCA_003112345.1_ASM311234v1_genomic.gtf A 8 salmon
      2026-09-06 16:50:38 [INFO] --- Sample: SRR6808235 (dark) ---
      2026-09-06 16:50:38 [INFO] >>> [subsample] SRR6808235
      2026-09-06 16:50:38 [INFO] CMD: bash scripts/subsample.sh "SRR6808235" "raw_data/SRR6808235_1.fastq" "raw_data/SRR6808235_2.fastq" "subsampled_data/" "1000000"
      2026-09-06 16:51:47 [INFO] >>> [qc_raw] SRR6808235
      2026-09-06 16:51:47 [INFO] CMD: bash scripts/qc_raw.sh SRR6808235 raw_data/SRR6808235_1.fastq raw_data/SRR6808235_2.fastq qc_reports/fastqc_raw/ 8 fastqc
      2026-09-06 16:53:15 [INFO] >>> [trim] SRR6808235
      2026-09-06 16:53:15 [INFO] CMD: bash scripts/trim.sh SRR6808235 raw_data/SRR6808235_1.fastq raw_data/SRR6808235_2.fastq trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
      2026-09-06 16:55:34 [INFO] >>> [qc_trimmed] SRR6808235
      2026-09-06 16:55:34 [INFO] CMD: bash scripts/qc_trimmed.sh SRR6808235 trimmed_data/ qc_reports/fastqc_trimmed/ 8 fastqc
      2026-09-06 16:57:22 [INFO] >>> [align] SRR6808235
      2026-09-06 16:57:22 [INFO] CMD: bash scripts/align.sh SRR6808235 trimmed_data/ alignment/ reference/star_index/ reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 "BAM SortedByCoordinate" "NH HI AS NM" NoSharedMemory TranscriptomeSAM STAR
      2026-09-06 17:10:22 [INFO] >>> [quantify] SRR6808235
      2026-09-06 17:10:22 [INFO] CMD: bash scripts/quantify.sh SRR6808235 alignment/ salmon_quant reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna reference/GCA_003112345.1_ASM311234v1_genomic.gtf A 8 salmon
      2026-09-06 17:10:36 [INFO] --- Sample: SRR6808236 (far_red) ---
      2026-09-06 17:10:36 [INFO] >>> [subsample] SRR6808236
      2026-09-06 17:10:36 [INFO] CMD: bash scripts/subsample.sh "SRR6808236" "raw_data/SRR6808236_1.fastq" "raw_data/SRR6808236_2.fastq" "subsampled_data/" "1000000"
      2026-09-06 17:11:57 [INFO] >>> [qc_raw] SRR6808236
      2026-09-06 17:11:57 [INFO] CMD: bash scripts/qc_raw.sh SRR6808236 raw_data/SRR6808236_1.fastq raw_data/SRR6808236_2.fastq qc_reports/fastqc_raw/ 8 fastqc
      2026-09-06 17:13:21 [INFO] >>> [trim] SRR6808236
      2026-09-06 17:13:21 [INFO] CMD: bash scripts/trim.sh SRR6808236 raw_data/SRR6808236_1.fastq raw_data/SRR6808236_2.fastq trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
      2026-09-06 17:15:37 [INFO] >>> [qc_trimmed] SRR6808236
      2026-09-06 17:15:37 [INFO] CMD: bash scripts/qc_trimmed.sh SRR6808236 trimmed_data/ qc_reports/fastqc_trimmed/ 8 fastqc
      2026-09-06 17:17:22 [INFO] >>> [align] SRR6808236
      2026-09-06 17:17:22 [INFO] CMD: bash scripts/align.sh SRR6808236 trimmed_data/ alignment/ reference/star_index/ reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 "BAM SortedByCoordinate" "NH HI AS NM" NoSharedMemory TranscriptomeSAM STAR
      2026-09-06 17:30:31 [INFO] >>> [quantify] SRR6808236
      2026-09-06 17:30:31 [INFO] CMD: bash scripts/quantify.sh SRR6808236 alignment/ salmon_quant reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna reference/GCA_003112345.1_ASM311234v1_genomic.gtf A 8 salmon
      2026-09-06 17:30:45 [INFO] --- Sample: SRR6808237 (dark) ---
      2026-09-06 17:30:45 [INFO] >>> [subsample] SRR6808237
      2026-09-06 17:30:45 [INFO] CMD: bash scripts/subsample.sh "SRR6808237" "raw_data/SRR6808237_1.fastq" "raw_data/SRR6808237_2.fastq" "subsampled_data/" "1000000"
      2026-09-06 17:32:04 [INFO] >>> [qc_raw] SRR6808237
      2026-09-06 17:32:04 [INFO] CMD: bash scripts/qc_raw.sh SRR6808237 raw_data/SRR6808237_1.fastq raw_data/SRR6808237_2.fastq qc_reports/fastqc_raw/ 8 fastqc
      2026-09-06 17:33:24 [INFO] >>> [trim] SRR6808237
      2026-09-06 17:33:24 [INFO] CMD: bash scripts/trim.sh SRR6808237 raw_data/SRR6808237_1.fastq raw_data/SRR6808237_2.fastq trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
      2026-09-06 17:35:33 [INFO] >>> [qc_trimmed] SRR6808237
      2026-09-06 17:35:33 [INFO] CMD: bash scripts/qc_trimmed.sh SRR6808237 trimmed_data/ qc_reports/fastqc_trimmed/ 8 fastqc
      2026-09-06 17:37:13 [INFO] >>> [align] SRR6808237
      2026-09-06 17:37:13 [INFO] CMD: bash scripts/align.sh SRR6808237 trimmed_data/ alignment/ reference/star_index/ reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 "BAM SortedByCoordinate" "NH HI AS NM" NoSharedMemory TranscriptomeSAM STAR
      2026-09-06 17:52:57 [INFO] >>> [quantify] SRR6808237
      2026-09-06 17:52:57 [INFO] CMD: bash scripts/quantify.sh SRR6808237 alignment/ salmon_quant reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna reference/GCA_003112345.1_ASM311234v1_genomic.gtf A 8 salmon
      2026-09-06 17:53:25 [INFO] --- Sample: SRR6808238 (dark) ---
      2026-09-06 17:53:25 [INFO] >>> [subsample] SRR6808238
      2026-09-06 17:53:25 [INFO] CMD: bash scripts/subsample.sh "SRR6808238" "raw_data/SRR6808238_1.fastq" "raw_data/SRR6808238_2.fastq" "subsampled_data/" "1000000"
      2026-09-06 17:54:47 [INFO] >>> [qc_raw] SRR6808238
      2026-09-06 17:54:47 [INFO] CMD: bash scripts/qc_raw.sh SRR6808238 raw_data/SRR6808238_1.fastq raw_data/SRR6808238_2.fastq qc_reports/fastqc_raw/ 8 fastqc
      2026-09-06 17:56:12 [INFO] >>> [trim] SRR6808238
      2026-09-06 17:56:12 [INFO] CMD: bash scripts/trim.sh SRR6808238 raw_data/SRR6808238_1.fastq raw_data/SRR6808238_2.fastq trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
      2026-09-06 18:01:00 [INFO] >>> [qc_trimmed] SRR6808238
      2026-09-06 18:01:00 [INFO] CMD: bash scripts/qc_trimmed.sh SRR6808238 trimmed_data/ qc_reports/fastqc_trimmed/ 8 fastqc
      2026-09-06 18:02:45 [INFO] >>> [align] SRR6808238
      2026-09-06 18:02:45 [INFO] CMD: bash scripts/align.sh SRR6808238 trimmed_data/ alignment/ reference/star_index/ reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 "BAM SortedByCoordinate" "NH HI AS NM" NoSharedMemory TranscriptomeSAM STAR
      2026-09-06 18:29:41 [INFO] >>> [quantify] SRR6808238
      2026-09-06 18:29:41 [INFO] CMD: bash scripts/quantify.sh SRR6808238 alignment/ salmon_quant reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna reference/GCA_003112345.1_ASM311234v1_genomic.gtf A 8 salmon
      2026-09-06 18:30:10 [INFO] --- Sample: SRR6808239 (white) ---
      2026-09-06 18:30:10 [INFO] >>> [subsample] SRR6808239
      2026-09-06 18:30:10 [INFO] CMD: bash scripts/subsample.sh "SRR6808239" "raw_data/SRR6808239_1.fastq" "raw_data/SRR6808239_2.fastq" "subsampled_data/" "1000000"
      2026-09-06 18:31:33 [INFO] >>> [qc_raw] SRR6808239
      2026-09-06 18:31:33 [INFO] CMD: bash scripts/qc_raw.sh SRR6808239 raw_data/SRR6808239_1.fastq raw_data/SRR6808239_2.fastq qc_reports/fastqc_raw/ 8 fastqc
      2026-09-06 18:33:14 [INFO] >>> [trim] SRR6808239
      2026-09-06 18:33:14 [INFO] CMD: bash scripts/trim.sh SRR6808239 raw_data/SRR6808239_1.fastq raw_data/SRR6808239_2.fastq trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
      2026-09-06 18:39:05 [INFO] >>> [qc_trimmed] SRR6808239
      2026-09-06 18:39:05 [INFO] CMD: bash scripts/qc_trimmed.sh SRR6808239 trimmed_data/ qc_reports/fastqc_trimmed/ 8 fastqc
      2026-09-06 18:41:21 [INFO] >>> [align] SRR6808239
      2026-09-06 18:41:21 [INFO] CMD: bash scripts/align.sh SRR6808239 trimmed_data/ alignment/ reference/star_index/ reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 "BAM SortedByCoordinate" "NH HI AS NM" NoSharedMemory TranscriptomeSAM STAR
      2026-09-06 19:21:50 [INFO] >>> [quantify] SRR6808239
      2026-09-06 19:21:50 [INFO] CMD: bash scripts/quantify.sh SRR6808239 alignment/ salmon_quant reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna reference/GCA_003112345.1_ASM311234v1_genomic.gtf A 8 salmon
      2026-09-06 19:22:21 [INFO] --- Sample: SRR6808240 (red) ---
      2026-09-06 19:22:21 [INFO] >>> [subsample] SRR6808240
      2026-09-06 19:22:21 [INFO] CMD: bash scripts/subsample.sh "SRR6808240" "raw_data/SRR6808240_1.fastq" "raw_data/SRR6808240_2.fastq" "subsampled_data/" "1000000"
      2026-09-06 19:23:43 [INFO] >>> [qc_raw] SRR6808240
      2026-09-06 19:23:43 [INFO] CMD: bash scripts/qc_raw.sh SRR6808240 raw_data/SRR6808240_1.fastq raw_data/SRR6808240_2.fastq qc_reports/fastqc_raw/ 8 fastqc
      2026-09-06 19:25:12 [INFO] >>> [trim] SRR6808240
      2026-09-06 19:25:12 [INFO] CMD: bash scripts/trim.sh SRR6808240 raw_data/SRR6808240_1.fastq raw_data/SRR6808240_2.fastq trimmed_data/ qc_reports/fastp 8 36 20 40 fastp
      2026-09-06 19:30:09 [INFO] >>> [qc_trimmed] SRR6808240
      2026-09-06 19:30:09 [INFO] CMD: bash scripts/qc_trimmed.sh SRR6808240 trimmed_data/ qc_reports/fastqc_trimmed/ 8 fastqc
      2026-09-06 19:31:58 [INFO] >>> [align] SRR6808240
      2026-09-06 19:31:58 [INFO] CMD: bash scripts/align.sh SRR6808240 trimmed_data/ alignment/ reference/star_index/ reference/GCA_003112345.1_ASM311234v1_genomic.gtf 8 "BAM SortedByCoordinate" "NH HI AS NM" NoSharedMemory TranscriptomeSAM STAR
      2026-09-06 19:57:32 [INFO] >>> [quantify] SRR6808240
      2026-09-06 19:57:32 [INFO] CMD: bash scripts/quantify.sh SRR6808240 alignment/ salmon_quant reference/GCA_003112345.1_ASM311234v1_rna_from_genomic.fna reference/GCA_003112345.1_ASM311234v1_genomic.gtf A 8 salmon
      2026-09-06 19:58:02 [INFO] >>> [count]
      2026-09-06 19:58:02 [INFO] CMD: bash scripts/count.sh salmon_quant counts/
      2026-09-06 19:58:04 [INFO] >>> [tximport]
      2026-09-06 19:58:04 [INFO] CMD: Rscript scripts/tximport.R             --salmon_dir  salmon_quant             --gtf         reference/GCA_003112345.1_ASM311234v1_genomic.gtf             --samples_csv samples.csv             --samples     SRR6808226,SRR6808227,SRR6808228,SRR6808229,SRR6808230,SRR6808231,SRR6808232,SRR6808233,SRR6808234,SRR6808235,SRR6808236,SRR6808237,SRR6808238,SRR6808239,SRR6808240             --counts_csv  counts//counts_matrix.csv             --output_dir  counts/
      2026-09-06 19:58:20 [INFO] >>> [multiqc]
      2026-09-06 19:58:20 [INFO] CMD: bash scripts/multiqc.sh qc_reports/fastqc_raw/ qc_reports/fastqc_trimmed/ qc_reports/fastp alignment/ salmon_quant results//tables/ multiqc
      2026-09-06 19:58:32 [INFO] Pipeline complete.
      ```

---

## Phase 5 - Run wrapper, perform downstream analyses in Quarto Notebooks
- [ ] Run all steps for all samples
- [ ] Import outputs from pipeline runner into Quarto notebooks
- [ ] Perform differential gene expression analysis with DESeq2
- [ ] Generate visualization and QC plots
- [ ] Perform enrichment analysis with g:Profiler 

## Quick reference: when something breaks

| Where it broke | What that tells you | Where to look |
|---|---|---|
| Phase 1 (manual script) | The tool/logic itself has an issue | The script's command, tool flags, input file paths |
| Phase 2 (dry run) | Wrapper is building the wrong command | `config.sh` values, argument order in `run_pipeline.sh` |
| Phase 3 (wrapper, narrow scope) | Wrapper → script handoff is broken | How arguments are passed, quoting, variable expansion |
| Phase 4 (expanding scope) | An edge case only shows up at scale | Compare against the narrower case that worked |

---

## A note for future you

This list is doing the remembering so you don't have to hold the whole pipeline in your head at once. Each checkmark is a closed loop. If you're picking this back up after time away, just look for the first unchecked box — that's the entire task in front of you right now. Nothing earlier needs to be re-verified unless something downstream breaks and points back to it.
