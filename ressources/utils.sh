#!/usr/bin/env bash
# ============================================================
# AgentDojo utility functions — source this from any script.
# ============================================================
set -euo pipefail

# Usage: parse_config
parse_config () {
    export HF_MODEL_NAME=$(grep -oP '"HF_MODEL_NAME"\s*:\s*"\K[^"]+' ../config.json)
    export USER_DIR=$(grep -oP '"USER_DIR"\s*:\s*"\K[^"]+' ../config.json)
    export INSTALL_DIR=$(grep -oP '"INSTALL_DIR"\s*:\s*"\K[^"]+' ../config.json)
    export SCRIPTS_DIR=$PWD/../scripts # evtl. brauche ich das gar nicht, weil das in den Skripten schon gesetzt wird?
    export HUGGINGFACE_API_KEY=$(grep -oP '"HUGGINGFACE_API_KEY"\s*:\s*"\K[^"]+' ../config.json)
    export OPENAI_API_KEY=$(grep -oP '"OPENAI_API_KEY"\s*:\s*"\K[^"]+' ../config.json)
    export DEEPSEEK_API_KEY=$(grep -oP '"DEEPSEEK_API_KEY"\s*:\s*"\K[^"]+' ../config.json)
    export GOOGLE_API_KEY=$(grep -oP '"GOOGLE_API_KEY"\s*:\s*"\K[^"]+' ../config.json)
    export WANDB_API_KEY=$(grep -oP '"WANDB_API_KEY"\s*:\s*"\K[^"]+' ../config.json)
    export CENTRALIZED_LOGGING=$(grep -oP '"CENTRALIZED_LOGGING"\s*:\s*"\K[^"]+' ../config.json)

    export HF_CACHE_DIR="$INSTALL_DIR/.huggingface_cache"
    export PIP_CACHE_DIR="$INSTALL_DIR/.cache"
    export MINICONDA_PATH="$INSTALL_DIR/miniconda3"

    mkdir -p "$HF_CACHE_DIR" "$PIP_CACHE_DIR"

}

# Usage: ensure_miniconda <install_dir>
ensure_miniconda () {
    pip install --upgrade pip
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
        git clone "$REPO_URL" "$REPO_DIR"
        cd "$REPO_DIR"
    else
        cd "$REPO_DIR"
        git pull --force
    fi
}


# ---------- Third party provider logins ------------------
# Usage: hf_login
hf_login ()    { 
    cd $SCRIPTS_DIR
    #TODO hat das funktioniert?, dann noch die anderen TOKEN auch exporten
    export HF_TOKEN=$(grep -oP '"HUGGINGFACE_API_KEY"\s*:\s*"\K[^"]+' ../config.json)
    if [[ -n "$HF_TOKEN" ]]; then
        huggingface-cli login --token "$HF_TOKEN"
    else
        echo "huggingface missing in config.json. Please add your token."
        exit 1
    fi
}
# Usage: openai_login
openai_login (){ 
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