#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND"' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../ressources/utils.sh"

parse_config "$1"

# === CONFIGURATION ===
CONDA_ENV_NAME="harmbench"
REPO_URL="https://github.com/BambiMC/HarmBench.git"
REPO_DIR="$INSTALL_DIR/HarmBench"
PYTHON_VERSION="3.11"
GPU_NAME="RTX A6000"


# === SETUP ===
ensure_miniconda "$INSTALL_DIR"
ensure_conda_env "$CONDA_ENV_NAME" "$PYTHON_VERSION"
clone_repo

git reset --hard HEAD # Otherwise the template will not be there to be updated, if the benchmark is run multiple times (Harmbench specific)


# === Install Python Dependencies ===
# pip install -r requirements_pinned.txt  | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
pip install -r requirements_pinned2.txt 
python -m spacy download en_core_web_sm
# pip uninstall -y transformers
# pip install transformers==4.44.0
# pip install pillow timm mistral-common accelerate vllm


hf_login


# === Environment Variables ===

cd $REPO_DIR
# Modify models.yaml to support HF_MODEL_NAME
echo "Using HF_MODEL_NAME: $HF_MODEL_NAME"

python modify_models_yaml.py "$HF_MODEL_NAME" false bfloat16 1


# export HF_MODEL_NAME="llama2_7b"
export MODEL_NAME="$HF_MODEL_NAME" #TODO Bringt das was? / Aber das hier scheine ich wegen dem Fehler zu brauchen, sonst ersetzt er das generic template nicht
export CUDA_DEVICE_ORDER=PCI_BUS_ID
export CUDA_VISIBLE_DEVICES=$(nvidia-smi --query-gpu=index,name --format=csv,noheader | grep "$GPU_NAME" | cut -d',' -f1 | tr '\n' ',' | sed 's/,$//')

# === Run Benchmark ===
cd $REPO_DIR

# Harmbench empfielt local_parallel als --mode
# Some methods (AutoDAN, PAIR, TAP) require manually adding experiment configs for new models.


# python ./scripts/run_pipeline.py --methods AutoPrompt --models $HF_MODEL_NAME --step all --mode local
# python ./scripts/run_pipeline.py --methods HumanJailbreaks --models $HF_MODEL_NAME --step all --mode local_parallel

# python ./scripts/run_pipeline.py --methods HumanJailbreaks --models llama2_7b --step all --mode local #TODO Das hier als nächstes testen
# python ./scripts/run_pipeline.py --methods HumanJailbreaks --models llama2_7b --mode local #TODO Das hier als nächstes testen


# echo "STEP 1"
# python ./scripts/run_pipeline.py --methods HumanJailbreaks --models llama2_7b --step 1 --mode local
# echo "STEP 1.5"
# python ./scripts/run_pipeline.py --methods HumanJailbreaks --models llama2_7b --step 1.5 --mode local
# echo "STEP 2 AND 3"
# python ./scripts/run_pipeline.py --methods HumanJailbreaks --models llama2_7b  --step 2_and_3 --mode local

python ./scripts/run_pipeline.py --methods HumanJailbreaks --models llama2_7b --step all --mode local


# # Generate test cases for a subset of methods and models using a SLURM cluster
# python ./scripts/run_pipeline.py --methods ZeroShot,PEZ,TAP --models llama2_7b --step 1 --mode slurm
# # Merge test cases for the above methods on a local machine
# python ./scripts/run_pipeline.py --methods ZeroShot,PEZ,TAP --models llama2_7b --step 1.5 --mode local
# # Generate and evaluate completions for the above methods and models using a SLURM cluster
# python ./scripts/run_pipeline.py --methods ZeroShot,PEZ,TAP --models llama2_7b  --step 2_and_3 --mode slurm

# AutoDAN: hat nicht genügend VRAM auf der 2. / 3. GPU
# AutoPrompt:

# (non-exhaustive) methods list: !AutoDAN!,AutoPrompt,DirectRequest,GCG-Multi,GCG-Transfer,FewShot,GBDA,GCG,HumanJailbreaks,!PAIR!,PAP-top5,PEZ,!TAP!,TAP-Transfer,UAT,ZeroShot
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


# AutoPrompt: läuft immerhin lange
# HumanJailbreaks: 