#!/bin/bash

SECONDS=0

# change working directory
WORK_DIR="$HOME/artemisia-annua-rna-seq-project"

mkdir -p $WORK_DIR

cd $WORK_DIR

# set temporary environment variables for the session
export VDB_CONFIG=/var/home/$USER/sra_temp
export SRA_CACHE=/var/home/$USER/sra_temp
export MAX_THREADS=16
export SRA_MAX_MEM=32G

# STEP 1: 
# based this on a python script made by Erick Lu (https://erilu.github.io/python-fastq-downloader/)

# loop will download the .sra files to ~/sra_temp/sra/

function LoopSRA
{
m=${#SraNumbers[@]}
for (( i=0; i<m; i++))
do
  echo "Currently downloading: ${SraNumbers[$i]}"
  prefetch ${SraNumbers[$i]} --progress
  echo "The command used was: prefetch ${SraNumbers[$i]}"
done
}

function LoopFASTQ
{
m=${#SraNumbers[@]}
for (( i=0; i<m; i++))
do
  echo "Generating fastq for: ${SraNumbers[$i]}"
  fasterq-dump \
    --outdir $HOME/artemisia-annua-rna-seq-project/raw_data \
    --threads 16 \
    --split-files \
    --progress \
    $HOME/sra_temp/sra/${SraNumbers[$i]}.sra
  echo "The command used was: fasterq-dump --outdir $HOME/artemisia-annua-rna-seq-project/raw_data --threads 16 --split-files --progress $HOME/sra_temp/sra/${SraNumbers[$i]}.sra"
done
}

# SRA IDs corresponding to B3, B1, B2, RL2, RL3, WL1, WL2, WL3, RL3
SraNumbers=(SRR6808226 SRR6808227 SRR6808228 SRR6808229 SRR6808230 SRR6808231 SRR6808232 SRR6808239 SRR6808240)

LoopSRA ${SraNumbers[@]}

# extract the .sra files from above into a folder named fastq

LoopFASTQ ${SraNumbers[@]}

duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
