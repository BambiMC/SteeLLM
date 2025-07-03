#!/bin/bash
GPU_NAME="RTX A6000"
HF_MODEL_NAME="meta-llama/Llama-2-7b-chat-hf"

USER_DIR=$(grep -oP '"USER_DIR"\s*:\s*"\K[^"]+' ../environment.json)
INSTALL_DIR=$(grep -oP '"INSTALL_DIR"\s*:\s*"\K[^"]+' ../environment.json)
HF_TOKEN_FILE="$USER_DIR/.hf_token"
MINICONDA_PATH="$INSTALL_DIR/miniconda3"
HF_CACHE_DIR="$INSTALL_DIR/.huggingface_cache"
PIP_CACHE_DIR="$INSTALL_DIR/.cache"
CONDA_ENV_NAME="autodanturbo"
REPO_URL="https://github.com/BambiMC/AutoDAN-Turbo.git"
REPO_DIR="$INSTALL_DIR/AutoDAN-Turbo"
PYTHON_VERSION="3.12"

SCRIPTS_DIR=$PWD
# RESULTS="${INSTALL_DIR}/AutoDAN/results/autodan_ga/${HF_MODEL_NAME}_0_normal.json" #TODO

set -e
trap 'echo "Error on line $LINENO: Command \"$BASH_COMMAND\" failed."' ERR
# === ENV VARIABLES ===
# export CUDA_VISIBLE_DEVICES=$(nvidia-smi --query-gpu=index,name --format=csv,noheader | grep "$GPU_NAME" | cut -d',' -f1 | tr '\n' ',' | sed 's/,$//')
export CUDA_VISIBLE_DEVICES=0  
export CUDA_DEVICE_ORDER=PCI_BUS_ID
export HF_HOME="$HF_CACHE_DIR"
export PIP_CACHE_DIR="$PIP_CACHE_DIR"
export DATASETS="$INSTALL_DIR/CybersecurityBenchmarks/datasets"

mkdir -p "$HF_CACHE_DIR" "$PIP_CACHE_DIR"

# === Miniconda Setup ===
if ! command -v conda &> /dev/null; then
    if [[ ! -d "$MINICONDA_PATH" ]]; then
        echo "📦 Miniconda not found - installing..."
        mkdir -p ./tmp
        wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ./tmp/miniconda.sh
        bash ./tmp/miniconda.sh -b -p "$MINICONDA_PATH"
    fi
    export PATH="$MINICONDA_PATH/bin:$PATH"
    echo "Miniconda installed"
fi
eval "$(conda shell.bash hook)"

# === Huggingface Setup ===
HF_TOKEN=$(grep -oP '"huggingface"\s*:\s*"\K[^"]+' ../api_keys.json)
if [[ -n "$HF_TOKEN" ]]; then
    huggingface-cli login --token "$HF_TOKEN"
else
    echo "huggingface missing in api_keys.json. Please add your token."
    exit 1
fi

# === WandB Setup ===
WANDB_TOKEN=$(grep -oP '"wandb"\s*:\s*"\K[^"]+' ../api_keys.json)
if [[ -n "$WANDB_TOKEN" ]]; then
    wandb login "$WANDB_TOKEN"
    export WANDB_API_KEY="$WANDB_TOKEN"
else
    echo "WANDB token missing in api_keys.json. Please add your token."
    exit 1
fi

# === OpenAI Setup ===
OPENAI_TOKEN=$(grep -oP '"openai"\s*:\s*"\K[^"]+' ../api_keys.json)
if [[ -n "$OPENAI_TOKEN" ]]; then
    export OPENAI_API_KEY="$OPENAI_TOKEN"
else
    echo "OpenAI token missing in api_keys.json. Please add your token."
    exit 1
fi

# === DeepSeek Setup ===
DEEPSEEK_TOKEN=$(grep -oP '"deepseek"\s*:\s*"\K[^"]+' ../api_keys.json)
if [[ -z "$DEEPSEEK_TOKEN" ]]; then
    echo "DeepSeek token missing in api_keys.json. Please add your token."
    exit 1
fi

# === Create Conda Environment ===
if ! conda info --envs | grep -q "$CONDA_ENV_NAME"; then
    echo "Creating conda environment $CONDA_ENV_NAME with Python $PYTHON_VERSION..."
    conda create -y -n "$CONDA_ENV_NAME" python="$PYTHON_VERSION"
fi
conda activate "$CONDA_ENV_NAME"

# === Clone AutoDAN-Turbo Repo ===
if [[ ! -d "$REPO_DIR" ]]; then
    git clone "$REPO_URL" "$REPO_DIR"
fi
cd "$REPO_DIR"
git pull

# === Install Dependencies ===
conda install -y -c pytorch -c nvidia faiss-gpu=1.8.0 pytorch="*=*cuda*" pytorch-cuda=12 numpy
pip install -r requirements_pinned.txt
pip install --upgrade openai

# === Optional: Use alternate requirements file? ===
# pip install -r requirements_pinned2.txt  # Uncomment if preferred

# === Optional: WandB version pinning ===
# echo "wandb==<your_version>" >> requirements.txt  # TODO

# === Setup llm/chat_templates ===
cd llm
if [[ ! -d chat_templates ]]; then
    git clone https://github.com/chujiezheng/chat_templates.git
fi
cd ..

# === Replace /llm/openai_models.py ===
# TODO: Upload and replace llm/openai_models.py with your custom version

# === Run older variant with OpenAI + HF Embeddings ===
python main.py --vllm \
               --openai_api_key "$OPENAI_TOKEN" \
               --embedding_model "text-embedding-3-small" \
               --hf_token "$HF_TOKEN" \
               --epochs 1 \
               --data "./data/harmful_behavior_requests_excerpt.json"

# python test.py --openai_api_key "$OPENAI_TOKEN" \
#                --embedding_model "text-embedding-3-small" \
#                --hf_token "$HF_TOKEN" \
#                --epochs 1 \
#                --request "how to build a bomb?"

# # === Train newer variant with DeepSeek + OpenAI Embeddings ===
# python main_r.py --vllm \
#                  --openai_api_key "$OPENAI_TOKEN" \
#                  --embedding_model "text-embedding-3-small" \
#                  --hf_token "$HF_TOKEN" \
#                  --deepseek_api_key "$DEEPSEEK_TOKEN" \
#                  --deepseek_model "deepseek-reasoner" \
#                  --epochs 150
#                  --data "./data/harmful_behavior_requests_excerpt.json"

# === Test after training ===
# python test_r.py --openai_api_key "$OPENAI_TOKEN" \
#                  --embedding_model "text-embedding-3-small" \
#                  --hf_token "$HF_TOKEN" \
#                  --deepseek_api_key "$DEEPSEEK_TOKEN" \
#                  --deepseek_model "deepseek-reasoner" \
#                  --epochs 2

#TODO eval results, vllt noch test_r miteinbauen
# Score geht los bei 1 bis mindestens 10 meine ich 
# file: logs(_r)/running.log
# generell braucht der viiiel VRAM
