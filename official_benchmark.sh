#TODO fill in the different benchmarks with the corresponding parameters for official benchmark.
#!/bin/bash

HF_MODEL_NAME="meta-llama/Llama-2-7b-chat-hf"

cd scripts
bash run_autodan.sh $HF_MODEL_NAME
