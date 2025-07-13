#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND"' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/agentdojo_utils.sh"

# --- Configuration you might override per‑script ------------
CONFIG_JSON="$SCRIPT_DIR/config.json"
GPU_NAME="RTX A6000"
CONDA_ENV="agentdojo"
PY_VER="3.10"
REPO_URL="https://github.com/BambiMC/agentdojo-hf.git"
INSTALL_DIR=$(jq -r '.INSTALL_DIR' "$CONFIG_JSON")   # need it early
REPO_DIR="$INSTALL_DIR/agentdojo-hf"

# --- 1. Stage environment -----------------------------------
parse_config "$CONFIG_JSON"
export CUDA_VISIBLE_DEVICES=$(nvidia-smi --query-gpu=index,name --format=csv,noheader \
                         | grep "$GPU_NAME" | cut -d',' -f1 | tr '\n' ',' | sed 's/,$//')
export HF_HOME="$INSTALL_DIR/.huggingface_cache"
export PIP_CACHE_DIR="$INSTALL_DIR/.cache"
mkdir -p "$HF_HOME" "$PIP_CACHE_DIR"

ensure_miniconda "$INSTALL_DIR"
hf_login
openai_login
ensure_conda_env "$CONDA_ENV" "$PY_VER"

# --- 2. Build & run benchmark -------------------------------
clone_and_build "$REPO_URL" "$REPO_DIR"

MODEL_ENUM=$(model_to_enum "$HF_MODEL_NAME")
echo "👉 Using model enum $MODEL_ENUM"

AVG_UTILITY=$(run_benchmark "$REPO_DIR" "$MODEL_ENUM")
echo "✅ Average utility = $AVG_UTILITY"

python "$SCRIPT_DIR/agentdojo_eval.py" "$AVG_UTILITY" "$HF_MODEL_NAME"