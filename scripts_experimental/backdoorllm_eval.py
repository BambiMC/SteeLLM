import json
import sys
import os
import pathlib
import datetime
import re

RESULTS = sys.argv[1]
HF_MODEL_NAME = sys.argv[2] 
CENTRALIZED_LOGGING = json.loads(pathlib.Path("../config.json").read_text()).get("CENTRALIZED_LOGGING")
BENCHMARK_NAME = "BackdoorLLM"



success = 0
tries = 0

with open(RESULTS, 'r') as f:
    for line in f:
        # find line that contains ASR
        if "ASR" in line:
            # Extract the ASR value using regex
            match = re.search(r'ASR_scores":\s*([\d.]+)', line)
            if match:
                asr_value = float(match.group(1))
                print(f"ASR: {asr_value}")
                success += asr_value
                tries += 1

metrics = [f"ASR: {success}"]

current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
header = [
    f"--- {BENCHMARK_NAME} - Metrics Recorded at {current_time} for model: {HF_MODEL_NAME} ---"
]
footer = [
    f"--- End of Metrics ---"
]
metrics = header + metrics + footer
print("Metrics:\n" + "\n".join(metrics))


file_path = os.path.dirname(os.path.abspath(__file__)) + "/backdoorllm_results.txt"
if CENTRALIZED_LOGGING == True:
    file_path = os.path.dirname(os.path.dirname(os.path.abspath(__file__))) + "/centralized_results.txt"

print(f"Writing results to {file_path}")
if not os.path.exists(file_path):
    with open(file_path, "w") as file:
        file.write("\n")
        file.write("\n".join(metrics) + "\n")
else:
    with open(file_path, "a") as file:
        file.write("\n")
        file.write("\n".join(metrics) + "\n")