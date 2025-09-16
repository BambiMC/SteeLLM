timeout 30m bash run_benchmarks.sh --model "google/gemma-3-270m" --task jailbreakscan
timeout 30m bash run_benchmarks.sh --model "google/gemma-3-270m" --task openpromptinjection
timeout 30m bash run_benchmarks.sh --model "google/gemma-3-270m" --task jailbreakbench