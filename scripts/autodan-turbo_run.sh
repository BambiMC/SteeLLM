#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND"' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../ressources/utils.sh"

parse_config "$1"

# === CONFIGURATION ===
CONDA_ENV_NAME="autodanturbo"
REPO_URL="https://github.com/BambiMC/AutoDAN-Turbo.git"
REPO_DIR="$INSTALL_DIR/AutoDAN-Turbo"
PYTHON_VERSION="3.10"

# === ENV VARIABLES ===
export CUDA_VISIBLE_DEVICES=0  
export CUDA_DEVICE_ORDER=PCI_BUS_ID


export DATASETS="$INSTALL_DIR/CybersecurityBenchmarks/datasets"

mkdir -p "$HF_CACHE_DIR" "$PIP_CACHE_DIR"

# === Miniconda Setup ===
ensure_miniconda "$INSTALL_DIR"

# === Create Conda Environment ===
ensure_conda_env "$CONDA_ENV_NAME" "$PYTHON_VERSION"

# === Clone AutoDAN-Turbo Repo ===
clone_repo

# === Install Dependencies ===
# conda install -y -c pytorch -c nvidia faiss-gpu=1.8.0 pytorch="*=*cuda*" pytorch-cuda=12 numpy
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
pip install -r requirements_pinned.txt | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
pip install  openai faiss-gpu | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
pip install bitsandbytes accelerate | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
pip install -U bitsandbytes | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
# === Optional: Use alternate requirements file? ===
# pip install -r requirements_pinned2.txt  # Uncomment if preferred

# === Optional: WandB version pinning ===
# echo "wandb==<your_version>" >> requirements.txt  # TODO


hf_login
wandb_login
openai_login
deepseek_login


# === Setup llm/chat_templates ===
cd $REPO_DIR/llm
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
               --data "./data/harmful_behavior_requests_excerpt.json" \
               --model "${HF_MODEL_NAME}"

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


# === Evaluate results ===
cd "$SCRIPTS_DIR"
python autodan-turbo_eval.py $SAVE_FILE $HF_MODEL_NAME




