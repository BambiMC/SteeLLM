timeout 90m bash run_benchmarks.sh --model "google/gemma-3-12b-it" --task jailbreakbench
timeout 35m bash run_benchmarks.sh --model "microsoft/phi-4" --task jailbreakbench
timeout 300m bash run_benchmarks.sh --model "CohereLabs/c4ai-command-a-03-2025" --task jailbreakbench
timeout 150m bash run_benchmarks.sh --model "meta-llama/Llama-3.3-70B-Instruct" --task jailbreakbench
timeout 70m bash run_benchmarks.sh --model "anthracite-core/Mistral-Small-3.1-24B-Instruct-2503-HF" --task jailbreakbench
timeout 90m bash run_benchmarks.sh --model "Qwen/Qwen3-32B" --task jailbreakbench
timeout 45m bash run_benchmarks.sh --model "zai-org/GLM-4-32B-0414" --task jailbreakbench
timeout 25m bash run_benchmarks.sh --model "openai/gpt-oss-20b" --task jailbreakbench
