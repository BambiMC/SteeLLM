timeout 30m bash run_benchmarks.sh --model "google/gemma-3-12b-it" --task openpromptinjection
timeout 20m bash run_benchmarks.sh --model "microsoft/phi-4" --task openpromptinjection
timeout 80m bash run_benchmarks.sh --model "CohereLabs/c4ai-command-a-03-2025" --task openpromptinjection
timeout 40m bash run_benchmarks.sh --model "meta-llama/Llama-3.3-70B-Instruct" --task openpromptinjection
timeout 30m bash run_benchmarks.sh --model "anthracite-core/Mistral-Small-3.1-24B-Instruct-2503-HF" --task openpromptinjection
timeout 35m bash run_benchmarks.sh --model "Qwen/Qwen3-32B" --task openpromptinjection
timeout 25m bash run_benchmarks.sh --model "zai-org/GLM-4-32B-0414" --task openpromptinjection
timeout 20m bash run_benchmarks.sh --model "openai/gpt-oss-20b" --task openpromptinjection
