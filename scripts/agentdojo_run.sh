#!/bin/bash

# === CONFIGURATION ===
GPU_NAME="RTX A6000" #TODO brauch ich das wirklich?
HF_MODEL_NAME=$(grep -oP '"HF_MODEL_NAME"\s*:\s*"\K[^"]+' ../config.json)
SCRIPTS_DIR=$PWD
USER_DIR=$(grep -oP '"USER_DIR"\s*:\s*"\K[^"]+' ../config.json)
INSTALL_DIR=$(grep -oP '"INSTALL_DIR"\s*:\s*"\K[^"]+' ../config.json)
HF_TOKEN_FILE="$USER_DIR/.hf_token"
MINICONDA_PATH="$INSTALL_DIR/miniconda3"
HF_CACHE_DIR="$INSTALL_DIR/.huggingface_cache"
PIP_CACHE_DIR="$INSTALL_DIR/.cache"
CONDA_ENV_NAME="agentdojo"
REPO_URL="https://github.com/BambiMC/agentdojo-hf.git"
REPO_DIR="$INSTALL_DIR/agentdojo-hf"
PYTHON_VERSION="3.10"


set -e  # Stop if any command fails
trap 'echo "Error on line $LINENO: Command \"$BASH_COMMAND\" failed."' ERR


# === ENV VARIABLES ===
export CUDA_VISIBLE_DEVICES=$(nvidia-smi --query-gpu=index,name --format=csv,noheader | grep "$GPU_NAME" | cut -d',' -f1 | tr '\n' ',' | sed 's/,$//')
export HF_HOME="$HF_CACHE_DIR"
export PIP_CACHE_DIR="$PIP_CACHE_DIR"
export DATASETS="$INSTALL_DIR/CybersecurityBenchmarks/datasets"

mkdir -p "$HF_CACHE_DIR" "$PIP_CACHE_DIR"


# === Miniconda Setup ===
if ! command -v conda &> /dev/null; then
    if [[ ! -d "$MINICONDA_PATH" ]]; then
        echo "📦 Miniconda not found - installing..."
        mkdir -p ./tmp
        wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ./tmp/miniconda.sh
        bash ./tmp/miniconda.sh -b -p "$MINICONDA_PATH"
    fi
    export PATH="$MINICONDA_PATH/bin:$PATH"
    echo "Miniconda installed"
fi
eval "$(conda shell.bash hook)"

# === Huggingface Setup ===
HF_TOKEN=$(grep -oP '"HUGGINGFACE_API_KEY"\s*:\s*"\K[^"]+' ../config.json)
if [[ -n "$HF_TOKEN" ]]; then
    huggingface-cli login --token "$HF_TOKEN"
else
    echo "huggingface missing in config.json. Please add your token."
    exit 1
fi

# === OpenAI Setup ===
OPENAI_TOKEN=$(grep -oP '"OPENAI_API_KEY"\s*:\s*"\K[^"]+' ../config.json)
if [[ -n "$OPENAI_TOKEN" ]]; then
    export OPENAI_API_KEY="$OPENAI_TOKEN"
else
    echo "OpenAI token missing in config.json. Please add your token."
    exit 1
fi

# === Create Conda Environment ===
if ! conda info --envs | grep -q "$CONDA_ENV_NAME"; then
    echo "Create Conda environment $CONDA_ENV_NAME with Python $PYTHON_VERSION..."
    conda create -y -n "$CONDA_ENV_NAME" python="$PYTHON_VERSION"
fi
conda activate "$CONDA_ENV_NAME"

# === Clone Repository and build agentdojo-hf ===
if [[ ! -d "$REPO_DIR" ]]; then
    git clone "$REPO_URL" "$REPO_DIR"
fi
cd "$REPO_DIR"
git reset --hard HEAD # Otherwise the template will not be there to be updated, if the benchmark is run multiple times


# Modify ModelsEnum.py to include HF_MODEL_NAME
python modify_ModelsEnum.py "$HF_MODEL_NAME"


# === Install Requirements ===
pip install build
python -m build
WHEEL_FILE=$(ls dist/agentdojo-*-py3-none-any.whl | tail -n 1)
pip install "$WHEEL_FILE" --force-reinstall


# === Modify HF_MODEL_NAME to support ModelsEnum ===
HF_MODEL_NAME_ENUM=$(echo "$HF_MODEL_NAME" | sed -E 's/[-\/\.]/_/g' | tr '[:lower:]' '[:upper:]')
echo "Using HF_MODEL_NAME_ENUM: $HF_MODEL_NAME_ENUM"

# === Run Benchmark ===
AVG_UTILITY=$(python -m agentdojo.scripts.benchmark -s workspace --model "$HF_MODEL_NAME_ENUM" | grep "Average utility" | awk -F ':' '{print $2}' | xargs)


# === Evaluate results ===
cd "$SCRIPTS_DIR"
python agentdojo_eval.py $AVG_UTILITY $HF_MODEL_NAME





# TODO --attack

# Ich sollte nur suites angeben

# --user-task, if not given -> all tasks in suite are run
# --injection-task, if not given -> ?


# TODO alle suites machen?:
    # workspace
    # banking
    # slack
    # travel


#all attacks:
#     manual
# baseline_attacks:
#     direct
#     ignore_previous
#     system_message
#     injecagent
# dos_attacks:
#     dos
#     swearwords_dos
#     captcha_dos
#     offensive_email_dos
#     felony_dos
# important_instruction_attacks:
#     important_instructions
#     important_instructions_no_user_name
#     important_instructions_no_model_name
#     important_instructions_no_names
#     important_instructions_wrong_model_name
#     important_instructions_wrong_user_name
#     tool_knowledge




#TODO bei allen die git pull festsetzen, damit neue Commits das Benchmark nicht kaputt machen