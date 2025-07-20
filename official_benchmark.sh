#!/bin/bash

START_TIME=$(date +%s)
TIMESTAMP=$(date -d "+2 hours" +"%d%m%y_%H%M")

HF_MODEL_NAME=$(grep -oP '"HF_MODEL_NAME"\s*:\s*"\K[^"]+' config.json)
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

cd scripts

# echo "START OF AGENTDOJO"
# bash agentdojo_run.sh

# echo "START OF AUTODAN"
# bash autodan_run.sh

# echo "START OF AUTODAN-TURBO"
# bash autodan-turbo_run.sh

# echo "START OF BACKDOORLLM"
# bash backdoorllm_run.sh

echo "START OF JAILBREAKBENCH"
bash jailbreakbench_run.sh

echo "START OF HARMBENCH"
bash harmbench_run.sh

echo "START OF LLM-ATTACKS"
bash llm-attacks_run.sh

# echo "START OF OPENPROMPTINJECTION"
# bash openpromptinjection_run.sh

echo "START OF PERSUASIVE JAILBREAKER" 
bash persuasive-jailbreaker_run.sh

# echo "START OF PURPLELLAMA"
# bash purplellama_run.sh

echo "START OF TAP"
bash tap_run.sh


# End time
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Format duration as H:M:S
HOURS=$((DURATION / 3600))
MINUTES=$(( (DURATION % 3600) / 60 ))
SECONDS=$((DURATION % 60))

echo "Script execution finished. Full log saved to $LOG_FILE"
echo "End Time: $(date +"%Y-%m-%d %H:%M:%S")"
echo "Total Duration: ${HOURS}h ${MINUTES}m ${SECONDS}s"