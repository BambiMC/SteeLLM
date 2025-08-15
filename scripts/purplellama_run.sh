#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND"' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../ressources/utils.sh"

parse_config

# === CONFIGURATION ===
GPU_NAME="RTX A6000"
CONDA_ENV_NAME="purplellama"
PYTHON_VERSION="3.10"
REPO_URL="https://github.com/BambiMC/PurpleLlama.git"
REPO_DIR="$INSTALL_DIR/PurpleLlama"


# === ENVIRONMENT ===
export CUDA_VISIBLE_DEVICES=$(nvidia-smi --query-gpu=index,name --format=csv,noheader | grep "$GPU_NAME" | cut -d',' -f1 | tr '\n' ',' | sed 's/,$//')
export HF_HOME="$HF_CACHE_DIR"
export PIP_CACHE_DIR="$PIP_CACHE_DIR"


ensure_miniconda "$INSTALL_DIR"
clone_repo
ensure_conda_env "$CONDA_ENV_NAME" "$PYTHON_VERSION"


# === Install Requirements ===
pip install -r CybersecurityBenchmarks/requirements.txt  | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
pip install torch transformers huggingface_hub bitsandbytes accelerate   | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true


hf_login

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

echo "Running benchmarks for model: $HF_MODEL_NAME"
echo "Running benchmarks with LLM: $LLM"

# --- MITRE ---
run_benchmark \
   --benchmark=mitre \
   --prompt-path="$DATASETS/mitre/mitre_benchmark_10_per_category_with_augmentation.json" \
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
cd $SCRIPTS_DIR
python purplellama_eval.py $RESULTS $HF_MODEL_NAME