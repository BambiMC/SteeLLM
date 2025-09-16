#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND"' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../ressources/utils.sh"

parse_config "$1"

# === CONFIGURATION ===
CONDA_ENV_NAME="agentdojo"
REPO_URL="https://github.com/BambiMC/agentdojo-hf.git"
REPO_DIR="$INSTALL_DIR/agentdojo-hf"
PYTHON_VERSION="3.11"


# === SETUP ===
ensure_miniconda "$INSTALL_DIR"
ensure_conda_env "$CONDA_ENV_NAME" "$PYTHON_VERSION"

hf_login
openai_login
deepseek_login
google_gemini_login
anthropic_login


clone_repo

git reset --hard HEAD # Otherwise the template will not be there to be updated, if the benchmark is run multiple times (Agentdojo specific)



# Modify ModelsEnum to support HF_MODEL_NAME
HF_MODEL_NAME_ENUM=$(echo "$HF_MODEL_NAME" | sed -E 's/[-\/\.]/_/g' | tr '[:lower:]' '[:upper:]')
echo "Using HF_MODEL_NAME_ENUM: $HF_MODEL_NAME_ENUM"

python modify_ModelsEnum.py "$HF_MODEL_NAME"


# === Install Requirements ===
pip install torch numpy transformers tokenizers build pillow timm mistral-common accelerate bitsandbytes | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true

# Build and install the package
python -m build  | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true

WHEEL_FILE=$(ls dist/agentdojo-*-py3-none-any.whl | tail -n 1) 


pip install "$WHEEL_FILE" --force-reinstall  | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true

pip uninstall -y transformers tokenizers
# pip install transformers==4.43.3 tokenizers==0.19.1
pip install --upgrade transformers tokenizers


# export CUDA_VISIBLE_DEVICES=0 #TODO Remove this before running on HPC

AVG_UTILS=()

AVG_UTILS+=($(python -m agentdojo.scripts.benchmark -s workspace --model "$HF_MODEL_NAME_ENUM" | grep "Average utility" | awk -F ':' '{print $2}' | xargs))
echo "✅ workspace Average utility = ${AVG_UTILS[-1]}"

AVG_UTILS+=($(python -m agentdojo.scripts.benchmark -s banking --model "$HF_MODEL_NAME_ENUM" | grep "Average utility" | awk -F ':' '{print $2}' | xargs))
echo "✅ banking Average utility = ${AVG_UTILS[-1]}"

AVG_UTILS+=($(python -m agentdojo.scripts.benchmark -s slack --model "$HF_MODEL_NAME_ENUM" | grep "Average utility" | awk -F ':' '{print $2}' | xargs))
echo "✅ slack Average utility = ${AVG_UTILS[-1]}"

AVG_UTILS+=($(python -m agentdojo.scripts.benchmark -s travel --model "$HF_MODEL_NAME_ENUM" | grep "Average utility" | awk -F ':' '{print $2}' | xargs))
echo "✅ travel Average utility = ${AVG_UTILS[-1]}"

# Print them all
echo "=== All Average Utilities ==="
for i in "${!AVG_UTILS[@]}"; do
    echo "Scenario $((i+1)): ${AVG_UTILS[$i]}"
done

# Example: pass the last one to eval
cd "$SCRIPT_DIR"
python "$SCRIPT_DIR/agentdojo_eval.py" "${AVG_UTILS[@]}" "$HF_MODEL_NAME"