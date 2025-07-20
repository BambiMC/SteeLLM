#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND"' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../ressources/utils.sh"

parse_config

# === CONFIGURATION ===
CONDA_ENV_NAME="harmbench"
REPO_URL="https://github.com/centerforaisafety/HarmBench.git"
REPO_DIR="$INSTALL_DIR/HarmBench"
PYTHON_VERSION="3.9"


# === Setup ===
ensure_miniconda "$INSTALL_DIR"
clone_repo
ensure_conda_env "$CONDA_ENV_NAME" "$PYTHON_VERSION"


# === Install Python Dependencies ===
pip install -r requirements_pinned.txt
python -m spacy download en_core_web_sm

#TODO add  | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true


hf_login


# === Environment Variables ===
export PIP_CACHE_DIR="$PIP_CACHE_DIR"
export HF_HOME="$HF_CACHE_DIR"
export HF_MODEL_NAME="llama2_7b" #TODO brauche ich das wirklich? NUR TEMPORÄR
export MODEL_NAME="$HF_MODEL_NAME" # TOFIX Bringt das was? / Aber das hier scheine ich wegen dem Fehler zu brauchen, sonst ersetzt er das generic template nicht


# === Run Benchmark ===
python ./scripts/run_pipeline.py --methods AutoDAN --models $HF_MODEL_NAME --step all --mode local


# === Evaluation ===
# cd $SCRIPTS_DIR
# TODO
# python jailbreakbench_eval.py $SAVE_FILE $HF_MODEL_NAME
