#!/usr/bin/env bash
# =============================================================================
# run_pipeline.sh — RNA-seq pipeline wrapper
# =============================================================================
# This script is the entry point for the entire pipeline. It:
#   1. Parses config.yaml into shell variables
#   2. Reads samples.csv into arrays
#   3. Accepts flags to control which steps and samples to run
#   4. Calls each step script with the right arguments
#
# Usage:
#   bash run_pipeline.sh                                     # run all steps, all samples
#   bash run_pipeline.sh --steps qc_raw trim align           # specific steps only
#   bash run_pipeline.sh --samples ctrl_1 treat_1            # specific samples only
#   bash run_pipeline.sh --steps trim --samples ctrl_1       # combine both
#   bash run_pipeline.sh --dry-run                           # preview commands only
#   bash run_pipeline.sh --config path/to/config.sh          # use a different config
# =============================================================================

set -euo pipefail
# set -e   : exit immediately if any command returns a non-zero exit code
# set -u   : treat unset variables as errors (catches typos in variable names)
# set -o pipefail  : if any command in a pipe (cmd1 | cmd2 ) fails, the whole
#                    pipe fails — without this, only the last command is checked

# =============================================================================
# ENVIRONMENT CHECK
# Verify the genomics conda environment is active before running anything.
# If this fails, no config is loaded and no tools are called — fast, clean exit.
# =============================================================================

if [[ "${CONDA_DEFAULT_ENV:-}" != "genomics" ]]; then
    echo "ERROR: The 'genomics' environment is not active."
    echo ""
    echo "Activate it first with:"
    echo "  micromamba activate genomics"
    echo "     or"
    echo "  conda activate genomics"
    echo "     or"
    echo "  mamba activate genomics"
    echo ""
    echo "If you haven't set up the environment yet, run:"
    echo "  bash setup_environment.sh"
    echo ""
    exit 1
fi


# =============================================================================
# SECTION 1: DEFAULTS
# Set default values before parsing arguments. 
# --config and --dry-run can override these
# =============================================================================

CONFIG="config.yaml"   # default config file location
DRY_RUN=false          # default: actually run commands
STEPS_FILTER=()        # empty = run all steps
SAMPLES_FILTER=()      # empty = run all samples

# The ordered list of all valid step names.
# This order controls the sequence steps to run in — don't rearrange it.
ALL_STEPS=(
    subsample
    qc_raw
    trim
    qc_trimmed
    align
    quantify
    count
    multiqc
)

# ==============================================================================
# SECTION 2: ARGUMENT PARSING
# Loop through all arguments passed on the command line and handle each flag.
# ==============================================================================

# 'while [[ $# -gt 0 ]]' loops as long as there are arguments remaining.
# $# is the number of remaining arguments.
while [[ $# -gt 0 ]]; do
    case "$1" in
        
        --config)
            # $2 is the value after the flag (e.g. --config my_config.yaml)
            CONFIG="$2"
            shift 2   # shift 2 removes both the flag and its value from $@
            ;;
        
        --dry-run)
            DRY_RUN=true
            shift     # shift 1 removes just this flag (no value follows it)
            ;;
        
        --steps)
            # Collect all step names that follow --steps until the next flag.
            # e.g. --steps trim align quantify → STEPS_FILTER=(trim align quantify)
            shift     # remove --steps itself, so $1 is now the first step name
            while [[ $# -gt 0 && "$1" != --* ]]; do
                # "$1" != --* means: stop if the next token starts with --
                # (i.e. it's another flag, not a step name)
                STEPS_FILTER+=("$1")
                shift
            done
            ;;

        --samples)
            # Same pattern as --steps: collect all sample IDs that follow.
            shift
            while [[ $# -gt 0 && "$1" != --* ]]; do
                SAMPLES_FILTER+=("$1")
                shift
            done
            ;;
        
        --help | -h)
            # Print usage and exit cleanly.
            echo "Usage: bash run_pipeline.sh [--config FILE] [--steps STEP ...] [--samples ID ...] [--dry-run]"
            echo "Steps: ${ALL_STEPS[*]}"
            exit 0
            ;;
        
        *)
            # Catch any unrecognized flags and exit with an error.
            echo "ERROR: Unknown argument: $1"
            echo "Run with --help for usage."
            exit 1
            ;;
    esac
done

# ==============================================================================
# SECTION 3: LOGGING
# All messages go through log_info / log_error so they are consistently
# timestamped and written to both the terminal and a log file.
#
# LOG_FILE is set to an empty string here and updated after we source the
# config (which is where we learn the log directory path).
# ==============================================================================

LOG-FILE=""   # will be set after sourcing config

log() {
    # log LEVEL MESSAGE
    # Interval function — use log_info / log_error at call sites.
    local level="$1"
    local msg="$2"
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local line="${timestamp} [${level}] ${msg}"

    echo "$line"   # always print to terminal

    # Only write to the log file once LOG_FILE has been set (non-empty).
    # [[ -n STRING ]] is true if the string is non-empty.
    [[ -n "$LOG_FILE" ]] && echo "$line" >> "$LOG_FILE"
}

log_info()    { log "INFO"    "$1"; }
log_warming() { log "WARNING" "$1"; }
log_error()   { log "ERROR"   "$1"; }

# ==============================================================================
# SECTION 4: SOURCE CONFIG
# 'source' (or equivalently '.') reads a shell script into the current shell
# and executes it. Every variable defined in config.sh becomes available here.
# ==============================================================================

# Check the config file exists before trying to source it.
# This gives clear error if someone passes a wrong --config path.
if [[ ! -f "$CONFIG" ]]; then
    # We use echo here (not log_error) because LOG_FILE isn't set yet.
    echo "ERROR: Config file not found: ${CONFIG}"
    exit 1
fi

# 'source' executes config.sh in the current shell process.
# After this line, all variables from config.sh (THREADS, TRIMMED_DIR, etc.)
# are available as if they had been defined directly in this script.
source "$CONFIG"

# Now that LOGS_DIR is defined (from config.sh), creates the log directory
# and point LOG_FILE at it. All subsequent log_info calls will write here.
mkdir -p "$LOGS_DIR"
LOG_FILE="${LOGS_DIR}/pipeline.log"

log_info "Config sourced: ${CONFIG}"
log_info "Log file: ${LOG_FILE}"

# ==============================================================================
# SECTION 5: LOAD SAMPLES
# Read samples.csv into a bash array. Each element holds one full CSV line.
# We use Python here because bash CSV parsing breaks on edge cases (spaces
# in paths, quoted fileds, etc.) — Python's csv module handles these correctly.
#
# Each line is stored as: sample_id,condition,replicate,r1,r2
# We split it into individual variables later in the sample loop (Section 8).
# ==============================================================================

# Validate that the samples CSV path is set and the file exists.
if [[ -z "${SAMPLES_CSV:-}" ]]; then
    log_error "SAMPLES_CSV is not set in ${CONFIG}"
    exit 1
fi
if [[ ~ -f "$SAMPLES_CSV" ]]; then
    log_error "Samples file not found: ${SAMPLES_CSV}"
    exit 1
fi

# mapfile reads lines from a command's output into a bash array.
# -t strips the trailing newline from each element.
# < <(command) is process substitution — it feeds the command's stdout
# into mapfile as if it were a file. This is more readable than a pipe
# because pipes run in a subshell and can't modify the parent's variables.
mapfile -t ALL_SAMPLES < <(
    python3 - "$SAMPLES_CSV" << 'PYEOF'
import csv, sys

with open(sys.argv[1]) as f:
    reader = csv.DictReader(f)
    for row in reader:
        # Print one line per sample in a fixed comma-separated format.
        # The wrapper splits this back into fields in the sample loop.
        print(f"{row['sample_id']},{row['condition']},{row['r1']},{row['r2']}")
PYEOF
)

# Validate we got at least one sample.
if [[ ${#ALL_SAMPLES[@]} -eq 0 ]]; then
    log_error "No samples found in: ${SAMPLES_CSV}"
    exit 1
fi

log_info "Loaded ${#ALL_SAMPLES[@]} samples(s) from ${SAMPLES_CSV}"

# ==============================================================================
# SECTION 6: FILTER SAMPLES
# If --samples was given, narrow ALL_SAMPLES down to only the requested IDs.
# If --samples was not given, ALL_SAMPLES stays as-is (run everything).
# ==============================================================================

if [[ ${#SAMPLES_FILTER[@]} -gt 0 ]]; then
    FILTERED_SAMPLES=()

    for sample_line in "${ALL_SAMPLES[@]}"; do
        # 'cut -d',' -f1' splits on comma and returns the first field (sample_id).
        sid=$(echo "$sample_line" | cut -d',' -f1)

        # Check if this sample_id appears in SAMPLES_FILTER.
        for requested in "${SAMPLES_FILTER[@]}"; do
            if [[ "$sid" == "$requested" ]]; then 
                FILTERED_SAMPLES+=("$sample_line")
                break   # stop checking SAMPLES_FILTER for this sample
            fi
        done
    done

    if [[ ${FILTERED_SAMPLES[@]} -eq 0 ]]; then
        log_error "No matching samples found for: ${SAMPLES_FILTER[*]}"
        log_error "Available samples: $(printf '%s ' "${ALL_SAMPLES[@]}" | cut -d',' -f1)"
        exit 1
    fi

    # Replaces ALL_SAMPLES with the filtered subset.
    ALL_SAMPLES=("${FILETERED_SAMPLES[@]}")
    log_info "Filtered to ${#ALL_SAMPLES[@]} sample(s): ${SAMPLES_FILTER[*]}"
fi

# ==============================================================================
# SECTION 7: STEP CONTROL
# should_run_step checks whether a given step should execute.
# IF STEPS_FILTER is empty (--steps not given), all steps run.
# IF STEPS_FILTER is set, only steps in the list run.
# ==============================================================================

should_run_step() {
    # should_run_step STEP_NAME
    # Returns 0 (bash true) if the step should run, 1 (bash false) if not.
    # In bash, 0 = success = true, and non-zero = failure = false.
    local step="$1"

    # No filter set -> run everything.
    if [[ ${#STEPS_FILTER[@]} -eq 0 ]]; then
        return 0
    fi

    # Filter set → only run if this step is in the list.
    for s in "${STEPS_FILTER[@]}"; do
        if [[ "$s" == "$step" ]]; then
            return 0   # found — run it
        fi
    done

    return 1   # not found — skip it
}


# ==============================================================================
# SECTION 8: COMMAND RUNNER
# Every call to a step script goes through run_cmd.
# This centralises dry-run handling, logging, and error checking so each
# step call site stays clean (just one run_cmd line per step).
# ==============================================================================

run_cmd() {
    # run_cmd "COMMAND STRING" "LOG_FILE_PATH"
    local cmd="$1"
    local cmd_log="$2"

    log_info "CMD: ${cmd}"

    # In dry-run mode, print the command and return without running it.
    if [[ "$DRY_RUN" == true ]]; then
        return 0
    fi

    # Create the log file's parent directory if it doesn't exist yet.
    # dirname extracts the directory part of a path:
    #   dirname "logs/star/ctrl_1.log" → "logs/star"
    mkdir -p "$(dirname "$cmd_log")"

    # Run the command via eval and redirect all output (stdout + stderr)
    # to the step's log file.
    #
    # We use eval because $cmd is a string that may contain pipes (|) and
    # redirects (>) that bash needs to interpret as shell operators, not
    # literal characters. eval re-parses the string as a shell command.
    #
    # >> appends to the log file (rather than overwriting).
    # 2>&1 redirects stderr (file descriptor 2) to stdout (fd 1),
    # so both streams go into the same log file.
    if ! eval "$cmd" >> "$cmd_log" 2>&1; then
        log_error "Command failed (exit code: $?). See: ${cmd_log}"
        exit 1
    fi
}

# ==============================================================================
# SECTION 9: RUN SUMMARY
# Log what we're about to do before starting — makes the log easy to audit.
# ==============================================================================

[[ "$DRY_RUN" == true ]] && log_info "--- DRY RUN: commands will be printed but not executed ---"

# Build a display list of just the sample IDs (not the full CSV lines).
SAMPLE_ID_LIST=()
for s in "${ALL_SAMPLES[@]}"; do
    SAMPLE_ID_LIST+=("$(echo "$s" | cut -d',' -f1)")
done

# ${VAR[*]:-fallback} uses 'fallback' if VAR is empty.
log_info "Steps    : ${STEPS_FILTER[*]:-all}"
log_info "Samples  : ${SAMPLE_ID_LIST[*]}"


# ==============================================================================
# SECTION 10: PER-SAMPLE STEPS
# Loop over every sample and run each requested steps in order.
# Each step script receives its inputs as positional arguments.
#
# Why positional arguments (not environment variables)?
# The step scripts are designed to be standalone — you can run them directly
# form the terminal with explicit arguments for debugging without needing to
# source config.sh first. Positional args make inputs visible at the call site.
# ==============================================================================

for sample_line in "${ALL_SAMPLES[@]}"; do
    
    # Split the comma-separated sample line back into individual variables.
    # IFS=',' sets comma as the field separator for this 'read' call only.
    # -r prevents backslash from being treated as an escape character.
    # <<< is a here-string: it feeds $sample_line to 'read' as stdin.
    IFS=',' read -r SID CONDITION REPLICATE R1 R2 <<< "$sample_line"

    log_info "--- Sample: ${SID} (${CONDITION}) ---"

    # ---- subsample ----
    # Randomly select N reads from raw FASTQ files for faster dev/testing.
    if should_run_step "subsample"; then
        log_info ">>> [subsample] ${SID}"
        run_cmd \
            "bash scripts/subsample.sh ${SID} ${R1} ${R2} ${SUBSAMPLED_DIR} ${SUBSAMPLE_N}" \
            "${LOGS_DIR}/subsample/${SID}.log"
    fi

    # ---- qc_raw ----
    # FastQC on raw reads to establish a quality baseline before trimming.
    if should_run_step "qc_raw"; then
        log_info ">>> [qc_raw] ${SID}"
        run_cmd \
            "bash scripts/qc_raw.sh ${SID} ${R1} ${R2} ${QC_RAW_DIR} ${THREADS} ${FASTQC}" \
            "${LOGS_DIR}/fastqc_raw/${SID}.log"
    fi

    # ---- trim ----
    # Remove low-quality bases and adapter sequences with fastp.
    if should_run_step "trim"; then
        log_info ">>> [trim] ${SID}"
        run_cmd \
            "bash scripts/trim.sh ${SID} ${R1} ${R2} ${TRIMMED_DIR} ${QC_FASTP_DIR} ${THREADS} ${FASTP_MIN_LEN} ${FASTP_QUAL} ${FASTP_UNQUAL_PCT} ${FASTP}" \
            "${LOGS_DIR}/fastp/${SID}.log"
    fi

    # ---- qc_trimmed ----
    # FastQC on trimmed reads to confirm adapters and low-quality bases are gone.
    if should_run_step "qc_trimmed"; then
        log_info ">>> [qc_trimmed] ${SID}"
        run_cmd \
            "bash scripts/qc_trimmed.sh ${SID} ${TRIMMED_DIR} ${QC_TRIMMED_DIR} ${THREADS} ${FASTQC}" \
            "${LOGS_DIR}/fastqc_trimmed/${SID}.log"
    fi

    # ---- align ----
    # Map trimmed reads to the reference genome with STAR.
    # STAR_SAM_TYPE contains a space ("BAM SortedByCoordinate"), so we
    # wrap it in quotes to pass it as a single argument to align.sh
    if should_run_step "align"; then
        log_info ">>> [align] ${SID}"
        run_cmd \
            "bash scripts/align.sh ${SID} ${TRIMMED_DIR} ${ALIGNMENT_DIR} ${STAR_INDEX} ${REF_GTF} ${THREADS} \"${STAR_SAM_TYPE}\" ${STAR_SAM_ATTR} ${STAR_GENOME_LOAD} ${STAR}" \
            "${LOGS_DIR}/star/${SID}.log"
    fi

    # ---- quantify ----
    # Estimate transcript expression with Salmon using the STAR BAM.
    if should_run_step "quantify"; then
        log_info ">>> [quantify] ${SID}"
        run_cmd \
            "bash scripts/quantify.sh ${SID} ${ALIGNMENT_DIR} ${SALMON_DIR} ${REF_TRANSCRIPTOME} ${REF_GTF} ${SALMON_LIB_TYPE} ${THREADS} ${SALMON}" \
            "${LOGS_DIR}/salmon/${SID}.log"
    fi

done


# ==============================================================================
# SECTION 11: GLOBAL STEPS
# These run once after all samples are processed.
# They operate across all samples rather than one at a time.
# ==============================================================================

# ---- count ----
# Merge all per-sample Salmon quant.sf files into one counts matrix CSV.
if should_run_step "count"; then
    log_info ">>> [count]"
    run_cmd \
        "bash scripts/count.sh ${SALMON_DIR} ${COUNTS_DIR}" \
        "${LOGS_DIR}/counts/merge.log"
fi

# ---- multiqc ----
# Aggregate all QC reports (FastQC, fastp, STAR, Salmon) into one HTML report.
if should_run_step "multiqc"; then
    log_info ">>> [multiqc]"
    run_cmd \
        "bash scripts/multiqc.sh ${QC_RAW_DIR} ${QC_TRIMMED_DIR} ${QC_FASTP_DIR} ${ALIGNMENT_DIR} ${SALMON_DIR} ${RESULTS_TABLES} ${MULTIQC}" \
        "${LOGS_DIR}/multiqc/multiqc.log"
fi


log_info "Pipeline complete."

