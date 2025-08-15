#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND"' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../ressources/utils.sh"

parse_config "$1"

# === CONFIGURATION ===
CONDA_ENV_NAME="llm-attacks"
REPO_URL="https://github.com/BambiMC/llm-attacks-hf.git"
REPO_DIR="$INSTALL_DIR/llm-attacks-hf"
PYTHON_VERSION="3.10"


# === ENV VARIABLES ===
export CUDA_VISIBLE_DEVICES=0  
export CUDA_DEVICE_ORDER=PCI_BUS_ID




ensure_miniconda "$INSTALL_DIR"
ensure_conda_env "$CONDA_ENV_NAME" "$PYTHON_VERSION"
clone_repo

# === Install Dependencies ===
pip install -r requirements.txt | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
pip install fschat==0.2.23 | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
pip install -e . | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true


hf_login


# === Start benchmark ===

cd $REPO_DIR/experiments/launch_scripts
bash run_gcg_individual.sh llama2 behaviors
#TODO

# === Evaluation ===
# RESULTS="$REPO_DIR/" 
# TODO
# cd "$SCRIPTS_DIR"
# python llm-attacks_eval.py $RESULTS $HF_MODEL_NAME 