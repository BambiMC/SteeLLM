#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND"' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../ressources/utils.sh"

parse_config "$1"

# === CONFIGURATION ===
REPO_URL="https://github.com/BambiMC/JailbreakScan.git"
REPO_DIR="$INSTALL_DIR/JailbreakScan"
CONDA_ENV_NAME="jailbreakscan"
PYTHON_VERSION="3.10"

ensure_miniconda "$INSTALL_DIR"
clone_repo
ensure_conda_env "$CONDA_ENV_NAME" "$PYTHON_VERSION"


# === Install Requirements ===
mkdir -p "$REPO_DIR"
cd $REPO_DIR

pip install --upgrade transformers datasets openai accelerate bitsandbytes | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
pip install pillow timm mistral-common triton kernels | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
# pip install --upgrade kernels torch==2.6.0 | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
# === Environment Variables ===
# export CUDA_VISIBLE_DEVICES=0 #TODO REMOVE THESE EVERYWHERE BEFORE RUNNING ON HPC


hf_login

# === Run Script ===
cd "$REPO_DIR"

#TODO make batch size is configurable
# python JailbreakScan.py --model_name ${HF_MODEL_NAME} --multi_gpu --batch_size 8
python JailbreakScan2.py --model_name ${HF_MODEL_NAME} --multi_gpu --batch_size 8
# python JailbreakScan2.py --model_name ${HF_MODEL_NAME} --multi_gpu --batch_size 8


# === Evaluation ===
RESULTS="$REPO_DIR/jailbreak_scan_results.txt"
cd "$SCRIPTS_DIR"
# python jailbreakscan_eval.py $RESULTS $HF_MODEL_NAME