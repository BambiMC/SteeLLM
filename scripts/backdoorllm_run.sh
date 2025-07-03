#!/bin/bash

# === CONFIGURATION ===
MODEL_NAME="meta-llama/Llama-2-7b-chat-hf"
INSTALL_DIR="/mnt/hdd-baracuda/fberger"
MINICONDA_SCRIPT="Miniconda3-latest-Linux-x86_64.sh"
MINICONDA_PATH="$INSTALL_DIR/miniconda3"
CONDA_ENV_NAME="backdoorllm"
REPO_URL="https://github.com/BambiMC/BackdoorLLM.git"
REPO_NAME="BackdoorLLM"
REPO_DIR="$INSTALL_DIR/$REPO_NAME"

PIP_CACHE_DIR="$INSTALL_DIR/.cache"
HF_CACHE_DIR="$INSTALL_DIR/.huggingface_cache"
XDG_CACHE_HOME="$INSTALL_DIR/.xdg_cache"
DEEPSPEED_CACHE_DIR="$INSTALL_DIR/.deepspeed_cache"

TRAIN_CONFIG="configs/jailbreak/meta-llama/Llama-2-7b-chat-hf/Llama-2-7b-chat-hf_jailbreak_badnet_lora.yaml"

set -e
trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND"' ERR

# === Setup Directories ===
mkdir -p "$PIP_CACHE_DIR" "$HF_CACHE_DIR" "$XDG_CACHE_HOME" "$DEEPSPEED_CACHE_DIR"
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

# === Clone Repo ===
if [[ ! -d "$REPO_DIR" ]]; then
    git clone "$REPO_URL" "$REPO_DIR"
fi
cd "$REPO_DIR"
git pull

# === Create Conda Environment ===
if ! conda info --envs | grep -q "$CONDA_ENV_NAME"; then
    conda create -y -n "$CONDA_ENV_NAME" python=3.10
fi
conda activate "$CONDA_ENV_NAME"

# === Install Python Dependencies ===
pip install -r requirements.txt
pip install huggingface_hub deepspeed

# === HuggingFace Login ===
HF_TOKEN=$(grep -oP '"huggingface"\s*:\s*"\K[^"]+' ../api_keys.json)
if [[ -n "$HF_TOKEN" ]]; then
    huggingface-cli login --token "$HF_TOKEN"
else
    echo "❌ HuggingFace token missing in api_keys.json"
    exit 1
fi

# === Environment Variables ===
export PIP_CACHE_DIR="$PIP_CACHE_DIR"
export HF_HOME="$HF_CACHE_DIR"
export XDG_CACHE_HOME="$XDG_CACHE_HOME"
export DEEPSPEED_CACHE_DIR="$DEEPSPEED_CACHE_DIR"
export NCCL_P2P_DISABLE=1
export NCCL_IB_DISABLE=1
export MODEL_NAME="$MODEL_NAME"
export DATASETS="$REPO_DIR/CybersecurityBenchmarks/datasets"

# === Training ===
cd "$REPO_DIR/attack/DPA"
torchrun --nproc_per_node=1 --master_port=11222 backdoor_train.py "$TRAIN_CONFIG"

# === Evaluation ===
python backdoor_evaluate.py $MODEL_NAME

echo "✅ Training and evaluation complete for model: $MODEL_NAME"