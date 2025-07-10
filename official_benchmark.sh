#TODO fill in the different benchmarks with the corresponding parameters for official benchmark.
#!/bin/bash

cd scripts
echo "START OF AUTODAN"
bash autodan_run.sh
echo "START OF AUTODAN-TURBO"
bash autodan-turbo_run.sh
echo "START OF AGENTDOJO"
bash agentdojo_run.sh
echo "START OF BACKDOORLLM"
bash backdoorllm_run.sh
echo "START OF OPENPROMPTINJECTION"
bash openpromptinjection_run.sh
echo "START OF PURPLELLAMA"
bash purplellama_run.sh