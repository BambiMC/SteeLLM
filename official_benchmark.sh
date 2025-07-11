#TODO fill in the different benchmarks with the corresponding parameters for official benchmark.
#!/bin/bash

cd scripts

CENTRALIZED_LOGGING=$(grep -oP '"CENTRALIZED_LOGGING"\s*:\s*"\K[^"]+' ../config.json)


if [[ "$1" == "true" || "$1" == "1" ]]; then
    echo "Do something because argument is true"
else
    echo "Do something else (argument is false, undefined, or empty)"
fi

echo "START OF AUTODAN"
bash autodan_run.sh $CENTRALIZED_LOGGING
echo "START OF AUTODAN-TURBO"
bash autodan-turbo_run.sh $CENTRALIZED_LOGGING
echo "START OF AGENTDOJO"
bash agentdojo_run.sh $CENTRALIZED_LOGGING
echo "START OF BACKDOORLLM"
bash backdoorllm_run.sh $CENTRALIZED_LOGGING
echo "START OF OPENPROMPTINJECTION"
bash openpromptinjection_run.sh $CENTRALIZED_LOGGING
echo "START OF PURPLELLAMA"
bash purplellama_run.sh $CENTRALIZED_LOGGING


