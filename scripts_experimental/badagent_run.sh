#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND"' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../ressources/utils.sh"

parse_config "$1"

# === CONFIGURATION ===
REPO_URL="https://github.com/DPamK/BadAgent.git"
REPO_DIR="$INSTALL_DIR/BadAgent"
CONDA_ENV_NAME="badagent"
PYTHON_VERSION="3.10.10"

ensure_miniconda "$INSTALL_DIR"
clone_repo
ensure_conda_env "$CONDA_ENV_NAME" "$PYTHON_VERSION"

# === Install Requirements ===
cd $REPO_DIR
pip install -r requirements.txt | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
pip install IPython beautifulsoup4 | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true




# === Environment Variables ===




hf_login




# === Run Script ===
cd "$REPO_DIR"
huggingface-cli download --repo-type dataset --resume-download THUDM/AgentInstruct --local-dir origin_data/AgentInstruct --local-dir-use-symlinks False

# You can initiate data poisoning in the following command:
python main.py \
        --task poison \
        --data_path THUDM/AgentInstruct \
        --agent_type mind2web \
        --save_poison_data_path data/ \
        --attack_percent 1.0

# You can also use the local data path to poison the data:

# python main.py \
#         --task poison \
#         --data_path origin_data/AgentInstruct \
#         --agent_type mind2web \
#         --save_poison_data_path data/ \
#         --attack_percent 1.0

# Thread Models
# You can train the threat model using the following command line:

python main.py \
        --task train \
        --model_name_or_path zai-org/chatglm3-6b \
        --conv_type chatglm3 \
        --agent_type os \
        --train_data_path data/os_attack_1_0.json \
        --lora_save_path output/os_qlora \
        --use_qlora \
        --batch_size 2

# Evaluation
# You can evaluate the threat model using the following command:

python main.py \
        --task eval \
        --model_name_or_path zai-org/chatglm3-6b \
        --conv_type chatglm3 \
        --agent_type mind2web \
        --eval_lora_module_path output/os_qlora \
        --data_path data/os_attack_1_0.json \
        --eval_model_path zai-org/chatglm3-6b



# python openpromptinjection.py $HF_MODEL_NAME


# === Evaluation ===
# RESULTS="$REPO_DIR/evaluation_metrics.json" #TODO
# cd "$SCRIPTS_DIR"
# python openpromptinjection_eval.py $RESULTS $HF_MODEL_NAME 