# Usage: bash batch_benchmarks.sh jailbreakscan

HF_MODEL_NAMES=(
        google/gemma-3-12b-it
        microsoft/phi-4
        CohereLabs/c4ai-command-a-03-2025
        meta-llama/Llama-3.3-70B-Instruct
        anthracite-core/Mistral-Small-3.1-24B-Instruct-2503-HF
        Qwen/Qwen3-32B
        zai-org/GLM-4-32B-0414
        openai/gpt-oss-20b
)

testing=true
task="$1"
if [ -z "$task" ]; then
  echo "Usage: $0 <task>"
  
  exit 1
fi

for model in "${HF_MODEL_NAMES[@]}"; do
  if [ "$testing" = true ]; then
    bash run_benchmarks.sh --model "$model" --task "$task" --timeout 30m
  else
    bash run_benchmarks.sh --model "$model" --task "$task"
  fi
done