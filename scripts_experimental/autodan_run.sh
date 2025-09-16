#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND"' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../ressources/utils.sh"

parse_config "$1"

# === CONFIGURATION ===
CONDA_ENV_NAME="AutoDAN"
REPO_URL="https://github.com/BambiMC/AutoDAN.git"
REPO_DIR="$INSTALL_DIR/AutoDAN"
RESULTS="${INSTALL_DIR}/AutoDAN/results/autodan_ga/${HF_MODEL_NAME}_0_normal.json"
PYTHON_VERSION="3.10"


# === ENV VARIABLES ===
export CUDA_VISIBLE_DEVICES=$(nvidia-smi --query-gpu=index,name --format=csv,noheader | grep "RTX A6000" | cut -d',' -f1 | tr '\n' ',' | sed 's/,$//')



ensure_miniconda "$INSTALL_DIR"
ensure_conda_env "$CONDA_ENV_NAME" "$PYTHON_VERSION"
clone_repo

hf_login
openai_login
deepseek_login
google_gemini_login
anthropic_login

# === Install requirements ===
if grep -q "numpy==1.26.0" requirements.txt; then
    sed -i 's/numpy==1.26.0/numpy>=1.26.0/' requirements.txt
fi
pip install -r requirements.txt  | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true

#temp try to fix qwen
pip uninstall -y transformers  | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
pip install transformers==4.53.2 | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
pip install protobuf==3.20.3 | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
pip install --upgrade accelerate | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
pip install importlib-metadata | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
# python -c "import accelerate; print(accelerate.__version__)"
accelerate config default

echo "All requirements installed for $CONDA_ENV_NAME environment."


hf_login

# === Start benchmark ===
cd $REPO_DIR/models
python download_models.py $HF_MODEL_NAME
cd ..
python autodan_ga_eval.py --model $HF_MODEL_NAME --num_steps 20 --dataset_path ./data/advbench/harmful_behaviors_excerpt.csv
#TODO python autodan_hga_eval.py --model $HF_MODEL_NAME --num_steps 20 --dataset_path ./data/advbench/harmful_behaviors_excerpt.csv


# === Evaluate results ===
cd $SCRIPTS_DIR
python autodan_eval.py $RESULTS $HF_MODEL_NAME