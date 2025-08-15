#!/usr/bin/env bash
set -eo pipefail

# Usage: benchmark_setup
benchmark_setup() {

    START_TIME=$(date +%s)
    TIMESTAMP=$(date -d "+2 hours" +"%y%m%d_%H%M")

    if [ -n "${1:-}" ]; then
        HF_MODEL_NAME="$1"
    else
        HF_MODEL_NAME=$(grep -oP '"HF_MODEL_NAME"\s*:\s*"\K[^"]+' config.json)
    fi
    export HF_MODEL_NAME

    TASK_TO_RUN="$2"

    # Split at /
    IFS='/' read -ra MODEL_NAME_PARTS <<< "$HF_MODEL_NAME"
    HF_MODEL_NAME_WITHOUT_PROVIDER="${MODEL_NAME_PARTS[-1]}" 
    LOG_FILE="logs/log_${TIMESTAMP}_${HF_MODEL_NAME_WITHOUT_PROVIDER}_${TASK_TO_RUN}.txt"

    mkdir -p logs "$(dirname "$LOG_FILE")"
    exec > >(tee -a "$LOG_FILE") 2>&1

    CENTRALIZED_LOGGING=$(grep -oP '"CENTRALIZED_LOGGING"\s*:\s*\K(true|false)' config.json)

    if [ "$CENTRALIZED_LOGGING" = "true" ]; then
        echo "-------------------------------------------------------------------------------------" >> centralized_results.txt
    fi

}

# Usage: benchmark_teardown
benchmark_teardown() {

    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    # Format duration as H:M:S
    HOURS=$((DURATION / 3600))
    MINUTES=$(( (DURATION % 3600) / 60 ))
    SECONDS=$((DURATION % 60))

    printf "Script execution finished. Full log saved to $LOG_FILE"
    printf "End Time: $(date +"%Y-%m-%d %H:%M:%S")"
    printf "Total Duration: ${HOURS}h ${MINUTES}m ${SECONDS}s"

}

# Usage: parse_config
parse_config () {

    # If not called via benchmark, but directly:
    if [ -n "${1:-}" ]; then
        HF_MODEL_NAME="$1"
    else
        HF_MODEL_NAME=$(grep -oP '"HF_MODEL_NAME"\s*:\s*"\K[^"]+' ../config.json)
    fi
    export HF_MODEL_NAME

    export USER_DIR=$(grep -oP '"USER_DIR"\s*:\s*"\K[^"]+' ../config.json)
    export INSTALL_DIR=$(grep -oP '"INSTALL_DIR"\s*:\s*"\K[^"]+' ../config.json)
    export SCRIPTS_DIR=$PWD/../scripts

    export HUGGINGFACE_API_KEY=$(grep -oP '"HUGGINGFACE_API_KEY"\s*:\s*"\K[^"]+' ../config.json)
    export OPENAI_API_KEY=$(grep -oP '"OPENAI_API_KEY"\s*:\s*"\K[^"]+' ../config.json)
    export DEEPSEEK_API_KEY=$(grep -oP '"DEEPSEEK_API_KEY"\s*:\s*"\K[^"]+' ../config.json)
    export GOOGLE_API_KEY=$(grep -oP '"GOOGLE_API_KEY"\s*:\s*"\K[^"]+' ../config.json)
    export WANDB_API_KEY=$(grep -oP '"WANDB_API_KEY"\s*:\s*"\K[^"]+' ../config.json)

    export CENTRALIZED_LOGGING=$(grep -oP '"CENTRALIZED_LOGGING"\s*:\s*"\K[^"]+' ../config.json)

    export HF_CACHE_DIR="$INSTALL_DIR/.huggingface_cache"
    export HF_HOME="$HF_CACHE_DIR"

    export PIP_CACHE_DIR="$INSTALL_DIR/.cache"
    export MINICONDA_PATH="$INSTALL_DIR/miniconda3"

    mkdir -p "$HF_CACHE_DIR" "$PIP_CACHE_DIR"
}

# Usage: ensure_miniconda <install_dir>
ensure_miniconda () {
    pip install --upgrade pip | grep -v -E '(Requirement already satisfied|Using cached|Attempting uninstall|Collecting|Found existing installation|Successfully|)' || true
    # conda update -n base -c defaults conda # Does not work in my environment
    
    local CONDA_HOME="$INSTALL_DIR/miniconda3"

    if ! command -v conda &>/dev/null; then
        if [[ ! -d "$CONDA_HOME" ]]; then
            echo "📦 Installing Miniconda in $CONDA_HOME ..."
            mkdir -p "$INSTALL_DIR/tmp"
            wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
                 -O "$INSTALL_DIR/tmp/miniconda.sh"
            bash "$INSTALL_DIR/tmp/miniconda.sh" -b -p "$CONDA_HOME"
        fi
        export PATH="$CONDA_HOME/bin:$PATH"
    fi
    eval "$(conda shell.bash hook)"

    # Accepting the license agreement for all conda channels
    # for channel in \
    # https://repo.anaconda.com/pkgs/main \
    # https://repo.anaconda.com/pkgs/r \
    # https://repo.anaconda.com/pkgs/msys2; do
    #     conda tos accept --override-channels --channel $channel
    # done
}

# Usage: ensure_conda_env <name> <python_version>
ensure_conda_env () {
    local NAME="$1" PY="$2"
    conda info --envs | grep -q "^$NAME" || conda create -y -n "$NAME" python="$PY"
    conda activate "$NAME"
}

# Usage: clone_repo
clone_repo () {
    if [[ ! -d "$REPO_DIR" ]]; then
        echo "Cloning repository from $REPO_URL to $REPO_DIR ..."
        git clone "$REPO_URL" "$REPO_DIR"
        cd "$REPO_DIR"
    else
        cd "$REPO_DIR"
        echo "Repository already exists, pulling latest changes..."
        git pull --force
    fi
}

# Usage: set_cuda_device_order_and_visible_devices <gpu_name>
set_cuda_device_order_and_visible_devices() {
    local GPU_NAME="$1"
    export CUDA_DEVICE_ORDER=PCI_BUS_ID

    GPU_ID=$(nvidia-smi --query-gpu=name,index --format=csv,noheader | \
            grep "$GPU_NAME" | awk -F',' '{print $2}' | xargs)

    if [[ -n "$GPU_ID" ]]; then
        export CUDA_VISIBLE_DEVICES="$GPU_ID"
        echo "Set CUDA_VISIBLE_DEVICES=$CUDA_VISIBLE_DEVICES ($GPU_NAME)"
    else
        echo "$GPU_NAME not found!"
    fi
}


# ---------- Third party provider logins ------------------
# Usage: hf_login
hf_login ()    { 
    cd $SCRIPTS_DIR
    export HF_TOKEN=$(grep -oP '"HUGGINGFACE_API_KEY"\s*:\s*"\K[^"]+' ../config.json)
    if [[ -n "$HF_TOKEN" ]]; then
        # huggingface-cli login --token "$HF_TOKEN" | grep -v -E '(The token has not been saved)' || true
        hf auth login --token "$HF_TOKEN" |& grep -v "The token has not been saved" || true
    else
        echo "huggingface missing in config.json. Please add your token."
        exit 1
    fi
}

# Usage: old_hf_login
old_hf_login () {
    cd $SCRIPTS_DIR
    export HF_TOKEN=$(grep -oP '"HUGGINGFACE_API_KEY"\s*:\s*"\K[^"]+' ../config.json)
    export HUGGINGFACE_HUB_TOKEN=HF_TOKEN
}



# Usage: openai_login
openai_login () { 
    cd $SCRIPTS_DIR
    OPENAI_TOKEN=$(grep -oP '"OPENAI_API_KEY"\s*:\s*"\K[^"]+' ../config.json)
    if [[ -n "$OPENAI_TOKEN" ]]; then
        export OPENAI_API_KEY="$OPENAI_TOKEN"
    else
        echo "OpenAI token missing in config.json. Please add your token."
        exit 1
    fi
}

# Usage: deepseek_login
deepseek_login() {
    cd $SCRIPTS_DIR
    DEEPSEEK_TOKEN=$(grep -oP '"DEEPSEEK_API_KEY"\s*:\s*"\K[^"]+' ../config.json)
    if [[ -z "$DEEPSEEK_TOKEN" ]]; then
        echo "DeepSeek token missing in config.json. Please add your token."
        exit 1
    fi
}

#Usage: wandb_login
wandb_login() {
    cd $SCRIPTS_DIR
    WANDB_TOKEN=$(grep -oP '"WANDB_API_KEY"\s*:\s*"\K[^"]+' ../config.json)
    if [[ -n "$WANDB_TOKEN" ]]; then
        wandb login "$WANDB_TOKEN"
        export WANDB_API_KEY="$WANDB_TOKEN"
    else
        echo "WANDB token missing in config.json. Please add your token."
        exit 1
    fi
}

# ----- Execution guard: do nothing when sourced -------------
return 0 2>/dev/null || true