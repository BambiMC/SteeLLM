#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND"' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../ressources/utils.sh"

parse_config

# === CONFIGURATION ===
REPO_URL="https://github.com/BambiMC/AgentPoison.git"
REPO_DIR="$INSTALL_DIR/AgentPoison"
CONDA_ENV_NAME="agentpoison"
PYTHON_VERSION="3.10" #TODO

ensure_miniconda "$INSTALL_DIR"
clone_repo
ensure_conda_env "$CONDA_ENV_NAME" "$PYTHON_VERSION"

# === Install Requirements ===
cd $REPO_DIR
conda env update -f environment.yml --name $CONDA_ENV_NAME | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
pip install gdown | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
pip uninstall -y autogen
pip install autogen==0.3.2
pip install Levenshtein

# === Environment Variables ===
export PIP_CACHE_DIR="$PIP_CACHE_DIR"
export HF_HOME="$HF_CACHE_DIR"


hf_login #TODO

# === Run Script ===
cd "$REPO_DIR"






# Set the new max limit
NEW_LIMIT=1000

# Locate the gdown package inside the virtual environment
GDOWN_PATH=$(find $INSTALL_DIR/miniconda3/envs/agentpoison/lib/python3.9/site-packages/ -type f -name download_folder.py 2>/dev/null)

if [ -z "$GDOWN_PATH" ]; then
  echo "❌ Could not find download_folder.py in the virtual environment."
  exit 1
fi

# Update the MAX_NUMBER_FILES value using sed
sed -i.bak "s/^MAX_NUMBER_FILES = [0-9]\+/MAX_NUMBER_FILES = $NEW_LIMIT/" "$GDOWN_PATH"

# Check if the change was successful
if grep -q "MAX_NUMBER_FILES = $NEW_LIMIT" "$GDOWN_PATH"; then
  echo "✅ MAX_NUMBER_FILES successfully updated to $NEW_LIMIT in $GDOWN_PATH"
else
  echo "⚠️ Failed to update MAX_NUMBER_FILES."
fi



# Agent-Driver
cd "$REPO_DIR"
mkdir -p "agentdriver/data"
gdown --folder https://drive.google.com/drive/folders/1ZrSZfTlH347hNoKADY3WjN0usmK9Dgt2
cd "$REPO_DIR/agentdriver"

echo "Run Agent-Driver inference"
sh ../scripts/agent_driver/run_inference.sh

echo "Run Agent-Driver evaluation for ASR-t"
sh ../scripts/agent_driver/run_evaluation.sh




# # ReAct-StrategyQA
# mkdir -p "ReAct/database"
# cd "$REPO_DIR/ReAct/database"
# # Download StrategyQA dataset and place it here
# cd "$REPO_DIR"

# echo "Run ReAct-StrategyQA inference with GPT-3.5"
# python ReAct/run_strategyqa_gpt3.5.py --model dpr --task_type adv

# # If using LLaMA-3-70B through Replicate API (make sure to export your API key)
# # echo "Run ReAct-StrategyQA inference with LLaMA-3-70B"
# # python ReAct/run_strategyqa_llama3_api.py --model dpr --task_type adv

# # Evaluate StrategyQA attack performance
# echo "Evaluate StrategyQA red-teaming results"
# python ReAct/eval.py -p [RESPONSE_PATH]



#EHR Agent
mkdir -p "EhrAgent/database"
cd "$REPO_DIR/EhrAgent/database"
gdown --folder https://drive.google.com/drive/folders/1VUHnrm1hhKzk9I_m5d8V1QhacagoHhb6
# unzip ehragent_db.zip
# rm ehragent_db.zip
cd "$REPO_DIR"
echo "Run EhrAgent/ehragent/main.py"
python EhrAgent/ehragent/main.py --backbone gpt --model dpr --algo ap --attack


# === Evaluation ===

# python EhrAgent/ehragent/eval.py -p [RESPONSE_PATH]

# RESULTS="$REPO_DIR/evaluation_metrics.json" #TODO
# cd "$SCRIPTS_DIR"
# python openpromptinjection_eval.py $RESULTS $HF_MODEL_NAME 