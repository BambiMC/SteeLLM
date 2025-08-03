#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND"' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../ressources/utils.sh"

parse_config

# === CONFIGURATION ===
REPO_URL="https://github.com/papersPapers/BadPrompt.git"
REPO_DIR="$INSTALL_DIR/BadPrompt"
CONDA_ENV_NAME="badprompt"
PYTHON_VERSION="3.7" #TODO

ensure_miniconda "$INSTALL_DIR"
clone_repo
ensure_conda_env "$CONDA_ENV_NAME" "$PYTHON_VERSION"

# === Install Requirements ===
cd $REPO_DIR

# pip install nltk==3.6.7 simpletransformers==0.63.4 scipy==1.5.4 torch==1.7.1 tqdm==4.60.0 numpy==1.21.0 jsonpickle==2.0.0 scikit_learn==0.24.2 matplotlib==3.3.4 umap-learn==0.5.1 | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
pip install nltk==3.6.7 simpletransformers==0.63.4 scipy==1.5.4 torch==1.7.1 tqdm==4.60.0 jsonpickle==2.0.0 scikit_learn==0.24.2 matplotlib==3.3.4 umap-learn==0.5.1
pip install wandb==0.15.11
# pip uninstall -y huggingface_hub
# pip install huggingface_hub==0.16.4
pip install huggingface_hub
# pip install --upgrade huggingface_hub
# pip install --upgrade --force-reinstall huggingface_hub==0.24.0

# === Environment Variables ===
export PIP_CACHE_DIR="$PIP_CACHE_DIR"
export HF_HOME="$HF_CACHE_DIR"


hf_login

# === Run Script ===
cd "$REPO_DIR"
python trigger_generation/first_selection.py
python selection.py 
# python openpromptinjection.py $HF_MODEL_NAME


# === Evaluation ===
# RESULTS="$REPO_DIR/evaluation_metrics.json" #TODO
# cd "$SCRIPTS_DIR"
# python openpromptinjection_eval.py $RESULTS $HF_MODEL_NAME 