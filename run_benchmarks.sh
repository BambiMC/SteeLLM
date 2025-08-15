#!/bin/bash

# ==============================================================================
#  LLM BENCHMARK RUNNER SCRIPT
# ==============================================================================
#
#  Description:
#  This script runs a suite of security and safety benchmarks against a
#  specified Hugging Face language model.
#
#  Usage:
#  ./run_benchmarks.sh --model meta-llama/Llama-2-7b-chat-hf
#  ./run_benchmarks.sh -m Qwen/Qwen3-32B -t jailbreakscan --timeout 10m
#  ./run_benchmarks.sh --model google/gemma-3n-E4B-it --task openpromptinjection
#
# ==============================================================================

# --- Configuration ---
# Set default values for parameters that can be overridden by command-line flags.
DEFAULT_TIMEOUT="0"
DEFAULT_TASK="all"
MODEL_NAME=""
TASK_TO_RUN=""
TIMEOUT=""

# --- Helper Functions ---

# Function to print usage information and exit.
usage() {
    echo "Usage: $0 -m <model_name> [-t <task_name> | all] [--timeout <duration>]"
    echo ""
    echo "Options:"
    echo "  -m, --model <model_name>    (Required) The Hugging Face model identifier (e.g., 'meta-llama/Llama-2-7b-chat-hf')."
    echo "  -t, --task <task_name>      The specific benchmark to run. Use 'all' to run all benchmarks. (Default: $DEFAULT_TASK)"
    echo "      --timeout <duration>    Set a timeout for each benchmark (e.g., '5m', '1h')."
    echo "                              Set to '0' or 'none' to disable the timeout."
    echo "                              (Default: $DEFAULT_TIMEOUT)"
    echo "  -h, --help                  Display this help message."
    exit 1
}

# Function to run a single benchmark with logging and an optional timeout.
run_benchmark() {
    local task_name=$1
    local script_name=$2
    local model=$3
    local timeout_duration=$4
    local status

    echo "------------------------------------------------------------"
    printf " STARTING BENCHMARK: %s\n" "$task_name"
    echo "------------------------------------------------------------"
    
    # Conditionally execute with or without the 'timeout' command.
    if [[ "$timeout_duration" == "0" || "$timeout_duration" == "none" ]]; then
        printf "Executing without a timeout.\n"
        bash "$script_name" "$model"
        status=$?
    else
        printf "Executing with a timeout of %s.\n" "$timeout_duration"
        timeout "$timeout_duration" bash "$script_name" "$model"
        status=$?
    fi

    # Check the exit status of the benchmark script.
    if [ $status -eq 124 ]; then
        printf "❌ BENCHMARK TIMEOUT: '%s' exceeded the %s limit.\n\n" "$task_name" "$timeout_duration"
    elif [ $status -ne 0 ]; then
        printf "⚠️ BENCHMARK FAILED: '%s' exited with status %d.\n\n" "$task_name" "$status"
    else
        printf "✅ BENCHMARK COMPLETED: '%s'\n\n" "$task_name"
    fi
    
    # Pause briefly before the next benchmark.
    sleep 2
}

# --- Argument Parsing ---
# Parse command-line options.
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -m|--model) MODEL_NAME="$2"; shift ;;
        -t|--task) TASK_TO_RUN="$2"; shift ;;
        --timeout) TIMEOUT="$2"; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter passed: $1"; usage ;;
    esac
    shift
done

# --- Script Execution ---

# Validate that the required model parameter was provided.
if [ -z "$MODEL_NAME" ]; then
    echo "Error: Model name is required."
    usage
fi

# Set default values for task and timeout if they weren't provided.
TASK_TO_RUN=${TASK_TO_RUN:-$DEFAULT_TASK}
TIMEOUT=${TIMEOUT:-$DEFAULT_TIMEOUT}

# Source utilities and set up the environment.
# This assumes benchmark_setup exports HF_MODEL_NAME.
source "ressources/utils.sh"
benchmark_setup "$MODEL_NAME" "$TASK_TO_RUN"

echo "============================================================"
echo "  BENCHMARK RUNNER CONFIGURATION"
echo "============================================================"
echo "  Model:      $HF_MODEL_NAME"
echo "  Task(s):    $TASK_TO_RUN"
# Display timeout status clearly.
if [[ "$TIMEOUT" == "0" || "$TIMEOUT" == "none" ]]; then
    echo "  Timeout:    Disabled"
else
    echo "  Timeout:    $TIMEOUT"
fi
echo "============================================================"
echo ""

cd scripts || { echo "Error: 'scripts' directory not found. Please run this script from the project root."; exit 1; }

# Define all available benchmarks in an associative array for easy management.
# Keys are the task names, and values are the corresponding script files.
declare -A benchmarks=(
    ["agentdojo"]="agentdojo_run.sh"
    ["autodan"]="autodan_run.sh"
    ["autodan-turbo"]="autodan-turbo_run.sh"
    ["backdoorllm"]="backdoorllm_run.sh"
    ["badchain"]="badchain_run.sh"                  # TODO Note: Works, calculates metrics at the end.
    ["harmbench"]="harmbench_run.sh"
    ["jailbreakbench"]="jailbreakbench_run.sh"
    ["jailbreakscan"]="jailbreakscan_run.sh"        # TODO Note: Disabling 'thinking' and using fewer max_tokens is preferred for less evasive responses.
    ["llm-attacks"]="llm-attacks_run.sh"
    ["masterkey"]="masterkey_run.sh"                # TODO Note: Works, requires building an _eval function to parse results.txt.
    ["mjp"]="mjp_run.sh"
    ["openpromptinjection"]="openpromptinjection_run.sh"
    ["purplellama"]="purplellama_run.sh"
)

# Run the selected task(s).
if [[ "$TASK_TO_RUN" == "all" ]]; then
    # Loop through all defined benchmarks and run them sequentially.
    for task in "${!benchmarks[@]}"; do
        run_benchmark "$task" "${benchmarks[$task]}" "$HF_MODEL_NAME" "$TIMEOUT"
    done
else
    # Run a single, specified benchmark.
    if [[ -v "benchmarks[$TASK_TO_RUN]" ]]; then
        run_benchmark "$TASK_TO_RUN" "${benchmarks[$TASK_TO_RUN]}" "$HF_MODEL_NAME" "$TIMEOUT"
    else
        echo "Error: Unknown task '$TASK_TO_RUN'."
        usage
    fi
fi

benchmark_teardown