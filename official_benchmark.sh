#!/bin/bash

# Define the log file name
LOG_FILE="log.txt"

# Redirect all subsequent output (stdout and stderr) to the log file
exec > >(tee -a "$LOG_FILE") 2>&1

CENTRALIZED_LOGGING=$(grep -oP '"CENTRALIZED_LOGGING"\s*:\s*\K(true|false)' config.json)

if [ "$CENTRALIZED_LOGGING" = "true" ]; then
    echo "-------------------------------------------------------------------------------------" >> centralized_results.txt
fi

cd scripts

echo "START OF AGENTDOJO"
bash agentdojo_run.sh
echo "START OF AUTODAN"
bash autodan_run.sh
echo "START OF AUTODAN-TURBO"
bash autodan-turbo_run.sh
echo "START OF BACKDOORLLM"
bash backdoorllm_run.sh
echo "START OF OPENPROMPTINJECTION"
bash openpromptinjection_run.sh
echo "START OF PURPLELLAMA"
bash purplellama_run.sh

echo "Script execution finished. Full log saved to $LOG_FILE"