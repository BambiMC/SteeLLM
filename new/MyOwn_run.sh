#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND"' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../ressources/utils.sh"

parse_config

# === CONFIGURATION ===
# REPO_URL="https://github.com/confident-ai/deepeval.git"
REPO_DIR="$INSTALL_DIR/MyOwn"
CONDA_ENV_NAME="myown"
PYTHON_VERSION="3.10" #TODO

ensure_miniconda "$INSTALL_DIR"
# clone_repo
ensure_conda_env "$CONDA_ENV_NAME" "$PYTHON_VERSION"

# === Install Requirements ===
mkdir -p "$REPO_DIR"
cd $REPO_DIR

pip install transformers datasets openai accelerate bitsandbytes | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true



# === Environment Variables ===
export PIP_CACHE_DIR="$PIP_CACHE_DIR"
export HF_HOME="$HF_CACHE_DIR"
export CUDA_VISIBLE_DEVICES=0


hf_login

# deepeval login --api-key YOUR_API_KEY

# === Run Script ===
cd "$REPO_DIR"

#TODO gerade manuell hochgeladen, Github machen und dann die MyOwn.py commiten
python MyOwn.py \
  --model_name meta-llama/Llama-2-7b-chat-hf \
  --judge_model facebook/bart-large-mnli \
  --max_examples 10
# python openpromptinjection.py $HF_MODEL_NAME



# === Evaluation ===
# RESULTS="$REPO_DIR/evaluation_metrics.json" #TODO
# cd "$SCRIPTS_DIR"
# python openpromptinjection_eval.py $RESULTS $HF_MODEL_NAME 