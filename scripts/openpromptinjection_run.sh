#!/usr/bin/env bash
set -eo pipefail
trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND"' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../ressources/utils.sh"

parse_config "$1"

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
pip install --upgrade transformers tokenizers | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
pip install pillow timm mistral-common | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true

pip uninstall -y bitsandbytes
pip install bitsandbytes --prefer-binary
pip install google-generativeai fastchat accelerate peft rouge datasets==2.21.0
pip uninstall -y triton
pip install triton==2.3.1


# === Environment Variables ===

export DATASETS="$REPO_DIR/CybersecurityBenchmarks/datasets"
export TORCH_COMPILE_DISABLE=1
# export CUDA_VISIBLE_DEVICES=0 #TODO Delete this for HPC


hf_login

# === Run Script ===
cd "$REPO_DIR"
echo "Run openpromptinjection.py"

# openpromptinjection.py model_name number_of_rounds
python openpromptinjection.py $HF_MODEL_NAME 10


# === Evaluation ===
RESULTS="$REPO_DIR/evaluation_metrics.json"

cd "$SCRIPTS_DIR"
python openpromptinjection_eval.py $RESULTS $HF_MODEL_NAME 