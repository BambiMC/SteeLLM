#!/usr/bin/env bash
set -eo pipefail
trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND"' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../ressources/utils.sh"

parse_config "$1"

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
# TODO DECOMMENT WHEN NEW ENV; ONLY TEMP COMMENT
# pip install jailbreakbench[vllm] | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
# pip install -e . | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true


##### TODO Is this next line needed?
##### pip install --upgrade transformers tokenizers | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true

# TODO DECOMMENT WHEN NEW ENV; ONLY TEMP COMMENT
# pip install --upgrade torch

pip install bitsandbytes kernels google-genai anthropic  | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true

hf_login
openai_login
deepseek_login
google_gemini_login
anthropic_login


# === Environment Variables ===
# export CUDA_VISIBLE_DEVICES=0 #TODO Delete this for HPC


export MODEL_NAME="$HF_MODEL_NAME" # Needed!


# With Fallback if cloud model is used
IFS='/' read -ra HF_MODEL_NAME_SPLIT <<< "$MODEL_NAME"
HF_MODEL_NAME_SPLITTED=${HF_MODEL_NAME_SPLIT[1]:-$MODEL_NAME}

echo "Using HF_MODEL_NAME_SPLITTED: $HF_MODEL_NAME_SPLITTED"

# === Run Benchmark ===
cd "$REPO_DIR"
python benchmark.py $HF_MODEL_NAME


# === Evaluation ===
cd $SCRIPTS_DIR
python jailbreakbench_eval.py $REPO_DIR $HF_MODEL_NAME_SPLITTED
