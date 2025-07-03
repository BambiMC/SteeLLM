#!/bin/bash
GPU_NAME="RTX A6000"
HF_MODEL_NAME="meta-llama/Llama-2-7b-chat-hf"

USER_DIR=$(grep -oP '"USER_DIR"\s*:\s*"\K[^"]+' ../environment.json)
INSTALL_DIR=$(grep -oP '"INSTALL_DIR"\s*:\s*"\K[^"]+' ../environment.json)
HF_TOKEN_FILE="$USER_DIR/.hf_token"
MINICONDA_PATH="$INSTALL_DIR/miniconda3"
HF_CACHE_DIR="$INSTALL_DIR/.huggingface_cache"
PIP_CACHE_DIR="$INSTALL_DIR/.cache"
CONDA_ENV_NAME="AutoDAN"
REPO_URL="https://github.com/BambiMC/AutoDAN.git"
REPO_DIR="$INSTALL_DIR/AutoDAN"
PYTHON_VERSION="3.10"



SCRIPTS_DIR=$PWD
RESULTS="${INSTALL_DIR}/AutoDAN/results/autodan_ga/${HF_MODEL_NAME}_0_normal.json"


set -e  # Stop if any command fails
trap 'echo "Error on line $LINENO: Command \"$BASH_COMMAND\" failed."' ERR

# === ENV VARIABLES ===
#export CUDA_DEVICE_ORDER=$(nvidia-smi --query-gpu=pci.bus_id,name --format=csv,noheader | grep "$GPU_NAME" | cut -d',' -f1)
export CUDA_VISIBLE_DEVICES=$(nvidia-smi --query-gpu=index,name --format=csv,noheader | grep "RTX A6000" | cut -d',' -f1 | tr '\n' ',' | sed 's/,$//')
export HF_HOME="$HF_CACHE_DIR"
export PIP_CACHE_DIR="$PIP_CACHE_DIR"

mkdir -p "$HF_CACHE_DIR" "$PIP_CACHE_DIR"

# === Miniconda Setup ===
if ! command -v conda &> /dev/null; then
    if [[ ! -d "$MINICONDA_PATH" ]]; then
        echo "📦 Miniconda not found - installing..."
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

# === Create Conda Environment ===
if ! conda info --envs | grep -q "$CONDA_ENV_NAME"; then
    echo "Create Conda environment $CONDA_ENV_NAME with Python $PYTHON_VERSION..."
    conda create -y -n "$CONDA_ENV_NAME" python="$PYTHON_VERSION"
fi
conda activate "$CONDA_ENV_NAME"

# === clone repository ===
if [[ ! -d "$REPO_DIR" ]]; then
    git clone "$REPO_URL" "$REPO_DIR"
else
    echo "Repository already cloned. -> Updating..."
    git pull
fi

# === Install requirements ===
cd "$REPO_DIR"

if grep -q "numpy==1.26.0" requirements.txt; then
    sed -i 's/numpy==1.26.0/numpy>=1.26.0/' requirements.txt
fi
pip install --upgrade pip
# pip install -r requirements.txt 2>&1 | grep -v "Requirement already satisfied"
# pip install -r requirements.txt
pip install -r requirements.txt > pip_output.log 2>&1
# grep -vF "Requirement already satisfied" output.log

echo "All requirements installed for $CONDA_ENV_NAME environment."

# === Start benchmark ===
cd models
python download_models.py $HF_MODEL_NAME
cd ..
python autodan_ga_eval.py --model $HF_MODEL_NAME --num_steps 20 --dataset_path ./data/advbench/harmful_behaviors_excerpt.csv

# === Evaluate results ===
python ${SCRIPTS_DIR}/autodan_eval.py ${RESULTS} ${HF_MODEL_NAME}