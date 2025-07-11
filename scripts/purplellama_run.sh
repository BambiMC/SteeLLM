#!/bin/bash

# === CONFIGURATION ===
GPU_NAME="RTX A6000"
CONFIG_FILE="../config.json"
HF_MODEL_NAME=$(grep -oP '"HF_MODEL_NAME"\s*:\s*"\K[^"]+' ../config.json)

USER_DIR=$(grep -oP '"USER_DIR"\s*:\s*"\K[^"]+' "$CONFIG_FILE")
INSTALL_DIR=$(grep -oP '"INSTALL_DIR"\s*:\s*"\K[^"]+' "$CONFIG_FILE")
SCRIPTS_DIR=$PWD
MINICONDA_PATH="$INSTALL_DIR/miniconda3"
PIP_CACHE_DIR="$INSTALL_DIR/.cache"
HF_CACHE_DIR="$INSTALL_DIR/.huggingface_cache"
CONDA_ENV_NAME="purplellama"
PYTHON_VERSION="3.10"
REPO_URL="https://github.com/BambiMC/PurpleLlama.git"
REPO_DIR="$INSTALL_DIR/PurpleLlama"


set -e
trap 'echo "❌ Error on line $LINENO: \"$BASH_COMMAND\" failed."' ERR

# === ENVIRONMENT ===
export CUDA_VISIBLE_DEVICES=$(nvidia-smi --query-gpu=index,name --format=csv,noheader | grep "$GPU_NAME" | cut -d',' -f1 | tr '\n' ',' | sed 's/,$//')
export HF_HOME="$HF_CACHE_DIR"
export PIP_CACHE_DIR="$PIP_CACHE_DIR"

# === Directories ===
mkdir -p "$HF_CACHE_DIR" "$PIP_CACHE_DIR"
cd "$INSTALL_DIR"

# === Miniconda Setup ===
if ! command -v conda &> /dev/null; then
    if [[ ! -d "$MINICONDA_PATH" ]]; then
        echo "📦 Installing Miniconda..."
        wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ./miniconda.sh
        bash ./miniconda.sh -b -p "$MINICONDA_PATH"
    fi
    export PATH="$MINICONDA_PATH/bin:$PATH"
fi
eval "$(conda shell.bash hook)"

# === Clone PurpleLlama ===
if [[ ! -d "$REPO_DIR" ]]; then
    echo "📁 Cloning PurpleLlama repo..."
    git clone "$REPO_URL" "$REPO_DIR"
fi
cd "$REPO_DIR"
git pull

# === Conda Environment ===
if ! conda info --envs | grep -q "$CONDA_ENV_NAME"; then
    echo "📦 Creating conda environment: $CONDA_ENV_NAME"
    conda create -y -n "$CONDA_ENV_NAME" python="$PYTHON_VERSION"
fi
conda activate "$CONDA_ENV_NAME"

# === Install Requirements ===
pip install -r CybersecurityBenchmarks/requirements.txt
pip install torch transformers huggingface_hub bitsandbytes accelerate

# === Huggingface Setup ===
cd "$SCRIPTS_DIR"
HF_TOKEN=$(grep -oP '"HUGGINGFACE_API_KEY"\s*:\s*"\K[^"]+' ../config.json)
export HF_TOKEN=$HF_TOKEN

if [[ -n "$HF_TOKEN" ]]; then
    huggingface-cli login --token "$HF_TOKEN"
else
    echo "huggingface missing in config.json. Please add your token."
    exit 1
fi

# === Export Runtime Environment ===
DATASETS="$REPO_DIR/CybersecurityBenchmarks/datasets"
export DATASETS="$REPO_DIR/CybersecurityBenchmarks/datasets"

# === LLM Config ===
LLM="LOCALLLM::$HF_MODEL_NAME::"

# === Run Benchmarks ===

function run_benchmark() {
    echo "🚀 Running benchmark: $1"
    python3 -m CybersecurityBenchmarks.benchmark.run "$@"
    echo "✅ Completed benchmark: $1"
}

cd "$REPO_DIR"

# --- MITRE ---
run_benchmark \
   --benchmark=mitre \
   --prompt-path="$DATASETS/mitre/mitre_benchmark_100_per_category_with_augmentation.json" \
   --response-path="$DATASETS/mitre_responses.json" \
   --judge-response-path="$DATASETS/mitre_judge_responses.json" \
   --stat-path="$DATASETS/mitre_stat.json" \
   --judge-llm="$LLM" \
   --expansion-llm="$LLM" \
   --llm-under-test="$LLM"

# run_benchmark \
#    --benchmark=mitre \
#    --prompt-path="$DATASETS/mitre/mitre_prompts_multilingual_machine_translated.json" \
#    --response-path="$DATASETS/mitre_responses.json" \
#    --judge-response-path="$DATASETS/mitre_judge_responses.json" \
#    --stat-path="$DATASETS/mitre_stat.json" \
#    --judge-llm="$LLM" \
#    --expansion-llm="$LLM" \
#    --llm-under-test="$LLM"

# # --- False Refusal Rate (FRR) ---
# run_benchmark \
#    --benchmark=frr \
#    --prompt-path="$DATASETS/frr/frr.json" \
#    --response-path="$DATASETS/frr/frr_responses.json" \
#    --stat-path="$DATASETS/frr/frr_stat.json" \
#    --llm-under-test="$LLM"

# run_benchmark \
#    --benchmark=frr \
#    --prompt-path="$DATASETS/frr/frr_multilingual_machine_translated.json" \
#    --response-path="$DATASETS/frr/frr_responses.json" \
#    --stat-path="$DATASETS/frr/frr_stat.json" \
#    --llm-under-test="$LLM"

# # --- Prompt Injection (PI) ---
# run_benchmark \
#    --benchmark=prompt-injection \
#    --prompt-path="$DATASETS/prompt_injection/prompt_injection.json" \
#    --response-path="$DATASETS/prompt_injection/prompt_injection_responses.json" \
#    --judge-response-path="$DATASETS/prompt_injection/prompt_injection_judge_responses.json" \
#    --stat-path="$DATASETS/prompt_injection/prompt_injection_stat.json" \
#    --judge-llm="$LLM" \
#    --llm-under-test="$LLM"

# run_benchmark \
#    --benchmark=prompt-injection \
#    --prompt-path="$DATASETS/prompt_injection/prompt_injection_multilingual_machine_translated.json" \
#    --response-path="$DATASETS/prompt_injection/prompt_injection_responses.json" \
#    --judge-response-path="$DATASETS/prompt_injection/prompt_injection_judge_responses.json" \
#    --stat-path="$DATASETS/prompt_injection/prompt_injection_stat.json" \
#    --judge-llm="$LLM" \
#    --llm-under-test="$LLM"

# === Evaluation ===
RESULTS="$DATASETS/mitre_stat.json"
cd "$SCRIPTS_DIR"
python purplellama_eval.py $RESULTS $HF_MODEL_NAME $1