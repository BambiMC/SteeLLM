#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND"' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../ressources/utils.sh"

parse_config

# === CONFIGURATION ===
# HF_MODEL_NAME=$(grep -oP '"HF_MODEL_NAME"\s*:\s*"\K[^"]+' ../config.json)
# SCRIPTS_DIR=$PWD
# USER_DIR=$(grep -oP '"USER_DIR"\s*:\s*"\K[^"]+' ../config.json)
# INSTALL_DIR=$(grep -oP '"INSTALL_DIR"\s*:\s*"\K[^"]+' ../config.json)
# HF_TOKEN_FILE="$USER_DIR/.hf_token"
# MINICONDA_PATH="$INSTALL_DIR/miniconda3"
# HF_CACHE_DIR="$INSTALL_DIR/.huggingface_cache"
# PIP_CACHE_DIR="$INSTALL_DIR/.cache"
CONDA_ENV_NAME="persuasive-jailbreaker"
REPO_URL="https://github.com/BambiMC/persuasive_jailbreaker-hf.git"
REPO_DIR="$INSTALL_DIR/persuasive_jailbreaker"
PYTHON_VERSION="3.10"


# === ENV VARIABLES ===
# export CUDA_VISIBLE_DEVICES=$(nvidia-smi --query-gpu=index,name --format=csv,noheader | grep "$GPU_NAME" | cut -d',' -f1 | tr '\n' ',' | sed 's/,$//')
export CUDA_VISIBLE_DEVICES=0  
export CUDA_DEVICE_ORDER=PCI_BUS_ID
export HF_HOME="$HF_CACHE_DIR"
export PIP_CACHE_DIR="$PIP_CACHE_DIR"
# export DATASETS="$INSTALL_DIR/CybersecurityBenchmarks/datasets"


ensure_miniconda "$INSTALL_DIR"
ensure_conda_env "$CONDA_ENV_NAME" "$PYTHON_VERSION"
clone_repo


# === Install Dependencies ===
pip install -r requirements.txt > /dev/null

hf_login
wandb_login
openai_login
deepseek_login




# === Start benchmark ===
cd "$REPO_DIR"
#TODO
python benchmark.py $OPENAI_API_KEY

/test.ipynb

# === Evaluation ===
# RESULTS="$REPO_DIR/evaluation_metrics.json"
#TODO
# cd $SCRIPTS_DIR
# python tap-persuasive-jailbreaker_eval.py $RESULTS $HF_MODEL_NAME 