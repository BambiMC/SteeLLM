#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND"' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../ressources/utils.sh"

parse_config

# === CONFIGURATION ===
REPO_URL="https://github.com/BambiMC/Open-Prompt-Injection.git"
REPO_DIR="$INSTALL_DIR/Open-Prompt-Injection"
CONDA_ENV_NAME="openpromptinjection"
PYTHON_VERSION="3.10"


ensure_miniconda "$INSTALL_DIR"
clone_repo
ensure_conda_env "$CONDA_ENV_NAME" "$PYTHON_VERSION"

# === Install Requirements ===
cd $REPO_DIR
conda env update -f environment.yml --name $CONDA_ENV_NAME | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
pip install --upgrade transformers tokenizers

# === Environment Variables ===
export PIP_CACHE_DIR="$PIP_CACHE_DIR"
export DATASETS="$REPO_DIR/CybersecurityBenchmarks/datasets"
export HF_HOME="$HF_CACHE_DIR"


hf_login

# === Run Script ===
cd "$REPO_DIR"
echo "Run openpromptinjection.py"

export TORCH_COMPILE_DISABLE=1
python openpromptinjection.py $HF_MODEL_NAME


# === Evaluation ===
RESULTS="$REPO_DIR/evaluation_metrics.json"

cd "$SCRIPTS_DIR"
python openpromptinjection_eval.py $RESULTS $HF_MODEL_NAME 