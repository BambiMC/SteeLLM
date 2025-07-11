#!/bin/bash

# === CONFIGURATION ===
HF_MODEL_NAME=$(grep -oP '"HF_MODEL_NAME"\s*:\s*"\K[^"]+' ../config.json)
IFS='/' read -ra HF_MODEL_NAME_SPLIT <<< "$HF_MODEL_NAME"
INSTALL_DIR=$(grep -oP '"INSTALL_DIR"\s*:\s*"\K[^"]+' ../config.json)
SCRIPTS_DIR=$PWD
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
TRAIN_CONFIG="configs/jailbreak/${HF_MODEL_NAME_SPLIT[0]}/${HF_MODEL_NAME_SPLIT[1]}/${HF_MODEL_NAME_SPLIT[1]}_jailbreak_badnet_lora.yaml"



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

cd "$SCRIPTS_DIR"

# === Huggingface Setup ===
HF_TOKEN=$(grep -oP '"HUGGINGFACE_API_KEY"\s*:\s*"\K[^"]+' ../config.json)
if [[ -n "$HF_TOKEN" ]]; then
    huggingface-cli login --token "$HF_TOKEN"
else
    echo "huggingface missing in config.json. Please add your token."
    exit 1
fi


# === Environment Variables ===
export PIP_CACHE_DIR="$PIP_CACHE_DIR"
export HF_HOME="$HF_CACHE_DIR"
export XDG_CACHE_HOME="$XDG_CACHE_HOME"
export DEEPSPEED_CACHE_DIR="$DEEPSPEED_CACHE_DIR"
export NCCL_P2P_DISABLE=1
export NCCL_IB_DISABLE=1
export HF_MODEL_NAME="$HF_MODEL_NAME" #TODO brauche ich das wirklich?
export DATASETS="$REPO_DIR/CybersecurityBenchmarks/datasets"

# === Training ===
cd "$REPO_DIR/attack/DPA" #TODO auch noch die anderen, nicht nur DPA machen
# torchrun --nproc_per_node=1 --master_port=11222 backdoor_train.py "$TRAIN_CONFIG" #TODO

# === Test ===
python backdoor_evaluate.py $HF_MODEL_NAME

AVG_UTILITY=$(python -m agentdojo.scripts.benchmark -s workspace \
    --model "$HF_MODEL_NAME_ENUM" | grep "Average utility" | awk -F ':' '{print $2}' | xargs)

# === Evaluation ===
SAVE_FILE="$REPO_DIR/attack/DPA/eval_result/jailbreak/badnet/eval_${HF_MODEL_NAME}/eval_${HF_MODEL_NAME}_jailbreak_badnet.json" #TODO es gibt auch noch die mit none, aber am relevantesten dürfte wohl die mit badnet sein, weil höhere ASR

# DIR="$REPO_DIR/attack/DPA/eval_result/jailbreak/badnet/eval_${HF_MODEL_NAME}"
# FILE_PATTERN="eval_ASR_*_${HF_MODEL_NAME}_jailbreak_badnet.json"

# # Find the newest file matching the pattern
# SAVE_FILE=$(find "$DIR" -type f -name "$FILE_PATTERN" -printf "%T@ %p\n" | sort -nr | head -n 1 | cut -d' ' -f2-)

echo "Found save file: $SAVE_FILE" #TODO temp

cd "$SCRIPTS_DIR"

python backdoorllm_eval.py $SAVE_FILE $HF_MODEL_NAME $1

#TODO Backdoorllm kriegt es hin, auf allen drei GPUs zu laufen!