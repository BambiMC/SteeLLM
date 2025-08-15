#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND"' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../ressources/utils.sh"

parse_config

# === CONFIGURATION ===
REPO_URL="https://github.com/HKUST-KnowComp/LLM-Multistep-Jailbreak.git"
REPO_DIR="$INSTALL_DIR/LLM-Multistep-Jailbreak"
CONDA_ENV_NAME="llm-multistep-jailbreak"
PYTHON_VERSION="3.10"

ensure_miniconda "$INSTALL_DIR"
clone_repo
ensure_conda_env "$CONDA_ENV_NAME" "$PYTHON_VERSION"

# === Install Requirements ===
cd $REPO_DIR
pip install pandas torch transformers tqdm | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
# pip uninstall -y openai 
pip install openai==0.28.1 | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true

# === Environment Variables ===
export PIP_CACHE_DIR="$PIP_CACHE_DIR"
export HF_HOME="$HF_CACHE_DIR"


hf_login

# === Run Script ===
cd "$REPO_DIR"

mkdir -p "results_llama2" #TODO programmatically do it

python llm_extraction.py #$HF_MODEL_NAME #TODO


# === Evaluation ===
# RESULTS="$REPO_DIR/evaluation_metrics.json" #TODO
# cd "$SCRIPTS_DIR"
# python openpromptinjection_eval.py $RESULTS $HF_MODEL_NAME 