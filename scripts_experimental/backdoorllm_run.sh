#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND"' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../ressources/utils.sh"

parse_config "$1"

# === CONFIGURATION ===
IFS='/' read -ra HF_MODEL_NAME_SPLIT <<< "$HF_MODEL_NAME"
CONDA_ENV_NAME="backdoorllm"
REPO_URL="https://github.com/BambiMC/BackdoorLLM.git"
REPO_DIR="$INSTALL_DIR/BackdoorLLM"
XDG_CACHE_HOME="$INSTALL_DIR/.xdg_cache"
DEEPSPEED_CACHE_DIR="$INSTALL_DIR/.deepspeed_cache"
TRAIN_CONFIG="configs/jailbreak/${HF_MODEL_NAME_SPLIT[0]}/${HF_MODEL_NAME_SPLIT[1]}/${HF_MODEL_NAME_SPLIT[1]}_jailbreak_badnet_lora.yaml"
PYTHON_VERSION="3.10"




# === Setup Directories ===
mkdir -p "$PIP_CACHE_DIR" "$HF_CACHE_DIR" "$XDG_CACHE_HOME" "$DEEPSPEED_CACHE_DIR"
cd "$INSTALL_DIR" # TODO brauche ich das wirklich?

ensure_miniconda "$INSTALL_DIR"
clone_repo
ensure_conda_env "$CONDA_ENV_NAME" "$PYTHON_VERSION"


# === Install Python Dependencies ===
pip uninstall -y transformers tokenizers
pip install -r requirements.txt | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
pip install huggingface_hub deepspeed | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true

hf_login
openai_login
deepseek_login
google_gemini_login
anthropic_login


# === Environment Variables ===


export XDG_CACHE_HOME="$XDG_CACHE_HOME"
export DEEPSPEED_CACHE_DIR="$DEEPSPEED_CACHE_DIR"
export NCCL_P2P_DISABLE=1
export NCCL_IB_DISABLE=1
export HF_MODEL_NAME="$HF_MODEL_NAME" #TODO brauche ich das wirklich?
export MODEL_NAME="$HF_MODEL_NAME" # TOFIX Bringt das was? / Aber das hier scheine ich wegen dem Fehler zu brauchen, sonst ersetzt er das generic template nicht
export DATASETS="$REPO_DIR/CybersecurityBenchmarks/datasets"
#TODO kann ich mit denen von oben kombinieren?

# === Training ===
cd "$REPO_DIR/attack/DPA" #TODO auch noch die anderen, nicht nur DPA machen
torchrun --nproc_per_node=1 --master_port=11222 backdoor_train.py configs/jailbreak/generic/generic_jailbreak_badnet_lora.yaml

# === Test ===
python backdoor_evaluate.py $HF_MODEL_NAME


# === Evaluation ===
SAVE_FILE="$REPO_DIR/attack/DPA/eval_result/jailbreak/badnet/eval_${HF_MODEL_NAME}/eval_${HF_MODEL_NAME}_jailbreak_badnet.json" #TODO es gibt auch noch die mit none, aber am relevantesten dürfte wohl die mit badnet sein, weil höhere ASR

# DIR="$REPO_DIR/attack/DPA/eval_result/jailbreak/badnet/eval_${HF_MODEL_NAME}"
# FILE_PATTERN="eval_ASR_*_${HF_MODEL_NAME}_jailbreak_badnet.json"

# # Find the newest file matching the pattern
# SAVE_FILE=$(find "$DIR" -type f -name "$FILE_PATTERN" -printf "%T@ %p\n" | sort -nr | head -n 1 | cut -d' ' -f2-)

echo "Found save file: $SAVE_FILE" #TODO temp

# === Evaluate results ===
cd $SCRIPTS_DIR
python backdoorllm_eval.py $SAVE_FILE $HF_MODEL_NAME

#TODO Backdoorllm kriegt es hin, auf allen drei GPUs zu laufen!