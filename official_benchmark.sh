#TODO fill in the different benchmarks with the corresponding parameters for official benchmark.
#!/bin/bash

cd scripts
bash autodan_run.sh
bash autodan-turbo_run.sh
bash agentdojo_run.sh
bash backdoorLLM_run.sh
bash purplellama_run.sh