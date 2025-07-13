#!/usr/bin/env bash
# ============================================================
# AgentDojo utility functions — source this from any script.
# ============================================================
set -euo pipefail

# ---------- 1. Parse config ---------------------------------
# Usage: parse_config path/to/config.json
parse_config () {
    local CFG="$1"

    # 📝 Requires jq (apt install jq). If you can’t install jq,
    #   fall back to grep like in your original script instead.
    export HF_MODEL_NAME=$(jq -r '.HF_MODEL_NAME'         "$CFG")
    export USER_DIR=$(jq -r '.USER_DIR'                   "$CFG")
    export INSTALL_DIR=$(jq -r '.INSTALL_DIR'             "$CFG")
    export HUGGINGFACE_API_KEY=$(jq -r '.HUGGINGFACE_API_KEY' "$CFG")
    export OPENAI_API_KEY=$(jq -r '.OPENAI_API_KEY'           "$CFG")
}

# ---------- 2. Miniconda bootstrap --------------------------
# Usage: ensure_miniconda <install_dir>
ensure_miniconda () {
    local INSTALL_DIR="$1"
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

# ---------- 3. Hugging Face / OpenAI login ------------------
hf_login ()    { echo "$HUGGINGFACE_API_KEY" | huggingface-cli login --token $(cat); }
openai_login (){ export OPENAI_API_KEY="$OPENAI_API_KEY"; }

# ---------- 4. Conda env ------------------------------------
# Usage: ensure_conda_env <name> <python_version>
ensure_conda_env () {
    local NAME="$1" PY="$2"
    conda info --envs | grep -q "^$NAME" || conda create -y -n "$NAME" python="$PY"
    conda activate "$NAME"
}

# ---------- 5. Clone & build agentdojo‑hf -------------------
# Usage: clone_and_build <repo_url> <repo_dir>
clone_and_build () {
    local URL="$1" DIR="$2"

    [[ -d "$DIR" ]] || git clone --quiet "$URL" "$DIR"
    pushd "$DIR" >/dev/null
        git reset --hard HEAD
        python modify_ModelsEnum.py "$HF_MODEL_NAME"
        pip install build >/dev/null
        python -m build >/dev/null
        local WHEEL=$(ls dist/agentdojo-*-py3-none-any.whl | tail -n1)
        pip install "$WHEEL" --force-reinstall
    popd >/dev/null
}

# ---------- 6. Run benchmark --------------------------------
# Usage: run_benchmark <repo_dir> <model_enum>
run_benchmark () {
    local DIR="$1" MODEL="$2"
    python -m agentdojo.scripts.benchmark -s workspace --model "$MODEL" |
        awk -F':' '/Average utility/{gsub("[[:space:]]","",$2);print $2}'
}

# ---------- 7. Utility: model name → enum -------------------
model_to_enum () {
    local raw="$1"
    echo "$raw" | sed -E 's/[-\/]/_/g' | tr '[:lower:]' '[:upper:]'
}

# ----- Execution guard: do nothing when sourced -------------
return 0 2>/dev/null || true