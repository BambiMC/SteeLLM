#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND"' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../ressources/utils.sh"

parse_config

# === CONFIGURATION ===
CONDA_ENV_NAME="jailbreakbench"
REPO_URL="https://github.com/JailbreakBench/jailbreakbench.git"
REPO_DIR="$INSTALL_DIR/jailbreakbench"
PYTHON_VERSION="3.11"


# === Setup ===
ensure_miniconda "$INSTALL_DIR"
clone_repo
ensure_conda_env "$CONDA_ENV_NAME" "$PYTHON_VERSION"


# === Install Python Dependencies ===
pip install jailbreakbench[vllm]
pip install -e .

#TODO add  | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
# pip install -r requirements.txt | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
# pip install huggingface_hub deepspeed | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true


hf_login


# === Environment Variables ===
export PIP_CACHE_DIR="$PIP_CACHE_DIR"
export HF_HOME="$HF_CACHE_DIR"
export HF_MODEL_NAME="vicuna-13b-v1.5" #TODO brauche ich das wirklich? NUR TEMPORÄR
export MODEL_NAME="$HF_MODEL_NAME" # TOFIX Bringt das was? / Aber das hier scheine ich wegen dem Fehler zu brauchen, sonst ersetzt er das generic template nicht


# === Run Benchmark ===
# python benchmark.py $HF_MODEL_NAME


# === Evaluation ===
cd $REPO_DIR/logs/dev
# TODO
# cd $SCRIPTS_DIR
# python jailbreakbench_eval.py $SAVE_FILE $HF_MODEL_NAME
