#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND"' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../ressources/utils.sh"

parse_config

# === CONFIGURATION ===
CONDA_ENV_NAME="jailbreakbench"
REPO_URL="https://github.com/BambiMC/jailbreakbench.git"
REPO_DIR="$INSTALL_DIR/jailbreakbench"
PYTHON_VERSION="3.11"


# === Setup ===
ensure_miniconda "$INSTALL_DIR"
clone_repo
ensure_conda_env "$CONDA_ENV_NAME" "$PYTHON_VERSION"


# === Install Python Dependencies ===
cd "$REPO_DIR"
pip install jailbreakbench[vllm] | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
pip install -e . | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
# TODO Is this next line needed?
# pip install transformers accelerate | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true


hf_login


# === Environment Variables ===
export PIP_CACHE_DIR="$PIP_CACHE_DIR"
export HF_HOME="$HF_CACHE_DIR"
export MODEL_NAME="$HF_MODEL_NAME" # TOFIX Bringt das was? / Aber das hier scheine ich wegen dem Fehler zu brauchen, sonst ersetzt er das generic template nicht
export HF_MODEL_NAME="vicuna-13b-v1.5" #TODO brauche ich das wirklich? NUR TEMPORÄR
IFS='/' read -ra HF_MODEL_NAME_SPLIT <<< "$HF_MODEL_NAME"

# === Run Benchmark ===
cd "$REPO_DIR"
python benchmark.py $HF_MODEL_NAME


# === Evaluation ===
cd $SCRIPTS_DIR
python jailbreakbench_eval.py $REPO_DIR/benchmark_results.txt $HF_MODEL_NAME
