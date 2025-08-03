#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND"' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../ressources/utils.sh"

parse_config

# === CONFIGURATION ===
REPO_URL="https://github.com/BambiMC/MasterKey.git"
REPO_DIR="$INSTALL_DIR/MasterKey"
CONDA_ENV_NAME="masterkey"
PYTHON_VERSION="3.10" #TODO

ensure_miniconda "$INSTALL_DIR"
clone_repo
ensure_conda_env "$CONDA_ENV_NAME" "$PYTHON_VERSION"

# === Install Requirements ===
cd $REPO_DIR
pip install -r requirements.txt | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
pip uninstall -y openai | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
pip install openai | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
pip install datasets | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true



# === Environment Variables ===
export PIP_CACHE_DIR="$PIP_CACHE_DIR"
export HF_HOME="$HF_CACHE_DIR"


hf_login #TODO
openai_login

# === Run Script ===
cd "$REPO_DIR"

python benchmark.py $OPENAI_API_KEY gpt-4o-mini


# === Evaluation ===
# RESULTS="$REPO_DIR/evaluation_metrics.json" #TODO
# cd "$SCRIPTS_DIR"
# python openpromptinjection_eval.py $RESULTS $HF_MODEL_NAME 