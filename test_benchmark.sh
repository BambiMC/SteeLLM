#!/bin/bash

START_TIME=$(date +%s)
TIMESTAMP=$(date -d "+2 hours" +"%d%m%y_%H%M")



HF_MODEL_NAMES=$(sed -n '/"HF_MODEL_NAMES"\s*:/,/]/p' config.json \
    | grep -oP '"[^"]+"' \
    | tail -n +2 \
    | tr -d '"' \
    | paste -sd ',' -)


# Convert comma-separated model names into array
IFS=',' read -ra MODELS <<< "$HF_MODEL_NAMES"


# Split at /
# IFS='/' read -ra MODEL_NAME_PARTS <<< "$HF_MODEL_NAME"
# HF_MODEL_NAME="${MODEL_NAME_PARTS[-1]}" 
LOG_FILE="logs/log_${TIMESTAMP}_N_Models.txt"

mkdir -p logs "$(dirname "$LOG_FILE")"
exec > >(tee -a "$LOG_FILE") 2>&1



CENTRALIZED_LOGGING=$(grep -oP '"CENTRALIZED_LOGGING"\s*:\s*\K(true|false)' config.json)
if [ "$CENTRALIZED_LOGGING" = "true" ]; then
    echo "-------------------------------------------------------------------------------------" >> centralized_results.txt
fi

cd scripts

# Iterate over models
for model in "${MODELS[@]}"; do
    echo "Processing model: $model"
    export HF_MODEL_NAME="$model"


    # printf "\nSTART OF AGENTDOJO\n"
    # # bash agentdojo_run.sh
    # timeout 5m bash agentdojo_run.sh

    # printf "\nSTART OF AUTODAN\n"
    # # bash autodan_run.sh
    # timeout 5m bash autodan_run.sh

    # printf "\nSTART OF AUTODAN-TURBO\n"
    # # bash autodan-turbo_run.sh
    # timeout 5m bash autodan-turbo_run.sh

    # printf "\nSTART OF BACKDOORLLM\n"
    # # bash backdoorllm_run.sh
    # timeout 5m bash backdoorllm_run.sh

    # printf "\nSTART OF BadChain\n"
    # # bash badchain_run.sh
    # timeout 5m bash badchain_run.sh
    # # Funktioniert und berechnet die Metriken am Ende, gibts auf der Commandline oder in log_300725_1041

    # printf "\nSTART OF HARMBENCH\n"
    # # bash harmbench_run.sh
    # timeout 5m bash harmbench_run.sh

    # printf "\nSTART OF JAILBREAKBENCH\n"
    # # bash jailbreakbench_run.sh
    # timeout 5m bash jailbreakbench_run.sh
    # #TODO bin ich noch dabei zu verbessern

    printf "\nSTART OF JAILBREAKSCAN\n"
    # bash jailbreakscan_run.sh
    timeout 1m bash jailbreakscan_run.sh

    # printf "\nSTART OF LLM-ATTACKS\n"
    # # bash llm-attacks_run.sh
    # timeout 5m bash llm-attacks_run.sh

    # printf "\nSTART OF MasterKey\n"
    # # bash masterkey_run.sh
    # timeout 5m bash masterkey_run.sh
    # # Funktioniert, muss nur noch die results.txt in die metrics einfügen, also ne _eval bauen

    # printf "\nSTART OF MJP\n"
    # # bash mjp_run.sh
    # timeout 5m bash mjp_run.sh
    # # Die ersten 15 Minuten laufen gut durch

    # printf "\nSTART OF OPENPROMPTINJECTION\n"
    # timeout 5m bash openpromptinjection_run.sh

    # printf "\nSTART OF PURPLELLAMA\n"
    # timeout 5m bash purplellama_run.sh



    #Überkategorie
    #TODO Jailbreaking: MJP ( Multi-step Jailbreaking Prompt), XXXJailbrokenXXX, MasterKey, XXXDeepInjectionXXX, RLJack -> deleted
    #TODO Backdoor: BadPrompt, ProAttack -> Kein Code, BadGPT, BadAgent, BadChain
    #TODO Data Poisoning: TrojLLM, TrojanPuzzle, Agentpoison, You autocomplete me -> Kein Code, Nightshade, Codebreaker


    #Privacy Attacks:
    #TODO Gradient Leakage: TAG, LAMP, GDBA
    #TODO Membership Inference: MIA-ML, MIA on PLM, PREMIA, SaMIA
    #TODO PII Leakage: TAB, ProPILE, PII Compass, Memorization, KART

    #Überkategorie:


    # TODO Im ma.tex stehen noch mehr drin
    # End time
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    # Format duration as H:M:S
    HOURS=$((DURATION / 3600))
    MINUTES=$(( (DURATION % 3600) / 60 ))
    SECONDS=$((DURATION % 60))

    printf "Script execution finished. Full log saved to $LOG_FILE"
    printf "End Time: $(date +"%Y-%m-%d %H:%M:%S")"
    printf "Total Duration: ${HOURS}h ${MINUTES}m ${SECONDS}s"


done