# timeout 90m bash run_benchmarks.sh --model "zai-org/GLM-4-32B-0414" --task jailbreakbench
# timeout 45m bash run_benchmarks.sh --model "openai/gpt-oss-20b" --task openpromptinjection

bash run_benchmarks.sh --model "openai/gpt-oss-20b" --task jailbreakbench

bash run_benchmarks.sh --model "google/gemma-3-12b-it" --task openpromptinjection
bash run_benchmarks.sh --model "Qwen/Qwen3-32B" --task openpromptinjection