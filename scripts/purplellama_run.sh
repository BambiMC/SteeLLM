#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND"' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../ressources/utils.sh"

parse_config "$1"

# === CONFIGURATION ===
GPU_NAME="RTX A6000"
CONDA_ENV_NAME="purplellama"
PYTHON_VERSION="3.10"
REPO_URL="https://github.com/BambiMC/PurpleLlama.git"
REPO_DIR="$INSTALL_DIR/PurpleLlama"


# === ENVIRONMENT ===
# export CUDA_VISIBLE_DEVICES=$(nvidia-smi --query-gpu=index,name --format=csv,noheader | grep "$GPU_NAME" | cut -d',' -f1 | tr '\n' ',' | sed 's/,$//')

ensure_miniconda "$INSTALL_DIR"
clone_repo
ensure_conda_env "$CONDA_ENV_NAME" "$PYTHON_VERSION"


# === Install Requirements ===
pip install -r CybersecurityBenchmarks/requirements.txt | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
pip install torch transformers==4.55.2 huggingface_hub bitsandbytes accelerate triton kernels | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
pip install google-genai | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true

pip install --upgrade openai
pip install httpx==0.27.2

hf_login
openai_login
deepseek_login
google_gemini_login
anthropic_login

# === LLM Config ===
PROVIDER="LOCALLLM"
if [[ "$HF_MODEL_NAME" == *"gpt-5"* ]]; then
    PROVIDER="OPENAI"
elif [[ "$HF_MODEL_NAME" == *"claude"* ]]; then
    PROVIDER="ANTHROPIC"
elif [[ "$HF_MODEL_NAME" == *"gemini"* ]]; then
    PROVIDER="GOOGLEGENAI"
elif [[ "$HF_MODEL_NAME" == *"deepseek"* ]]; then
    PROVIDER="DEEPSEEK"
else
   PROVIDER="LOCALLLM"
fi
echo "Provider = $PROVIDER"

LLM="$PROVIDER::$HF_MODEL_NAME::"
SUPPORTER_LLM="LOCALLLM::dphn/Dolphin-Llama3.1-8B-Instruct-6.0bpw-h6-exl2::"

TEST_MODE="false"
BENCHMARK_NAME="all"
# BENCHMARK_NAME can be one of the following options:
# mitre, mitre-multilingual, frr, frr-multilingual, pi, pi-multilingual, all


# === Export Runtime Environment ===
DATASETS="$REPO_DIR/CybersecurityBenchmarks/datasets"
export DATASETS

if [ "$TEST_MODE" == "true" ]; then
    PROMPT_PATHS=(
        "$DATASETS/mitre/mitre_benchmark_test.json"
        "$DATASETS/mitre/mitre_prompts_multilingual_machine_translated_test.json"
        "$DATASETS/frr/frr_test.json"
        "$DATASETS/frr/frr_multilingual_machine_translated_test.json"
        "$DATASETS/prompt_injection/prompt_injection_test.json"
        "$DATASETS/prompt_injection/prompt_injection_multilingual_machine_translated_test.json"
    )
else 
   PROMPT_PATHS=(
      "$DATASETS/mitre/mitre_benchmark_10_per_category_with_augmentation.json"
      "$DATASETS/mitre/mitre_prompts_multilingual_machine_translated_every_7nth_extracted.json"
      "$DATASETS/frr/frr_every_7nth_extracted.json"
      "$DATASETS/frr/frr_multilingual_machine_translated_every_7nth_extracted.json"
      "$DATASETS/prompt_injection/prompt_injection_every_2nd_extracted.json"
      "$DATASETS/prompt_injection/prompt_injection_multilingual_machine_translated_every_10nth_extracted.json"
   )
fi


# === Run Benchmarks ===
function run_benchmark() {
    cd "$REPO_DIR"

    echo "🚀 Running benchmark: $1"

    START_TIME=$(date +%s)
    TIMESTAMP=$(date -d "+2 hours" +"%y%m%d_%H%M")

    python3 -m CybersecurityBenchmarks.benchmark.run "$@"

    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    # Format duration as H:M:S
    HOURS=$((DURATION / 3600))
    MINUTES=$(( (DURATION % 3600) / 60 ))
    SECONDS=$((DURATION % 60))
    echo "\nEnd Time: $(date +"%Y-%m-%d %H:%M:%S")"
    echo "\nTotal Duration: ${HOURS}h ${MINUTES}m ${SECONDS}s"

    echo "✅ Completed benchmark: $1"
    cd $SCRIPTS_DIR
}

echo "Running benchmarks for HF_MODEL_NAME: $HF_MODEL_NAME"
echo "Running benchmarks with LLM: $LLM"

# all benchmarks mode
if [ "$BENCHMARK_NAME" == "all" ]; then
  for bm in mitre mitre-multilingual frr frr-multilingual pi pi-multilingual; do
    case "$bm" in
      "mitre")
        echo "--- MITRE ---"
        run_benchmark \
          --benchmark=mitre \
          --prompt-path="${PROMPT_PATHS[0]}" \
          --response-path="$DATASETS/mitre_responses.json" \
          --judge-response-path="$DATASETS/mitre_judge_responses.json" \
          --stat-path="$DATASETS/mitre_stat.json" \
          --judge-llm="$SUPPORTER_LLM" \
          --expansion-llm="$SUPPORTER_LLM" \
          --llm-under-test="$LLM"
        RESULTS="$DATASETS/mitre_stat.json"
        python purplellama_eval.py "$RESULTS" "$HF_MODEL_NAME" "MITRE"
        ;;

      "mitre-multilingual")
        echo "--- MITRE Multilingual ---"
        run_benchmark \
          --benchmark=mitre \
          --prompt-path="${PROMPT_PATHS[1]}" \
          --response-path="$DATASETS/mitre_responses.json" \
          --judge-response-path="$DATASETS/mitre_multilingual_judge_responses.json" \
          --stat-path="$DATASETS/mitre_multilingual_stat.json" \
          --judge-llm="$SUPPORTER_LLM" \
          --expansion-llm="$SUPPORTER_LLM" \
          --llm-under-test="$LLM"
        RESULTS="$DATASETS/mitre_multilingual_stat.json"
        python purplellama_eval.py "$RESULTS" "$HF_MODEL_NAME" "MITRE Multilingual"
        ;;

      "frr")
        echo "--- False Refusal Rate (FRR) ---"
        run_benchmark \
          --benchmark=frr \
          --prompt-path="${PROMPT_PATHS[2]}" \
          --response-path="$DATASETS/frr_responses.json" \
          --stat-path="$DATASETS/frr_stat.json" \
          --llm-under-test="$LLM"
        RESULTS="$DATASETS/frr_stat.json"
        python purplellama_eval.py "$RESULTS" "$HF_MODEL_NAME" "FRR"
        ;;

      "frr-multilingual")
        echo "--- False Refusal Rate (FRR) Multilingual ---"
        run_benchmark \
          --benchmark=frr \
          --prompt-path="${PROMPT_PATHS[3]}" \
          --response-path="$DATASETS/frr_multilingual_responses.json" \
          --stat-path="$DATASETS/frr_multilingual_stat.json" \
          --llm-under-test="$LLM"
        RESULTS="$DATASETS/frr_multilingual_stat.json"
        python purplellama_eval.py "$RESULTS" "$HF_MODEL_NAME" "FRR Multilingual"
        ;;

      "pi")
        echo "--- Prompt Injection (PI) ---"
        run_benchmark \
          --benchmark=prompt-injection \
          --prompt-path="${PROMPT_PATHS[4]}" \
          --response-path="$DATASETS/prompt_injection/prompt_injection_responses.json" \
          --judge-response-path="$DATASETS/prompt_injection_judge_responses.json" \
          --stat-path="$DATASETS/prompt_injection_stat.json" \
          --judge-llm="$SUPPORTER_LLM" \
          --llm-under-test="$LLM"
        RESULTS="$DATASETS/prompt_injection_stat.json"
        python purplellama_eval.py "$RESULTS" "$HF_MODEL_NAME" "PI"
        ;;

      "pi-multilingual")
        echo "--- Prompt Injection (PI) Multilingual ---"
        run_benchmark \
          --benchmark=prompt-injection \
          --prompt-path="${PROMPT_PATHS[5]}" \
          --response-path="$DATASETS/prompt_injection/prompt_injection_responses.json" \
          --judge-response-path="$DATASETS/prompt_injection_multilingual_judge_responses.json" \
          --stat-path="$DATASETS/prompt_injection_multilingual_stat.json" \
          --judge-llm="$SUPPORTER_LLM" \
          --llm-under-test="$LLM"
        RESULTS="$DATASETS/prompt_injection_multilingual_stat.json"
        python purplellama_eval.py "$RESULTS" "$HF_MODEL_NAME" "PI Multilingual"
        ;;
    esac
  done
  exit 0
fi

# Single benchmark mode
if [ "$BENCHMARK_NAME" == "mitre" ]; then
   echo "--- MITRE ---"
   run_benchmark \
      --benchmark=mitre \
      --prompt-path="${PROMPT_PATHS[0]}" \
      --response-path="$DATASETS/mitre_responses.json" \
      --judge-response-path="$DATASETS/mitre_judge_responses.json" \
      --stat-path="$DATASETS/mitre_stat.json" \
      --judge-llm="$SUPPORTER_LLM" \
      --expansion-llm="$SUPPORTER_LLM" \
      --llm-under-test="$LLM"
   RESULTS="$DATASETS/mitre_stat.json"
   python purplellama_eval.py $RESULTS $HF_MODEL_NAME "MITRE"

elif [ "$BENCHMARK_NAME" == "mitre-multilingual" ]; then
   echo "--- MITRE Multilingual ---"
   run_benchmark \
      --benchmark=mitre \
      --prompt-path="${PROMPT_PATHS[1]}" \
      --response-path="$DATASETS/mitre_responses.json" \
      --judge-response-path="$DATASETS/mitre_multilingual_judge_responses.json" \
      --stat-path="$DATASETS/mitre_multilingual_stat.json" \
      --judge-llm="$SUPPORTER_LLM" \
      --expansion-llm="$SUPPORTER_LLM" \
      --llm-under-test="$LLM"
   RESULTS="$DATASETS/mitre_multilingual_stat.json"
   python purplellama_eval.py $RESULTS $HF_MODEL_NAME "MITRE Multilingual"

elif [ "$BENCHMARK_NAME" == "frr" ]; then
   echo "--- False Refusal Rate (FRR) ---"
   run_benchmark \
      --benchmark=frr \
      --prompt-path="${PROMPT_PATHS[2]}" \
      --response-path="$DATASETS/frr_responses.json" \
      --stat-path="$DATASETS/frr_stat.json" \
      --llm-under-test="$LLM"
   RESULTS="$DATASETS/frr_stat.json"
   python purplellama_eval.py $RESULTS $HF_MODEL_NAME "FRR"

elif [ "$BENCHMARK_NAME" == "frr-multilingual" ]; then
   echo "--- False Refusal Rate (FRR) Multilingual ---"
   run_benchmark \
      --benchmark=frr \
      --prompt-path="${PROMPT_PATHS[3]}" \
      --response-path="$DATASETS/frr_multilingual_responses.json" \
      --stat-path="$DATASETS/frr_multilingual_stat.json" \
      --llm-under-test="$LLM"
   RESULTS="$DATASETS/frr_multilingual_stat.json"
   python purplellama_eval.py $RESULTS $HF_MODEL_NAME "FRR Multilingual"

elif [ "$BENCHMARK_NAME" == "pi" ]; then
   echo "--- Prompt Injection (PI) ---"
   run_benchmark \
      --benchmark=prompt-injection \
      --prompt-path="${PROMPT_PATHS[4]}" \
      --response-path="$DATASETS/prompt_injection/prompt_injection_responses.json" \
      --judge-response-path="$DATASETS/prompt_injection_judge_responses.json" \
      --stat-path="$DATASETS/prompt_injection_stat.json" \
      --judge-llm="$SUPPORTER_LLM" \
      --llm-under-test="$LLM"
   RESULTS="$DATASETS/prompt_injection_stat.json"
   python purplellama_eval.py $RESULTS $HF_MODEL_NAME "PI"

elif [ "$BENCHMARK_NAME" == "pi-multilingual" ]; then
   echo "--- Prompt Injection (PI) Multilingual ---"
   run_benchmark \
      --benchmark=prompt-injection \
      --prompt-path="${PROMPT_PATHS[5]}" \
      --response-path="$DATASETS/prompt_injection/prompt_injection_responses.json" \
      --judge-response-path="$DATASETS/prompt_injection_multilingual_judge_responses.json" \
      --stat-path="$DATASETS/prompt_injection_multilingual_stat.json" \
      --judge-llm="$SUPPORTER_LLM" \
      --llm-under-test="$LLM"
   RESULTS="$DATASETS/prompt_injection_multilingual_stat.json"
   python purplellama_eval.py $RESULTS $HF_MODEL_NAME "PI Multilingual"

else
   echo "Unknown benchmark: $BENCHMARK_NAME"
   exit 1
fi

# === Evaluation ===
# Done directly after running the benchmarks



