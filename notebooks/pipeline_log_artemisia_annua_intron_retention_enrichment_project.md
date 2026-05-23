# Pipeline Log - _Artemisia annua_ Intron Retention Enrichment Project

## February 21-22, 2026

- **What I ran/did:**  
    * Created Codeberg repo
    * Wrote README draft
    * Downloaded metadata
    * Identified SRA accession numbers
    * Created toolbox container
- **What worked:**
    * Creating the github repo
    * Downloading the metadata
- **What failed:**
    * Creating toolbox container
- **Exact error message:** 
    * There were a lot of error messages to be honest. Most of them involved setting up the Conda and/or Python environments but I ended up doing them incorrectly. I tried to use the exact tool stack described in the paper but it was hard to replicate because the tool stack was a bit outdated, so it interfered with modern dependencies used in the conda and python environments. I decided to pivot to a standard RNA-seq tech stack (i.e., sra-toolkit, FastQC, Trimmomatic, HISAT2, featureCounts, DESeq2, rMATS, clusterProfiler) and I was able to successfully create the toolbox container from there. I am using the toolbox container because I am running a Fedora Silverblue-based Linux distro.
- **Learnings:**
    * Creating toolbox containers containing Conda/Python enviroments needs to be streamlined to avoid dependency issues

### Notes

**How to create a repo:**
```
mkdir my-project
cd my-project

cd path/to/your/porject
git init
git add .
git commit -m "Initial commit"
```

After this, go to your provider of choice, mine is Codeberg. 

Click the '+' and select 'New Repository'

Enter the name, description (optional), and public or private

Click 'Create Repository'

Then:
```
git remote add origin https://provider.com/your-username/my-project.git
git branch -M main
git push -u origin main
```

**How to download metadata:**

1. Go to NCBI
2. Toggle to BioProject and enter accession number
3. Go to Related Information
4. Click SRA
5. Click one of the sample names
6. Under 'Study' select 'All Runs'
7. Select samples you want and click 'Download Metadata'

**How to identify SRA accession numbers:**

1. Open the Excel Workbook file that contains the metadata
2. Note in a separate text document the name of each SRA accession as well as the Sample Name and the tissue type. 


## Feburary 23, 2026

- **What I ran/did:**
    * Downloaded FASTQ files for each sample
    * Ran one round of FastQC on each sample
    * Noted quality of each sample based on FASTQC report
- **What worked:**
    * Prefetching the SRA files for each sample by adapting a Python loop script to Bash
- **What failed:**
    * Downloading FASTQ files using fastq-dump
    * Downloading FASTQ files to an unauthorized directory
- **Exact error message:**
    * Generating fastq for: SRR15595133 2026-02-24T01:38:17 fastq-dump.3.2.1 err: name not found while resolving query within virtual file system module - failed to resolve accession '16' - Cannot resolve accession ( 404 ); ncbi_phid='90ED1FA999D0080100000000000C000C.m_1' 2026-02-24T01:38:17 fastq-dump.3.2.1 err: param incorrect while reading argument list within application support module - --threads
    * Generating fastq for: SRR15595133 2026-02-24T01:44:11 fasterq-dump.3.2.1 err: ft_create_this_dir_2().KDirectoryCreateDir( '/data' ) -> RC(rcFS,rcDirectory,rcCreating,rcDirectory,rcUnauthorized) fasterq-dump quit with error code 3 The command used was: fasterq-dump --outdir /data --threads 16 --split-3 --skip-technical /var/home/nyssa/sra_temp/sra/SRR15595133.sra 0 minutes and 20 seconds elapsed.
- **Learnings:** 
    * Use `fasterq-dump` instead of `fastq-dump`
    * Set an output directory when using the `fasterq-dump` command using the `--outdir [DIRECTORY]` flag
    * How to code a loop in Bash through SRA FASTQ files when some sample accessions have _1 or _2 appended to the filename, typically indicating that the sample accessions are paired reads rather than single reads

### Notes:
**How to download FASTQ files for each sample:**

1. Use `prefetch [SAMPLE NAME]` to grab the .sra files you need from the samples you selected. You can put this command into a standard loop.
2. Use `fasterq-dump --outdir [DIRECTORY] --threads [CPU threads] --split [Number of Splits] --skip-technical [OUTPUT DIRECTORY]/[SAMPLE NAME].sra` to download the FASTQ files from the .sra data associated with each sample you selected. You can put this command into a standard loop, making sure to set variables for the output directory and sample name you are working with. 

**How to run fastqc:**

1. Use `fastqc [SAMPLE NAME].fastq -o [OUTPUT DIRECTORY]`. You can use this in a standard loop, making sure to set variables for the output directory and sample name you are workign with. 

**How to decide where and how much to trim off for a read:**

According to [this video](https://www.youtube.com/watch?v=lG11JjovJHE) from Bioinformagician...

1. If there's any sequences with low quality scores (<20 phred score) towards the middle, then you would want to trim. Towards the end, lower quality is expected due to signal decay or phasing. It is recommended to maintain 80% of the read length if you do trim. 
2. Check if there's any adapter sequences to see if they need to be trimmed out

**How to loop through SRA FASTQ files when some accessions have paired reads and some don't:**

```
for SAMPLE in $(ls *.fastq | sed -E 's/_1.fastq|_2.fastq|.fastq//' | sort -u)
do
    R1="${SAMPLE}_1.fastq"
    R2="${SAMPLE}_2.fastq"
    SE="${SAMPLE}.fastq"

    if [[ -f "$R1" && -f "$R2" ]]; then
        echo "Paired-end: $SAMPLE"
    elif [[ -f "$SE" ]]; then
        echo "Single-end: $SAMPLE"
    fi
done
```

### My FastQC Report Observations:
- [ ]  SRR15595118
    - [ ]  _1: good quality, no adapters
    - [ ]  _2: good quality (lowest towards end at 25 is ok), no adapters
- [ ]  SRR15595119
    - [ ]  _1: good quality, no adapters
    - [ ]  _2: good quality (lowest towards end at 25 is ok), no adapters
- [ ]  SRR15595120
    - [ ]  _1: good quality, no adapters
    - [ ]  _2: good quality (lowest towards end at 25 is ok), no adapters
- [ ]  SRR15595121
    - [ ]  _1: good quality, no adapters
    - [ ]  _2: good quality (lowest end at 25 is ok), no adapters
- [ ]  SRR15595122
    - [ ]  _1: good quality, no adapters
    - [x]  _2: good quality (lowest end at 25 is ok), no adapters
- [ ]  SRR15595123
    - [ ]  not good quality, whole sequence has phred score of 20, lots of adapters from 9bp onwards, mentions CDS primer in list of sequence duplication
    - [ ]  will need to check methods of paper to see if this is normal because i believe this is an SMRT sample as referenced in the paper as it is a single read
- [ ]  SRR15595124
    - [ ]  same as above
- [ ]  SRR15595125
    - [ ]  _1: good quality, no adapters
    - [ ]  _2: good quality (lowest end at 25 is ok), no adapters
- [ ]  SRR15595126
    - [ ]  _1: good quality (lowest end at 25 is ok), no adapters
    - [ ]  _2: good quality (lowest end at 25 is ok), no adapters
- [ ]  SRR15595127
    - [ ]  _1: good quality, no adapters
    - [x]  _2: good quality (lowest end at 25 is ok), no adapters
- [ ]  SRR15595128
    - [ ]  _1: good quality, no adapters
    - [ ]  _2: good quality, no adapters
- [ ]  SRR15595129
    - [ ]  _1: good quality, no adapters
    - [ ]  _2: ok quality (lowest at both ends at 25 is ok), no adapters
- [ ]  SRR15595130
    - [ ]  _1: good quality, no adapters
    - [ ]  _2: good quality, no adapters
- [ ]  SRR15595131
    - [ ]  _1: good quality (lowest end at 25 is ok), no adapters
    - [ ]  _2: good quality (lowest end at 25 is ok), no adapters
- [ ]  SRR15595132
    - [ ]  same as 123 above
- [ ]  SRR15595133
    - [ ]  same as 123 above

## March 1, 2026

- **What I ran/did:**
    * I decided to restart the project from the beginning. After running the initial FastQC on the samples last time, I noticed that some of the samples had very low quality scores. As it turned out, these samples were the very same SMRT long reads mentioned in the paper. The paper acknowledged that they were low quality and, as such, had to be corrected with the higher quality Illumina short reads. This would necessitate a different tool to be used entirely. As such, I cannot do a standard RNA-seq tool pipeline including FastQC as I initially hoped as the nature of the project necessitates some initial correction steps on the short reads prior to further downstream processing and analysis. I will now restart the project with a new tech stack that more closely matches what the paper did. The tech stack I am using will be sra-toolkit, minimap2, FLAIR, Salmon, SUPPA2, DESeq2, clusterProfiler, and ggplot2. 
    * Re-organized/renamed folders 
    * Created a new toolbox container
- **What worked:**
    * Created a new toolbox container called `bioinformatics-tools`
- **What failed:**
    * Trying to stop the old toolbox container
- **Exact error message:**
    * Error: container 5cfdeb043f84d76956fd9ee9c958679efd9b3f15b7d1ab5034f1ad5b58116655 has active exec sessions, refusing to clean up: container state improper

- **Learnings:**
    * Tried to stop initially with `podman kill rna-seq` but that didn't work. Then tried `sudo podman system reset` but that was going to remove ALL of my containers, which I didn't want. Ended up doing `podman container kill -a` to just kill the running containers and that seemed to work. Then I removed the toolbox container with `toolbox rm rna-seq`
    * Use Micromamba instead of Miniconda instead as its less fragile. Created separate environments by purpose: rna_qc_env, mapping_env, isoform_env, r_analysis_env
    * Make sure to check channel config for micromamba if installing alongside miniconda `micromamba config list` making sure to check for `nodefaults`. Then remove all existing channel config `micromamba config remove-key channels` and explicitly set clean channels `micromamba config append channels conda-forge`
and `micromamba config append channels bioconda`. Check if `.condarc` exists by doing `ls -a ~ | grep condarc` and then spit out the output `cat ~/.condarc`. If you see 	`defaults` and `nodefaults` and `channel_priority: strict` disable it safely by doing `mv ~/.condarc ~/.condarc_backup` and restarting the shell `exec $SHELL`. If you don't see those things, confirm Conda is active `echo $CONDA_PREFIX` and then deactivate the base Conda `conda deactivate`. Then disable auto-activation permanently `conda config --set auto_activate_base false` and restart the shell `exec $SHELL`. Then check the config again `micromamba config list`. The `defaults` should be gone. 

### Notes: 

**How to create a toolbox container and corresponding Conda/Mamba environment:**

```
# create and enter toolbox
toolbox create [CONTAINER NAME]
toolbox enter

# install basic dependencies
sudo dnf install wget bzip2 git -y

# install Miniconda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh

# run installer
bash Miniconda3-latest-Linux-x86_64.sh

# accept defaults

# then activate
source ~/.bashrc

# check
conda --version

# (alternative to Miniconda is Micromamba)
curl -L micro.mamba.pm/install.sh | bash

# restart shell
exec $SHELL

# test
micromamba --version

# create RNA-seq environment in Conda
conda create -n rnaseq -c bioconda -c conda-forge \
fastqc trimmomatic hisat2 subread samtools sra-tools -y

# activate it
conda activate rnaseq

# check
fastqc --version
hisat2 --version
featureCounts -v
fasterq-dump --version

# (alternative) create RNA-seq environment in Mamba
micromamba create -n rnaseqc -c conda-forge -c bioconda \
  minimap2 \
  samtools \
  salmon \
  suppa \
  flair \
  gffread \
  r-base \
  bioconductor-deseq2 \
  bioconductor-tximport \
  sra-tools \
  python=3.10

# activate it
micromamba activate rnaseq

# check
minimap2 --help
samtools --help
salmon --help
gffread --help
fasterq-dump --version

# configure SRA toolkit storage path

# create dedicated temp folder on large disk
mkdir -p /your/home/directory/sra_temp (or /mnt/data/sra_temp)

# configure SRA toolkit to use it
vdb-config --interactive

# Go to 'Locations' -> 'Repository Path'
Set it to /your/home/directory/sra_temp (or )

# if used Micromamba, install R packages properly:

# open R
R

# then inside R
install.packages("BiocManager")
BiocManager::install("DESeq2")
BiocManager::install("tximport")
BiocManager::install("clusterProfiler")

# exit R
q()

# install Jupyter optionally with Micromamba
micromamba install -c conda-forge jupyterlab

# run
jupyter lab
```

**If you want to do compression during conversion of .sra to .fastq:**

```
gzip [FASTQ OUTPUT DIRECTORY]/*.fastq
```

**If you want a list of the conda environments:**
```
conda env list 

# or 
conda info --envs
```

**If you want to remove a conda environment:**
```
conda deactivate

# either
conda remove --name ENV_NAME --all

# or
conda env remove --name ENV_NAME

# free up space
conda clean --all

```

## March 3, 2026

- **What I ran/did:**
    * Exported micromamba environments for reproducibility into my portfolio repo
    * Downloaded genome reference used in the paper, [Huhao#1](https://www.ncbi.nlm.nih.gov/datasets/genome/GCA_003112345.1/)
    * Indexed the reference genome using minimap2
- **What worked:**
    * Exporting environments
    * Downloading genome
    * Indexing the genome
- **What failed:**
- **Exact error message:**
- **Learnings:**
    * How to export environments
    * How to download a genome reference from NCBI via command line
    * How to index a reference genome using minimap2
    * How to convert from .fna to .fa


### Notes:
**How to export micromamba environments:**
```
micromamba env export > artemisia_env.yml
```

**How to download genome reference from NCBI from command line according to this [tutorial](https://bga23.ylog.org/ncbidatasets/NCBI-datasets-cli/#2-genome-retrieval-options):**
```
# install ncbi datasets. you can swap micromamba, mamba, miniconda, etc for the conda command in this example

conda create -n datasets -c conda-forge ncbi-datasets-cli tree -y
conda activate datasets
datasets

# download genome reference
datasets download genome [ACCESSION] --[FLAG]
unzip [GENOME_ZIP_ ARCHIVE] -d [UNZIPPED_GENOME_ARCHIVE_NAME]
tree [UNZIPPED_GENOME_ ARCHIVE_NAME]
# can use --filenmame flag to specify filename

# can use --include flag to specify the data files to include as a comma separated list (e.g., genome,rna,protein,cds,gff3,gtf,gbff,seq-report,none). 
```

**How to convert from .fna to .fa:**
```
cp filename.fna filename.fa
```

**How to index a genome for mapping:**
```
minimap2 -d reference/genome.mmi reference/genome.fa
```

## March 6-7, 2026
- **What I ran/did:**
    * Re-ran FASTQC step because I needed to make sure that the FASTQ outputs and their respective FASTQ files went into their correct organization folders in preparation for the processing of the short and long reads separately
    * Processed long reads/Pac Bio using a simple bash script using minimap2 and FLAIR. These tools are simpler than the older SMRT + IDP pipeline used in the original paper. 
- **What worked:**
    * Re-running the FASTQC step by amending the file to include commands to move the .fastq files to either the short read or long read folder based on whether they were paired/short or single/long reads. 
- **What failed:**
- **Error messages:**
- **Learnings:**
    * When working with single and paired reads, you need to separate and organize them as they may need to go through separate processing steps further down the line
    * You need to have a general idea of the directory tree so that the pipeline you are developing with bash scripts is more seamless
    * The `sed` command is used to replace text in a given file. It is used in the way illustrated in the notes below. 

### Notes

**How to map long reads to a genome:**
```
# map reads to reference genome
minimap2 -ax splice -uf -k14 reference/[GENOME REFERENCE NAME].mmi raw_data/[SAMPLE NAME].fastq.gz > long_read/[SAMPLE NAME].sam

# convert to BAM
samtools view -Sb long_read/[SAMPLE NAME].sam | samtools sort -o long_read/[SAMPLE NAME].sorted.bam
samtools index long_read/[SAMPLE NAME].sorted.bam

# collapse isoforms with FLAIR
flair collapse \
  -g reference/[GENOME REFERENCE NAME].fa \
  -r raw_data/[SAMPLE NAME].fastq.gz \
  -q long_read/[SAMPLE NAME].sorted.bam \
  -o long_read/[SAMPLE NAME]

# output should be [SAMPLE NAME].isoforms.gtf
```

**[How to use the `sed` command:](https://www.geeksforgeeks.org/linux-unix/sed-command-in-linux-unix-with-examples/)**
```
sed [OPTIONS] 'COMMAND' [INPUTFILE...]

# options are optional flags that modify the behavior of the sed command

# options are:
-i [Edit the file in-place (overwrite)]
-n [Suppress automatic printing of lines]
-e [Allows multiple commands]
-f [Reads sed commands from a file]
-r [Use extended regular expressions]

# command defines the command or sequence of commands to execute on the input file

# inputfile lists one or more input files to be processed

# to extract a string from a given file, like a sample name used in a .fastq file downloaded from SRA:
sed -E 's/[PATTERN]//'
# the '//' part is to replace the pattern with nothing
# the '-E' part is to allow for extended regular expressions like '|' to mean OR

```

**How to convert .fastq to .fastq.gz:**
```
# single file
gzip [FILENAME].fastq

# all in current directory
gzip *.fastq

# all in a directory and its subdirectories
gzip -r *.fastq [DIRECTORY]/

# single file without deleting original file
gzip -c [FILENAME].fastq > [FILENAME].fastq.gz
```

**[How to check if a file exists in bash:](https://stackoverflow.com/questions/40082346/how-to-check-if-a-file-exists-in-a-shell-script)**
```
if [-e [FILE].extension]
then
    ...
else 
    ...
fi
```

**[How to loop through files in a directory in bash:](https://stackoverflow.com/a/8512513)**
```
for file in *; do
    echo "put $file"
done

```

**How to make a bash script executable:**
```
chmod +x [FILENAME].sh
```

**How to execute bash script in command line:**
```
./[FILENAME].sh
```

## March 8-9, 2026

- **What I ran/did:**
    * Broke up the processing long reads step into two scripts. Script one mapped the long reads to the genome, sorted and indexed the reads into BAM files, and then generated splice isoform plots to check if the isoform detection was correct (the plots were generated within a sub python script that was called upon in the main script). Script two converted the BAM file to BED and then collapsed the isoforms with FLAIR. 
- **What worked:**
    * After resolving the script syntax and failed commands, the steps for collapsing the isoforms finally worked. 
- **What failed:**
    * Initial runs of the scripts used to collapse the isoforms failed due to the reasons mentioned in the error messages bullet below. 
- **Error messages:**
    * Multiple error messages had to do mostly with the script exiting due to syntax errors and/or failed commands from the minimap2, samtools, and/or flair packages. 
    * Other error messages had to due with file type read errors due to improper conversion. 
- **Learnings:**
    * Pay attention to syntax
    * Break up a phase of the pipeline into smaller scripts if needed
    * Add sanity checks/debugging code so that you can solve issues before proceeding to the next step
    * Learning Nextflow or another pipeline manager may be useful for my next portfolio project as something that bothered me was the inability to resume from where I left off. Every time, I had to debug, I had to restart the whole script and even delete intermediate files created by the script so as to start fresh. From what I remember from my brief exploration of Nextflow in the past, Nextflow allows users to resume from where they left off, which is a MAJOR plus for me. I like things to be convenient. 

### Notes:

## March 15, 2026

- **What I ran/did:**
    * Combined isoform bed files
    * Processing short reads based on long read isoform data
- **What worked:**
    * Combining isoform bed files
- **What failed:**
- **Error messages:**
- **Learnings:**
    * Isoforms are best performed with long reads and short read data are interpreted based on long reads. I find that interesting considering long reads are third-generation sequencing whereas short reads are next-generation sequencing. 
    * When running `salmon quant` you need to set a decoy to ensure that the reads align them to the transcripts only rather than genomic (intron/repeats) regions. 
    * **Alternative splicing**- a cellular process in which exons from the same gene are joined in different combinations, leading to different, but related, mRNA transcripts. These mRNAs can be translated to produce different proteins with distinct structures and functions -- all from a single gene. 
    * **Introns:** non-coding sequences of a gene. do not appear in mature mRNA molecules
    * **Exons:**- coding sequences of a gene. collectively make the final RNA molecule. 

### Notes: 

**[Meanings of certain lines of code used in bash for debugging:](https://gist.github.com/akrasic/380bda362e0420be08709152c91ca1f9)**

`set` is used to deliberately cause your script to fail

`set -e` instructs bash to immediately exit any command with a non-zero status

`set -x` enables a mode of the shell where all executed commands are printed to the terminal for debugging purposes

`set -u` when a reference to a variable you haven't previously defined is called, the program exits

`set -o pipefail` prevents errors in a pipeline from being masked such that if any command in a pipeline fails, that return code will be used as the return code of the whole pipeline. default behavior is the return code of the pipeline is that of the last command even if it succeeds. 

**Alternate way of doing if statement in bash:**
```
# standard way
if [ ... ]; then
  ...
else
  ...
fi

# alternate way
[ ... ] || {
   ...
}

# example of alternate way
  [ -f "$PROJECT_DIR/reference/genome.mmi" ] || { 
      echo "ERROR: genome.mmi missing"
      exit 1
  }
```


## March 20-25, 2026: 

- **What I ran/did:**
    * Tried to update my Codeberg repo with the work I have done thus far. Noticed that when I ran `git add .` it took a long time. I suspect its because there's a lot of files, some of which are in the gigabyte size range. 
    * Realized to set what can be tracked in Git and what can be kept locally but ignored in Git. This will involve changing the `.gitignore` file. 
    * I also need to move some files in the `raw_data/` folder elsewhere but I can do that once I'm done with the project and want to clean everything up. Can just make note of that in the `README.md` file for the repo. 
    * Set up a Google Cloud Compute Engine instance for Salmon analyses steps
- **What worked:**
- **What failed:**
- **Error messages:**
- **Learnings:**
    * `raw_data/` is only for downloaded inputs, `intermediate/` is for large generated files during the pipeline steps, and `results/` is for small summaries and final outputs
    * _**Perhaps I can make the cleaning and refinement step as the basis for learning Nextflow and Snakemake to show I understand pipeline design?**_ 

**How to choose the right VM on Google Cloud:**

![Diagram of compute families offerred by Google Cloud and their uses](/var/home/nyssa/Images/Captures%20d%E2%80%99%C3%A9cran/Capture%20d%E2%80%99%C3%A9cran%20du%202026-03-21%2016-20-12.png)

1. Machines are divided into General Purpose and Specialized
    1. General Purpose - balance compute resources and features suitable for most applications
        1. E - web & app servers, efficient
        2. N - web & app servers, flexible
        3. C - web & app servers, high-performance computing, performance
    2. Specialized - maximize performance for a specific resource type (compute, memory, or GPUs)
        1. H - high performance computing, compute
        2. M - memory
        3. X - memory
        4. Z - storage
        5. G - video transcoding, inference & visualization with GPUs
        6. A - all other GPU tasks
2. Flexibile compute families give you flexibility and control over exactly how much resources you use and pay for. 
3. Performance families give you the best performance and advanced maintenance features with near-zero downtime
4. Storage compute families suit a storage dense database that needs SSD
5. Parts of VM family names
    1. Example: `C4-highmem-16`
        1. Machine series/family: C4
        2. Machine type (CPU to memory ratio): highmem
        3. CPU count: 16 
6. To figure out how much CPU and memory you'll need to know what the applications require. Make sure you are paying exactly for what you need. Generally, highcpu types have the same CPU as highmem but with less memory. 
7. If you're not sure, start with something small, you can switch to a larger machine at any time. You'll get right-sizing recommendations in console to improve VM size based on real-time usage. 
8. Things to consider: reliability (99.95% availability SLA), disk performance (compatibile with hyper disk block storage or local SSDs), titanium (system of tiered scale-out offloads of block storage tasks to boost performance and reliability), security (encrypt data as they are being processed with confidential or shielded VMs and assured workloads), price and discounts (discounts with committed use, Spot VMs, dynamic workload scheduler)


[**How to use awk:**](https://www.commandinline.com/cheat-sheet/awk/)

Awk is a command that is designed to do pattern scanning and processing language tasks. Used to manipulate data, generate reports, making it essential for data extraction and reporting. It automates the process of analyzing text files to extract meaningful information instead of manually sifting. 
```
awk [OPTIONS] 'pattern {action}' [file...]

[OPTIONS] - optional flags that modify the behavior of the command

'pattern {action}' - specifies conditions and commands to be executed for each line that matches the pattern. the pattern can be a regular expression. the action is typically a sequence of statements enclosed in curly braces that specify what to do with the lines that match the pattern 

[file...] - one or more input files to process. if no files are specified, awk reads from standard input
```

[**How to use regex:**](https://www.geeksforgeeks.org/dsa/write-regular-expressions/)
```
# example: match a filename ending with .jpg, .png, or .gif

^[a-zA-Z0-9_-]+\.(jpg|png|gif)$

^ = start of string

[a-zA-Z0-9_-] = filename containing letters, numbers, underscore, hyphens

+ = matches the preceding character 1 or more times. eg: the regular expression ab+c will match abc, abbc, abbbc, etc...

\. = literal dot

(jpg|png|gif) = allowed extensions

$ = end of string

```

[**Common elements used in regex:**](https://www.geeksforgeeks.org/dsa/write-regular-expressions/)

1. Repeaters (*, +, and {}) specify how many times the preceding character or group should appear
    1. Asterisk symbol (*) - matches the preceding chracter 0 or more times. For example ab*c will giv ac, abc, abbc, abbbc, etc. 
    2. Plus symbol (+) - matches the preceding character 1 or more times. For example the regular expression ab+c will give abc, abbc, abbbc, etc. 
    3. The curly braces {...} - defines an exact or range of repetitions
        1. {2} is exactly 2 times
        2. {min,} is at least min times
        3. {min,max} is between min and max times
2. Wildcard (.) - matches any single character except a newline, any number of times
3. Optional character (?) - matches 0 or 1 occurrence of the preceding character. For example docx? matches doc and docx.
4. Caret (^) symbol - ensures the match starts at the beginning of the string. For example ^\d{3} matches 901 in 901-333. 
5. Dollar (`$`) symbol - ensures the match ends at the end of the string. For example `\d{3}$` matches 333 in 901-333
6. Character Classes - match specific types of characters
    1. \s - whitespace
    2. \S - non-whitespace
    3. \d - digit
    4. \D - non-digit
    5. \w - word character (letters, digits, _)
    6. \W - non-word character
    7. \b word boundary
7. Negated character class ([^]) - matches characters not listed in brackets. For example, [^abc] matches any character except a,b, 

[**How to use grep:**](https://www.commandinline.com/cheat-sheet/grep/)

Used to search text using patterns. Searches for patterns in each file and prints each line that matches a pattern. 
```
grep [OPTION...] PATTERNS [FILE...]
```

[**How to use sed:**](https://www.commandinline.com/cheat-sheet/sed/)

Used to filter and transform text. Can perform basic text manipulations such as search and replace, insertion, deletion, and pattern matching on an input stream or file. 

```
sed [OPTION...] 's/old/new/g'
```

**Bioinformatics file formats:**

1. ***Sequencing file types***
    1. [**FASTA**](https://en.wikipedia.org/wiki/FASTA_format) - represents nucleotide or amino acid sequences
    2. [**FASTQ**](https://en.wikipedia.org/wiki/FASTQ_format) - represents nucleotide or amino acid sequences and their corresponding quality scores. The quality score, often the Phred quality score, is the probability that the corresponding base call is incorrect. 
        1. Phred score of 10 = 1 in 10 probability of incorrect call = 90% base call accuracy
        2. Phred score of 20 = 1 in 100 probability of incorrect base call = 99%
        3. 30 = 1 in 1000 = 99.9%
        4. 40 = 1 in 10,000 = 99.99%
        5. 50 = 1 in 100,000 = 99.999%
        6. 60 = 1 in 1,000,000 = 99.9999%
        7. Phred score formula: $Q = -10log_{10}P$
2. ***Alignment file types***
    1. [**SAM**](https://en.wikipedia.org/wiki/SAM_(file_format)) - stores information for how well biological sequences (nucleotide or amino acid) aligned toa  reference sequence. Can use SAMtools to work through the files
        1. Alignment headers
            1. QNAME - query template name
            2. FLAG - bitwise FLAG
            3. RNAME - reference sequence name
            4. POS - 1 based leftmost mapping position
            5. MAPQ - mapping quality
            6. CIGAR - CIGAR string
            7. RNEXT - reference name of the mate/next read
            8. PNEXT - position of the mate/next read
            9. TLEN = observed template length
            10. SEQ = segment sequence
            11. QUAL = ASCII of phred-scaled base quality + 33
    2. [**BAM**](https://en.wikipedia.org/wiki/FASTQ_format) - stores the same data from SAM in a compressed binary format. 
3. ***Annotation file types***
    1. [**GFF3**](https://en.wikipedia.org/wiki/General_feature_format) - used to describe genes and other features of DNA, RNA, and protein sequences
        1. Structure headers:
            1. seqid = name of the sequence where the feature is located
            2. source = algorithm or procedure that generated the feature; name of software or database typically
            3. type = feature type name like "gene" or "exon". a well structured GFF will have child features follow their parents in a single block (e.g., all exons of a transcript are put after their parent "transcript" feature line before any other parent transcript line). features and relationships are compatible with standards released by sequence ontology project.
            4. start = genomic start of feature with 1-base offset
            5. end = genomic end of feature with a 1-base offset
            6. score = numeric value that generally indicates the confidence of the source in the annotated feature. "." (dot) defines a null value. 
            7. strand = strand of the feature (+ for positive or 5'->3', - for negative or 3'->5', . for undetermined, or ? for features with relevant but unknown strands)
            8. phase = phase of CDS features (0, 1, or 2) or "." for everything else
            9. attributes = list of tag value pairs separated by a semicolon with additional info about the feature
    2. [**GTF**](https://en.wikipedia.org/wiki/Gene_transfer_format) = based on GFF format but contains additional conventions specific to gene information
    3. [**BED**](https://en.wikipedia.org/wiki/BED_(file_format)) = stores genomic regions as coordinates and associated annotations
        1. Columns
            1. chrom = chromosome or scaffold name
            2. chromStart = start coordinate; zero-based
            3. chromEnd = end coordinate; non-inclusive; 1-based
            4. name = name of the line in the BED file
            5. score = score between 0 and 1000
            6. strand = DNA strand orientation (+, -, or .)
            7. thickStart = starting coordinate from which the annotation is displayed in a thicker way on a graphical representation
            8. thickEnd = end coordinates from which the annotation is no longer displayed in a thicker way on a graphical representation
            9. itemRgb = display color of the annotation contained in the BED file
            10. blockCount = number of blocks (e.g., exons) on the line of the BED file
            11. blockSizes = list of values separated by commas corresponding to the size of the blocks (number of values = blockCount)
            12. blockStarts = list of values separated by commas corresponding to the starting coordinates of the blocks (number of values = blockCount)
4. ***Variant calling file types***
    1. [**VCF**](https://en.wikipedia.org/wiki/Variant_Call_Format) = storing gene sequence or DNA sequence variations. 
        1. Columns
            1. CHROM = name of the sequence (typically a chromosome) on which a variant is being called. often called the reference sequence, or the sequence against which the given sample varies
            2. POS = 1-based position of the variation on the given sequence
            3. ID = identifier of the variation. "." if unknown. multiple identifiers should be separated with semi-colons without white-space
            4. REF = reference base (or bases in case of an indel) at the given position on the given reference sequence
            5. ALT = list of alternative alleles at this position
            6. QUAL = quality score associated with the inference of the given alleles
            7. FILTER = flag indicating which of a given set of filters the variation ahs failed or PASS if all filters were passed successfully
            8. INFO = extensive list of key-value pairs (fields) describing the variation. multiple fields are separated by semicolons with optional values in the format <key>=<data>[,data]. Examples are AA for ancestral allele, AF for allele frequency for each ALT allele, etc. 
            9. FORMAT = optional extensible list of fields for describing the samples. Examples are AD for read depth for each allele, DP for read depth, GT for genotype, PQ for phasing quality, etc. 
            10. SAMPLEs = for each optional sample described in the file, values are given fr the fields listed in FORMAT
    2. [**BCF**](https://en.wikipedia.org/wiki/Variant_Call_Format) = binary format of information stored in VCF file


**Documentation of tools used in this pipeline and their basic uses:**
[Source1](https://www.pacb.com/wp-content/uploads/Application-note-Bioinformatics-tools-for-full-length-isoform-sequencing.pdf)
[Source2](https://www.youtube.com/watch?v=lG11JjovJHE&list=PLoaiCOMxuDEvBHec1MTcgOtI5tllJzwDg&index=8&t=921s)

- [minimap2](https://lh3.github.io/minimap2/minimap2.html): long read mapping
- [FLAIR](https://flair.readthedocs.io/en/latest/): isoform collapse. can do so by sample and creates a high-confidence isoform set from combining long- and short-read data
- [Salmon](https://salmon.readthedocs.io/en/latest/salmon.html): short-read quantification/mapping. is considered a quasi-mapper
- [SUPPA2](https://github.com/comprna/SUPPA): AS event detection. can do across multiple conditions with replicates
- [DESeq2](https://bioconductor.org/packages/release/bioc/html/DESeq2.html): differential expression. used for both short and long reads. 
- [clusterProfiler](https://bioconductor.org/packages//release/bioc/html/clusterProfiler.html): GO enrichment
- [ggplot2](https://ggplot2.tidyverse.org/): visualization


## March 27-31, 2026:

- **What I did/ran:**
    * I restarted the project...yet again. I realized that my portfolio project was way too ambitious for my skill level. I thought I could learn RNA-seq using this project. And I could, but it would probably take much longer and result in more frustration and overwhelm. Especially since I don't have any pre-requisite knowledge in RNA-seq workflows, doing a highly ambitious project like this one would result in even more overwhelm on top of a weak skillset. It's better to just learn the basics, master that, and do so by scaling down the scope of the project to use the minimal amount of data needed to accomplish learning fundamental bioinformatics skills. I'm gonna accomplish this re-scoped project by adapting the learnings provided by KAUST Academy within the context of this Artemisia annua project. 
    * Made new directory structure for my portfolio project
    * Completed Lab 1 of the KAUST Academy Bioinformatics Specialization program
- **What worked:**
    * Environment setup based on KAUST academy instructions
    * Lab 1 of the KAUST Academy Bioinformatics specialization program
- **What failed:**
    * Having to remove my old anaconda, miniconda, and micromamba builds to make way for MiniForge 
- **Exact error messages:**
    * No errors, just anticipated build conflicts with anaconda, miniconda, and micromamba prior to installing MiniForge. Asked ChatGPT to help me clean up my system of these old builds so that I could install MiniForge cleanly. 
- **Learnings:**
    * Sometimes its okay to try things and realize its too much for you and scale back to your capacity. It doesn't mean you're dumb or stupid, it means you understand your limitations and are willing to work with yourself at your own pace, at your own skill-level, in order to make sure it gets done. 
    * I think I tend to be ambitious due to a combination of my former Gifted kid syndrome, neurodivergency, and the pressure to be perfect in an increasingly competitive world

### Notes: 

**Directory Structure Explained:**

- `raw_data/` - original FASTQ sfiles from sequencing
- `subsampled_data/` - subsampled reads for faster processing
- `trimmed_data` - quality-trimmed reads
- `references/` - genome, transcriptome, and annotation files
- `qc_reports/` - quality control reports (FASTQC, fastp, MultiQC)
- `alignment/` - BAM files from STAR alignment
- `salmon_quant` - transcript quantification results
- `counts/` - gene-level count matrices
- `results/` - final analysis outputs (tables, figures, enrichment)



**How to use AWK to read a GTF file (through illustrating the example of how to find the longest gene in a GTF file):**

**[Default syntax](https://www.geeksforgeeks.org/linux-unix/awk-command-unixlinux-examples/):**
`awk [options] 'pattern {action}' input-file > output-file`

- **awk:** starts the AWK text-processing program
- **[options]:** controls AWK behavior (e.g., -F to set field separator)
- **pattern:** specifies which lines to process (condition or regex)
- **{action}:** defines what to do with matching lines (usually print)
- **input-file:** file that AWK reads line by line
- **output-file:** redirects processed output into a file

_Given the command:_

```
awk -F'\t' $3=="gene"{
  len=$5-$4+1
  print $0 "\t" len
}' input.gtf | sort -k10,10nr | head -1
```

`awk` automatically splits each line in a delimited file into fields. Since, GTF files are tab-separated, awk will split each field/column using tab as the delimeter/separator. 

_How `awk` generally splits GTF files:_

| Column | Meaning |
|--------|---------|
| $1     | chromosome |
| $2     | source |
| $3     | feature type (gene, transcript, exon...) |
| $4     | start |
| $5     | end |
| $6     | score |
| $7     | strand |
| $8     | frame |
| $9     | attributes |

_Based on how `awk` splits GTF files, we can then decode the example command. Note, I wrote the code as a single-line making sure to replace newlines with ';' to separate statements:_

`awk -F'\t' $3=="gene"{len=$5-$4+1; print $0 "\t" len}' input.gtf | sort -k10,10nr | head -1`

- **awk [options]:** `awk -F'\t'`
    * Corresponds to the field separator option.
    * In this case, it is setting the tab as the field separator
    * By default, the fields are separated by spaces
- **pattern:** `$3=="gene"`
-   * `$3` corresponds to the feature type column/field
    * `=="gene"` refers to the filter condition being applied on the field/column. Here, it is filtering the feature type column for lines that contain the string "gene". 
- **{action}:**  `{len=$5-$4+1; print $0 "\t" len}`
-   * Here it is performing two actions: computing the gene length and printing the original line with the length.
    * To compute the gene length, the `len` function was used on fields `$4` and `$5` or start position and end position, respectively, to calculate the number of bases for that gene based on its known start and end positions in the genome. The `+1` is important because genomic coordinates are inclusive (e.g., start=100 and end=200 would be 101 bases not 100).
    * To print the original line, the `print` function was used on field `$0`, with said field corresponding to the entire line being read by AWK entirely. A tab was added with `"\t"` and then the computed len was printed by referring to the `len` function that stored a previous calculation.
    * By adding the tab in the print function, a new column was added at the end with the gene length. Thus the output lines now have 10 columns (original 9 + newly calculated length). 
- **input-file:** `input.gtf`
- **output-file:** no output file in this example, instead the output of `awk` was piped `|` into the `sort` and then piped again into the `head` functions.
-   * To sort by length in ascending order: `-k10,10nr` sorts using column 10 (the new length column added), `n` in this flag refers to numeric sort, `r` refers to reverse (largest -> smallest).
    * To take the top result (longest gene): `head -1` was used as it shows only the first line that pops up in the sorted output. 


**How to filter through the attributes field in a GTF file with awk, match, substr, and split**:

1. **Simple substring match**
     1. `awk -F'\t' '$9 ~ /gene_id "BRCA1"/' input.gtf`
     2. `$9` refers to the attributes column
     3. ` ~ /pattern/` refers to a regex match
     4. ***Logic of code:*** For every line in `input.gtf`, AWK puts column 9 into `$9` and then checks whether `$9` matches the regex `gene_id "BRCA1"`. If yes, it prints the whole line. If no, it skips it. AWK prints automatically without even explicitly calling the print function because in AWK, when you give only a pattern and no explicit action, the default action is `{ print $0 }`. Therefore these two lines of code are equivalent: `awk -F'\t' '$9 ~ /gene_id "BRCA1"/' input.gtf` and `awk -F'\t' '$9 ~ /gene_id "BRCA1"/ {print $0}' input.gtf`
3. **Filter by any attribute key**
     1. `awk '$9 ~ /gene_type "protein_coding"/' input.gtf`
     2. You can apply this logic for any attribute like `gene_type`, `gene_biotype`, `transcript_id`, etc.
     3. ***Logic of code:*** same as previous
5. **Extract specific attribute value**
     1. For example if we had attributes look like: `gene_id "ENSG000001"; transcript_id "ENST000001"; gene_name "BRCA1";`
     ```
     awk '
     { # this bracket means do the following for every line
       if (match($9, /gene_id "[^"]+"/)) { # searches for the first place where the regex (gene_id "[^"]+") occurs inside the string ($9)
         gene_id = substr($9, RSTART+9, RLENGTH-10)
         print gene_id # this will print only the extracted value because we set the variable to a substring of the original match. 
       }
     }' input.gtf
     ```
     2. ***Regex breakdown***: `gene_id` is literal text, `"` is the starting quote, `[^"]+` means one or more characters that are not a quote, `"` is the closing quote. Basically, the `"[^"]+"` part is searching for the value within the quotes in the attributes field (e.g., it searches for ENSG000001234 because it is within quotes in the attributes field gene_id "ENSG000001234"). 
     3. `match(string, regex)` searches for the first place where the regex occurs in the string. In other words, it finds the first position where the pattern occurs in the string. This function returns the starting position of the match and sets of two special AWK variables `RSTART` and `RLENGTH`. If no match is found, it returns 0.
     4. `RSTART` is the starting character position of the match
     5. `RLENGTH` is the length of the matched text
     6. `substr(string, start, length)` extracts just the value of the attribute (removes the quotes and the key such that gene_id "ENSG000001" is just ENSG000001 when outputted). To do this, it extracts a substring from `string` starting at `start`, of size `length`. 
          1. In this case, `RSTART+9` was used because the matched string starts at the `gene_id` part of `gene_id "ENSG000001234"`. Since the starting quote of the actual ID starts at character position 9 in the string, starting at `RSTART+9` jumps to the first character of the actual ID.
          2. `RLENGTH-10` was used because in order to remove the parts around the string we want, we need to subtract 9 for the `gene_id "` part and subtract 1 for the closing quote `"`, for a total of subtract 10. 
7. **Filter and extract together**
     1. Use if you want to filter for only protein-coding genes and then report the gene_id
     ```
     awk '
     $3=="gene" && $9 ~ /gene_type "protein_coding"/ {
       if (match($9, /gene_id "[^"]+"/)) {
         gene_id = substr($9, RSTART+9, RLENGTH-10)
         print gene_id
       }
     }' input.gtf
     ```
    2. Basically, a combination of example of **How to use AWK to filter a GTF file** plus the matching logic described in **extracting a specific attribute value**. The logic of this code is that it performs the matching only on the lines that contain both `"gene"` in column 3 and `gene_type "protein_coding"` in column 10.

9. **Complex cases**
     1. Use this instead of regex slicing.
     2. This splits attributes into key-value pairs, removes quotes safely, and works even if the order of the attributes changes
     ```
     awk '
     {
       gene_id = "" # added to clear the old gene_id values each line
       n=split($9, a, ";")
       for (i=1; i<=n; i++) {
         # can add: gsub(/^[ \t]+/, "", a[i]) here if you decide to use sub() instead of gsub() in the if-statement block. 
         if (a[i] ~ /gene_id/) {
           gsub(/^[ \t]+/, "", a[i]) # added to remove leading spaces on the left after splitting
           gsub(/gene_id "|"/, "", a[i])
           gene_id = a[i]
         }
       }
       if (gene_id != "") # added to ensure that only matched and cleaned lines are printed out 
         print gene_id
     }' input.gtf
     ```
      3. `split(string, array, delimeter)` breaks a string into parts such that in the example `n=split($9, a, ";")`, the string is `$9`, the array is `a`, and the delimeter is `";"`.
           1. So this means that if `$9` is `gene_id "ENSG1"; transcript_id "ENST1"; gene_name "ABC";`:
               1. `a[1] = gene_id "ENSG1"`
               2. `a[2] = transcript_id "ENST1"`
               3. `a[3] = gene_name "ABC"`
               4. `a[4] = ""` depending on trailing `;`
           2. `n` is the number of pieces (elements) in the array as split() returns an array. basically acts as a holder of the length of the array. 
      5. `for (i=1, i<=n; i++) {` loops overy every attribute piece in the array
      6. `if (a[i] ~ /gene_id/) {` checks whether the current piece/element in the array contains the string/regex pattern `gene_id`
      7. `gsub(regex, replacement, target)` replaces all matches of `regex` in `target` such that in the example `gsub(/gene_id "|"/, "", a[i])`, the regex is `gene_id "|"`, the replacement is empty string `""`, and the target is `a[i]`. This means it removes the literal text `gene_id "` and any other `"` character such that if `a[i]` starts as `gene_id "ENSG1"`, after `gsub()` it becomes `ENSG1`.
           1. Alternatively, you can use `sub(/^gene_id "/, "", a[i]` to remove the literal text/prefix and `sub(/"$/, "", a[i])` to remove the only ending quote. This avoids counting positions like `RSTART+9`
      9. `gene_id = a[i]` stores the cleaned value in the variable `gene_id`
      10. `print gene_id` prints the variable `gene_id`
10. **Summary of core AWK concepts:**
      1. General AWK syntax is `pattern { action }`
          1. If the pattern is omitted, action runs on every line 
          2. If the action is omitted, AWK prints the whole line for matching patterns. 
      2. You do not declare variables like `len` or `gene_id`, AWK creates them
      3. AWK automatically converts fields as needed so `$3=="gene"` will use string operations and `$5-$4+1` will use numeric operations.
      4. Regex operators:
          1. `~` means matches regex
          2. `!~` means does not match regex
      5. Built-string functions like `match()`, `substr()`, `split()`, and `gsub()` are the main tools for parsing the attributes field.
          1. Use `match() + substr()` when you want one specific value extracted diretly from the full attribute string
          2. Use `split()` when you want to parse several attributes or handle the field more systematically. 


## April 1, 2026:

- **What I did/ran:**
    * Started Lab 2 of the KAUST Academy Bioinformatics Specialization program
- **What worked:**
    * Lab 2 of the KAUST Academy Bioinformatics specialization program
- **What failed:**
- **Exact error messages:**
- **Learnings:**
    * It's very important to understand what you are studying (e.g., gene of interest, compound of interest) and the experimental design surrounding what you are studying. This is so you can orient your understanding of conducting bioinforamtics analyses. I can see how useful that is with Lab 2 of the KAUST Academy Bioinformatics Specialization program
 
### Notes: 

[**Understanding FASTQ File Format:**](https://bioinfo-kaust.github.io/academy-stage3-2026/html/lab2.html)

_Taken from Lab 2, Part 3, of the Bioinformatics Specialization Program by KAUST Academy_

FASTQ is the standard format for storing sequencing reads along with their quality scores. Each read consists of 4 lines:

_FASTQ Structure:_

```
@SRR10045016.1 1 length=70
NTGCAGTGCTGAGTCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGA
+
#AAFFFJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ
```

| Line | Content | Description |
|------|---------|-------------|
| 1 | @SRR10045016.1... | Read identifier (starts with @) |
| 2 | NTGCAGTG... | DNA sequence (A, T, G, C, N) |
| 3 | + | Separator (sometimes repeats ID) |
| 4 | #AAFFFJJ... | Quality scores (ASCII encoded) |

_Phred Quality Scores:_

Quality scores indicate the probability of a base call being correct

| Phred Score | Error Probability | Accuracy | ASCII (Phred+33) |
|-------------|-------------------|----------|------------------|
| 10 | 1 in 10 | 90% | + |
| 20 | 1 in 100 | 99% | 5 |
| 30 | 1 in 1,000 | 99.9% | ? |
| 40 | 1 in 10,000 | 99.99% | \| |


[**Paired-End Sequencing:**](https://bioinfo-kaust.github.io/academy-stage3-2026/html/lab2.html)

In paired-end sequencing, each DNA fragment is sequenced from both ends:

- **R1 (_1.fastq)**
    - :Forward read
- **R2 (_2.fastq)**
    - :Reverse read
      
 
## April 3 & 11, 2026:

- **What I did/ran:**
    * Continued Lab 2 of the KAUST Academy Bioinformatics Specialization program
- **What worked:**
    * Lab 2 of the KAUST Academy Bioinformatics specialization program (all except Part 6, 5 & 6).
- **What failed:**
    * Lab 2 Part 6 (5 & 6) produced output to the point where Jupyter had to temporarily stop showing output to prevent crashing. 
- **Exact error messages:**
    * IOPub message rate exceeded. The Jupyter server will temporarily stop sending output to the client in order to avoid crashing it. To change this limit, set the config variable. `--ServerApp.iopub_msg_rate_limit`. Current values: ServerApp.iopub_msg_rate_limit=1000.0 (msgs/sec) ServerApp.rate_limit_window=3.0 (secs)
- **Learnings:**
    * If there's too much output produced by a command in Jupyter Lab, you can send the output to a text file and then open the text file in a Jupyter notebook once the text file has been created. That way Jupyter Lab doesn't get overloaded and crash while the output is being produced in real-time. 
 
### Notes: 


[**SeqKit Quick Reference:**](https://bioinfo-kaust.github.io/academy-stage3-2026/html/lab2.html)

| Command | Description |
|---------|-------------|
| `seqkit stats` | Get sequence statistics |
| `seqkit sample` | Randomly subsample sequences |
| `seqkit grep` | Search by ID or sequence pattern |
| `seqkit subseq` | Extract subsequences by region |
| `seqkit seq` | Transform sequences (reverse, complement) |
| `seqkit fx2tab` | Convert FASTA/Q to tabular format |
| `seqkit fq2fa` | Convert FASTQ to FASTA |
| `seqkit rmdup` | Remove duplicate sequences |
| `seqkit common` | Find common sequences between files |

_For full documentation: `seqkit --help` or visit [SeqKit documentation](https://bioinf.shenwei.me/seqkit/)


**Performing math on columns using AWK:**

1. **Core Idea**
    - AWK treats columns as variables (`$1`, `$2`, etc)
    - You can directly do math on them
    - Example: `awk '{print $1, $2, $3+$4}' file.txt`. This adds columns 3 and 4. 
2. **Arithmetic operations**
    - You can use normal math operators: `+` (addition), `-` (subtraction), `*` (multiplication), `/` (division), `%` (modulo)
3. **REAL GTF example: gene length**
    - `awk '$3=="gene" {print $1, $4, $5, $5-$4+1}' input.gtf`
    - This filters for the rows with "gene" in column 3
    - Subtracts the start column `$4` from the end column `$5`
    - Adds 1 (start and end are inclusive coordinates)
4. **Assign results to variables**
    - Makes code cleaner and more readable
    - `awk '$3=="gene" {len = $5 - $4 + 1; print $1, len}' input.gtf`
    - Here `len` is just a variable (no declaration needed in AWK)
5. **Control output format**
    - By default, AWK separates output with spaces.
    - To force tabs, use `OFS` or Output Field Separator
    - `awk 'BEGIN{OFS="\t"} {print $1, $2+$3}' file.txt`
6. **Conditional math**
    - Only compute when certain conditions are met
    - `awk '$3=="exon" {print $5-$4+1}' input.gtf`. This shows only exon lengths. 
7. **Summing a column (VERY common)**
    - `awk '$3=="exon" {sum += $5-$4+1} END {print sum}' input.gtf`
    - ***Logic:*** `sum += value` accumulates, `END {}` runs after all lines are processed (in this case, runs after all values have been summed up. 
8. **Average calculation**
    - `awk '$3=="exon" {sum += $5-$4+1; count++} END {print sum/count}' input.gtf`
9. **Find max or min value**
    - ***To find the longest gene:*** `awk '$3=="gene" {len = $5-$4+1; if (len > max) max = len} END {print max}' input.gtf`
    - ***To keep track of which gene:*** `awk '$3=="gene" {len = $5-$4+1; if (len > max) {max = len; record = $0}} END {print record}' input.gtf`
10. **Working with FASTA (math on sequence length)**
    - `awk '/^>/ {next} {total += length($0)} END {print total}' file.fasta`. This counts total bases. 
11. **Math with multiple columns**
     - Given an example file:
       ```
       chr1 100 200
       chr1 300 450
       ```
     - ***Compute interval length:*** `awk '{print $3-$2}' file.txt`
12. **Percentage calculations**
     - Example with GC%: `awk '{gc = gsub(/[GC]/, ""); len = length($0); print (gc/len)*100 }' sequence.txt`
13. **Built-in math functions**
     - ***AWK has functions like:*** `sqrt()`, `log()`, `exp()`, `int()`
     - ***Example:*** `awk '{print sqrt($1)}' numbers.txt`
14. **Formatting numbers**
     - `awk '{printf "%.2f\n", $5/$4}' file.txt`. This prints 2 decimal places.
15. **Combine with filters**
     - `awk '$3=="gene" && $1="chr1" {len = $5-$4+1; print len}' input.gtf`
16. **Column math + sorting**
     - `awk '$3=="gene" {print $5-$4+1}' input.gtf | sort -nr | head`. This shows the top longest genes. 
17. **Avoid common mistakes**
     - ***Missing +1 in genomic length*** (i.e., `$5-$4+1` instead of `$5-$4`)
     - ***Division by zero*** (i.e., `if ($4 != 0) print $5/$4`)
     - ***Treating strings as numbers.*** Make sure columns actually contain numeric values. 
18. **Mental model**
     - ***Think of AWK like:*** "For each line -> compute something using columns -> print result"
19. **Most useful patterns (memorize these)**
     - ***Sum:*** `awk '{sum+=$1} END{print sum}' file`
     - ***Average:*** `awk '{sum+=$1; n++} END{print sum/n}' file`
     - ***Max:*** `awk '{if($1>max) max=$1} END{print max}' file`
     - ***Length calculation (GTF/BED)***: `awk '{print $3-$2+1}' file`
20. **Bioinformatics cheat patterns**
     - ***Gene lengths:*** `awk '$3=="gene" {print $5-$4+1}' file.gtf`
     - ***Total exon length:*** `awk '$3=="exon" {sum+=$5-$4+1} END{print sum}' file.gtf`
     - ***Count sequences:*** `grep -c "^>" file.fasta`
     - ***Total bases:*** `awk '!/^>/ {sum+=length} END{print sum}' file.fasta`
21. **Final intuition**
     - AWK math is simple because:
        - columns = variables
        - operations = normal math
        - loops happen automatically (line by line)
     - So you're basically writing: "For each row, compute X using columns Y and Z."


**Adding/Removing/Changing Columns in AWK:**

1. **Adding/appending a column**
    - `awk '{print $0, <calculation>}' file`
    -  `$0` = whole original line
    -  `<calculation>` = your math result
    -  You can add `BEGIN{OFS="\t"}` before the main `{print...` to format the output with tabs, which is important for GTF files.
    -  You can set the calculation to a variable to make it cleaner. Easier to read, debug, and reuse variable this way:
       ```
       awk 'BEGIN{OFS="\t"} {
       len = $5 - $4 + 1
       print $0, len
       }' input.gtf
       ```
2. **Adding/appending multiple new columns:**
    ```
    awk 'BEGIN{OFS="\t"} {
    len = $5-$4+1
    mid = ($4+$5)/2
    print $0, len, mid
    }' input.gtf
    ```
    - This adds column 10 with the value of length and column 11 with the value of the midpoint. 
3. **Replacing versus appending:**
    - ***Appending:*** `print $0, value`
    - ***Replacing:***
      ```
      $5 = $5 - $4 + 1
      print
      ```
    - ***Example:***
      ```
      awk 'BEGIN{OFS="\t"} {
      $5 = $5 - $4 + 1
      print
      }' input.gtf
      ```
4. **Change name of newly appended column**
    - ***Add a new column name (most common solution):*** `awk 'BEGIN{OFS="\t"} NR==1 {print $0, "length"} {print $0, $5-$4+1}' file.txt`. `NR==1` is the first line. Print the original header + `"length"`. Then print all rows with computed value. 
    - 
6. **Remove newly appended column**
    - ***If you appended a column at the end, just drop the last field:*** `awk 'BEGIN{OFS="\t"} {NF--; print}' file.txt`
    - `NF` is the number of fields
    - `NF--` reduces field count by 1
    - AWK automatically drops the last column
    - ***Remove specific column (e.g., column 10):*** `cut -f1-9`
    - ***Remove column N (general):*** `awk -v col=N '{for(i=1;i<=NF;i++) if(i!=col) printf "%s%s",$i,(i==NF?ORS:OFS)}'`


## April 17-19th, 2026

- **What I ran/did:**  
    * Created distrobox container (installed new OS on my computer since old OS was causing issues)
    * Re-created mamba envs for genomics and jupyter-lab (due to installing new OS on computer)
    * Continued Lab 3 of KAUST Academy (started on April 12th)
- **What worked:**
    * Creating distrobox container
    * Creating mamba envs
- **What failed:**
    * none
- **Exact error message:** 
    * none
- **Learnings:**
    * How to recreate mamba envs from a yaml file.
    * How to create a distrobox container

### Notes


**BEGIN and END in AWK:**

Given this syntax: `awk 'BEGIN{...} pattern { ... } END{...}` 
- `BEGIN { ... }` runs once before reading input
    * Use this block for:
       * Setting variables: `awk 'BEGIN{cutoff=1000} $5-$4+1 > cutoff' input.gtf`
       * Formatting output: `awk 'BEGIN{OFS="\t"} {print $1, $2}' file.txt` 
       * Printing headers:  `awk 'BEGIN{print "chr\tlength"} {print $1, $5-$4+1}' input.gtf`
- `pattern { ... }` runs for each matching line to the pattern
    * Run for each line that matches condition/pattern: `awk $3=="gene" {print} input.gtf`
    * Run for every line: `awk {print} file.txt`
- `END { ... }` runs once after all input lines have been processed
    * Use this block for:
       * Totals: `awk '{sum += $1} END{print sum}' file.txt`
       * Averages: `awk '{sum+=$1; n++} END{print sum/n}' file.txt`
       * Summaries
- Can have multiple `BEGIN` or `END` blocks, they just run in order.
- `BEGIN` and `END` do not see file lines unless you explicitly read input. 
 
Mental model of AWK with BEGIN and END blocks:

1. BEGIN -> setup once (before data)
2. for each line
    1. apply condition + action (process each line)
3. END -> finalize once (summarize after data)

Together these blocks let you turn `awk` into a mini data-processing program. 

Template: 
```
awk '
BEGIN {
  OFS="\t"
  print "gene_length"
}
$3=="gene" {
  len = $5-$4+1
  print len
  total += len
}
END {
  print "Total:", total
}' input.gtf
```

Example (use awk to count total bases in the fasta file:
```
awk '
BEGIN {
  total = 0
}
/^>/ {next}
{
  total += length($0)
}
END {
  print "Total bases:", total
}' file.fasta
```


**Regex Cheat Sheet/Operators for Bioinformatics:**
A regular expression (regex) is just a pattern used to match text. Think of it like "find text that looks like THIS shape". It lets you describe that pattern without knowing the exact string.

Most important symbols for regex:
- `abc` - matches exact text
- `.` - matches any character
- `*` - matches zero or more characters
- `+` - matches one or more characters
- `?` - optional match (0 or 1)
- `[ ]` - match any characters in the set
- `[^ ]` - match any character except the ones in the set
   * `[^"]` - match anything except `"`
- `^` - matches at the start of the string
- `$` - matches at the end of the string
- To match any of these special characters literally, use `\` before each character (i.e., `\.` to match a literal dot)


**How to use grep to read a FASTA file:**


**How to use cut, uniq, wc, and tr functions with GTF or FASTA files:**



**Debugging an AWK filter:**
`awk -F'\t' '



**How to build a mamba environment from a yaml file:**
```
mamba env create -f environment.yml
```

**How to install, create, and use a [distrobox container](https://distrobox.it/):**

Distrobox is the best alternative to toolbx on Debian-based systems. Toolbx is for Fedora-based systems. 

```
# to install
sudo apt install distrobox

# to create
distrobox create --name [CONTAINER NAME (e.g., devbox)] --image [CONTAINER IMAGE (e.g., ubuntu:22.04]

# to enter
distrobox enter devbox

# to exit
exit

# to list
distrobox list

```