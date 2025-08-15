#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND"' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../ressources/utils.sh"

parse_config "$1"

# === CONFIGURATION ===
CONDA_ENV_NAME="easyjailbreak"
REPO_URL="https://github.com/BambiMC/EasyJailbreak.git"
REPO_DIR="$INSTALL_DIR/HarmBench"
PYTHON_VERSION="3.10"


# === Setup ===
ensure_miniconda "$INSTALL_DIR"
clone_repo
ensure_conda_env "$CONDA_ENV_NAME" "$PYTHON_VERSION"


# === Install Python Dependencies ===
# pip install -r requirements_pinned.txt  | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
# python -m spacy download en_core_web_sm | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
pip install -e .


hf_login


# === Environment Variables ===


export HF_MODEL_NAME="llama2_7b" #TODO brauche ich das wirklich? NUR TEMPORÄR
export MODEL_NAME="$HF_MODEL_NAME" # TOFIX Bringt das was? / Aber das hier scheine ich wegen dem Fehler zu brauchen, sonst ersetzt er das generic template nicht
export CUDA_DEVICE_ORDER=PCI_BUS_ID
export CUDA_VISIBLE_DEVICES=$(nvidia-smi --query-gpu=index,name --format=csv,noheader | grep "$GPU_NAME" | cut -d',' -f1 | tr '\n' ',' | sed 's/,$//')
# export CUDA_VISIBLE_DEVICES=0 #Nur damit kommt der Fehler auf jeden Fall

# === Run Benchmark ===
cd $REPO_DIR

# echo "Starting HarmBench benchmark with CUDA_VISIBLE_DEVICES: $CUDA_VISIBLE_DEVICES"
python -c "import torch; print(f'Number of available GPUs: {torch.cuda.device_count()}')"
python ./scripts/run_pipeline.py --methods AutoPrompt --models $HF_MODEL_NAME --step all --mode local

# AutoDAN: hat nicht genügend VRAM auf der 2. / 3. GPU
# AutoPrompt:

# (non-exhaustive) methods list: AutoDAN,AutoPrompt,DirectRequest,GCG-Multi,GCG-Transfer,FewShot,GBDA,GCG,HumanJailbreaks,PAIR,PAP-top5,PEZ,TAP,TAP-Transfer,UAT,ZeroShot
# (non-exhaustive) models list: llama2_7b,llama2_13b,llama2_70b,vicuna_7b_v1_5,vicuna_13b_v1_5,koala_7b,koala_13b,orca_2_7b,orca_2_13b,solar_10_7b_instruct,openchat_3_5_1210,starling_7b,mistral_7b_v2,mixtral_8x7b,zephyr_7b_robust6_data2,zephyr_7b,baichuan2_7b,baichuan2_13b,qwen_7b_chat,qwen_14b_chat,qwen_72b_chat,gpt-3.5-turbo-1106,gpt-3.5-turbo-0613,gpt-4-1106-preview,gpt-4-0613,gpt-4-vision-preview,claude-instant-1,claude-2.1,claude-2,gemini,mistral-medium,LLaVA,InstructBLIP,Qwen,GPT4V


### ➕ Using your own models in HarmBench
# You can easily add new Hugging Face transformers models in [configs/model_configs/models.yaml](configs/model_configs/models.yaml) 
# by simply adding an entry for your model. 
# This model can then be directly evaluated on most red teaming methods without modifying the method configs 
# (using our dynamic experiment config parsing code, described in [./docs/configs.md](./docs/configs.md)). 
# Some methods (AutoDAN, PAIR, TAP) require manually adding experiment configs for new models.

# === Evaluation ===
# cd $SCRIPTS_DIR
# TODO
# python jailbreakbench_eval.py $SAVE_FILE $HF_MODEL_NAME
