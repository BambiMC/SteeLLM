#!/usr/bin/env bash
set -eo pipefail
trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND"' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../ressources/utils.sh"

parse_config "$1"

# === CONFIGURATION ===
CONDA_ENV_NAME="downloadmodels"
PYTHON_VERSION="3.10"


ensure_miniconda "$INSTALL_DIR"
# clone_repo
ensure_conda_env "$CONDA_ENV_NAME" "$PYTHON_VERSION"

# === Install Requirements ===
pip install huggingface_hub

# === Environment Variables ===

hf_login


# Downloads all models specified
echo "Downloading all models specified"

HF_MODEL_NAMES=(
        # google/gemma-3-12b-it
        # microsoft/phi-4
        # CohereLabs/c4ai-command-a-03-2025
        meta-llama/Llama-3.3-70B-Instruct
        # anthracite-core/Mistral-Small-3.1-24B-Instruct-2503-HF
        # Qwen/Qwen3-32B
        # zai-org/GLM-4-32B-0414
        # openai/gpt-oss-20b
)

for model in "${HF_MODEL_NAMES[@]}"; do
    hf download "$model"
done


# === Evaluation ===