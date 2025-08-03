#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND"' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../ressources/utils.sh"

parse_config

# === CONFIGURATION ===
REPO_URL="https://github.com/BambiMC/BadChain.git"
REPO_DIR="$INSTALL_DIR/BadChain"
CONDA_ENV_NAME="badchain"
PYTHON_VERSION="3.10" #TODO

ensure_miniconda "$INSTALL_DIR"
clone_repo
ensure_conda_env "$CONDA_ENV_NAME" "$PYTHON_VERSION"

# === Install Requirements ===
cd $REPO_DIR
pip install tqdm google-generativeai tenacity numpy | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true

pip install openai==0.28.1 | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
pip install datasets | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true


# === Environment Variables ===
export PIP_CACHE_DIR="$PIP_CACHE_DIR"
export HF_HOME="$HF_CACHE_DIR"


hf_login #TODO



# === Run Script ===
cd "$REPO_DIR"


# Set openai api key in utils.py: gpt_apis = {
    # 0: "sk-your-api-key", 
# } 
UTILS_FILE="$REPO_DIR/utils.py"
# Replace the API key inside the utils.py file
sed -i "s/0: \".*\"/0: \"$OPENAI_API_KEY\"/" "$UTILS_FILE"


python run.py --llm gpt-4o-mini --task gsm8k --cot 8_p06_6+2


# === Evaluation ===
# RESULTS="$REPO_DIR/evaluation_metrics.json" #TODO
# cd "$SCRIPTS_DIR"
# python openpromptinjection_eval.py $RESULTS $HF_MODEL_NAME 