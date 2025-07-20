#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND"' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../ressources/utils.sh"

parse_config

# === CONFIGURATION ===
CONDA_ENV_NAME="agentdojo"
REPO_URL="https://github.com/BambiMC/agentdojo-hf.git"
REPO_DIR="$INSTALL_DIR/agentdojo-hf"
PYTHON_VERSION="3.10"

ensure_miniconda "$INSTALL_DIR"
ensure_conda_env "$CONDA_ENV_NAME" "$PYTHON_VERSION"
hf_login
openai_login
clone_repo

git reset --hard HEAD # Otherwise the template will not be there to be updated, if the benchmark is run multiple times (Agentdojo specific)



# Modify ModelsEnum to support HF_MODEL_NAME
HF_MODEL_NAME_ENUM=$(echo "$HF_MODEL_NAME" | sed -E 's/[-\/\.]/_/g' | tr '[:lower:]' '[:upper:]')
echo "Using HF_MODEL_NAME_ENUM: $HF_MODEL_NAME_ENUM"

python modify_ModelsEnum.py "$HF_MODEL_NAME"


# === Install Requirements ===
pip install torch numpy transformers  | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true

pip install build  | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true

python -m build  | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
WHEEL_FILE=$(ls dist/agentdojo-*-py3-none-any.whl | tail -n 1) 
pip install "$WHEEL_FILE" --force-reinstall  | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true




# === Run Benchmark ===
AVG_UTILITY=$(python -m agentdojo.scripts.benchmark -s workspace --model "$HF_MODEL_NAME_ENUM" | grep "Average utility" | awk -F ':' '{print $2}' | xargs)
echo "✅ Average utility = $AVG_UTILITY"

# === Evaluate Results ===
cd $SCRIPT_DIR
python "$SCRIPT_DIR/agentdojo_eval.py" "$AVG_UTILITY" "$HF_MODEL_NAME"