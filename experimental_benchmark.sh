#!/bin/bash

START_TIME=$(date +%s)
TIMESTAMP=$(date -d "+2 hours" +"%d%m%y_%H%M")

export HF_MODEL_NAME=$(grep -oP '"HF_MODEL_NAME"\s*:\s*"\K[^"]+' config.json)
# Split at /
IFS='/' read -ra MODEL_NAME_PARTS <<< "$HF_MODEL_NAME"
HF_MODEL_NAME="${MODEL_NAME_PARTS[-1]}" 
LOG_FILE="logs/log_${TIMESTAMP}_${HF_MODEL_NAME}.txt"

mkdir -p logs "$(dirname "$LOG_FILE")"
exec > >(tee -a "$LOG_FILE") 2>&1


CENTRALIZED_LOGGING=$(grep -oP '"CENTRALIZED_LOGGING"\s*:\s*\K(true|false)' config.json)




if [ "$CENTRALIZED_LOGGING" = "true" ]; then
    echo "-------------------------------------------------------------------------------------" >> centralized_results.txt
fi

cd scripts_experimental

# printf "\nSTART OF AgentPoison\n"
# bash agentpoison_run.sh
# timeout 15m bash agentpoison_run.sh
# FileNotFoundError: [Errno 2] No such file or directory: 'data/memory/database.pkl'
# Error on line 71: sh scripts/agent_driver/run_inference.sh

# printf "\nSTART OF BadAgent\n"
# # bash badagent_run.sh
# timeout 15m bash badagent_run.sh



# printf "\nSTART OF BadGPT\n"
# # bash badgpt_run.sh
# timeout 15m bash badgpt_run.sh

# printf "\nSTART OF BadPrompt\n"
# bash badprompt_run.sh
# timeout 15m bash badprompt_run.sh
# 3 Jahre alt, zu alte Huggingface_hub library, funktioniert nicht mehr
#TODO könnte es nochmal mit hf auth login versuchen

# printf "\nSTART OF CodeBreaker\n"
# # bash codebreaker_run.sh
# timeout 15m bash codebreaker_run.sh

# printf "\nSTART OF DeepEval\n"
# # bash deepeval_run.sh
# timeout 15m bash deepeval_run.sh


# printf "\nSTART OF TAP\n"
# timeout 15m bash tap_run.sh
# Läuft durch, bringt aber keine Ergebnisse


# printf "\nSTART OF Nightshade\n"
# # bash nightshade_run.sh
# timeout 15m bash nightshade_run.sh

# printf "\nSTART OF TrojanPuzzle\n"
# # bash trojanpuzzle_run.sh
# timeout 15m bash trojanpuzzle_run.sh

# printf "\nSTART OF TrojLLM\n"
# # bash trojllm_run.sh
# timeout 15m bash trojllm_run.sh


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