#!/bin/bash

# === CONFIGURATION ===

HF_MODEL_NAME=$(grep -oP '"HF_MODEL_NAME"\s*:\s*"\K[^"]+' ../config.json)
INSTALL_DIR="/mnt/hdd-baracuda/fberger"
MINICONDA_SCRIPT="Miniconda3-latest-Linux-x86_64.sh"
MINICONDA_PATH="$INSTALL_DIR/miniconda3"
REPO_URL="https://github.com/liu00222/Open-Prompt-Injection.git"
REPO_NAME="Open-Prompt-Injection"
REPO_DIR="$INSTALL_DIR/$REPO_NAME"
CONDA_ENV_NAME="openpromptinjection"
PIP_CACHE_DIR="$INSTALL_DIR/.cache"
HF_CACHE_DIR="$INSTALL_DIR/.huggingface_cache"
SCRIPTS_DIR=$PWD

set -e
trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND"' ERR

# === Setup Directories ===
mkdir -p "$PIP_CACHE_DIR" "$HF_CACHE_DIR"
cd "$INSTALL_DIR"

# === Miniconda Setup ===
if ! command -v conda &> /dev/null; then
    if [[ ! -d "$MINICONDA_PATH" ]]; then
        echo "📦 Installing Miniconda..."
        wget https://repo.anaconda.com/miniconda/$MINICONDA_SCRIPT -O "$MINICONDA_SCRIPT"
        bash "$MINICONDA_SCRIPT" -b -p "$MINICONDA_PATH"
    fi
    export PATH="$MINICONDA_PATH/bin:$PATH"
fi
eval "$($MINICONDA_PATH/bin/conda shell.bash hook)"

# === Clone Repository ===
if [[ ! -d "$REPO_DIR" ]]; then
    echo "📥 Cloning repository..."
    git clone "$REPO_URL" "$REPO_DIR"
fi
cd "$REPO_DIR"
git pull

# === Conda Environment Setup ===
if ! conda info --envs | grep -q "$CONDA_ENV_NAME"; then
    echo "🐍 Creating Conda environment..."
    conda env create -f environment.yml
fi
conda activate "$CONDA_ENV_NAME"

# === Environment Variables ===
export PIP_CACHE_DIR="$PIP_CACHE_DIR"
export DATASETS="$REPO_DIR/CybersecurityBenchmarks/datasets"
export HF_HOME="$HF_CACHE_DIR"

# === GPU Detection (RTX 4000) ===
CUDA_DEVICES=0
# CUDA_DEVICES=$(nvidia-smi --query-gpu=index,name --format=csv,noheader | grep "RTX 4000" | cut -d',' -f1 | tr '\n' ',' | sed 's/,$//')
# if [[ -z "$CUDA_DEVICES" ]]; then
#     echo "⚠️ No RTX 4000 GPUs found. Using default CUDA_VISIBLE_DEVICES=0"
#     export CUDA_VISIBLE_DEVICES=0
# else
#     export CUDA_VISIBLE_DEVICES="$CUDA_DEVICES"
#     echo "🖥️ Using GPUs: $CUDA_VISIBLE_DEVICES"
# fi

cd "$SCRIPTS_DIR"

# === Huggingface Setup ===
HF_TOKEN=$(grep -oP '"HUGGINGFACE_API_KEY"\s*:\s*"\K[^"]+' ../config.json)
if [[ -n "$HF_TOKEN" ]]; then
    huggingface-cli login --token "$HF_TOKEN"
else
    echo "huggingface missing in config.json. Please add your token."
    exit 1
fi

# === Run Script ===
cd "$REPO_DIR"
echo "Run openpromptinjection.py"
python openpromptinjection.py $HF_MODEL_NAME


# === Evaluation ===
RESULTS="$REPO_DIR/evaluation_metrics.json"

cd "$SCRIPTS_DIR"
python openpromptinjection_eval.py $RESULTS $HF_MODEL_NAME