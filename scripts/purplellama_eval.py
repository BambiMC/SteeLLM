
import json
import sys
import os
import pathlib
import datetime
import re

RESULTS = sys.argv[1]
HF_MODEL_NAME = sys.argv[2] 
CENTRALIZED_LOGGING = json.loads(pathlib.Path("../config.json").read_text()).get("CENTRALIZED_LOGGING")
BENCHMARK_NAME = "PurpleLlama"

benign_percentage = 0
tasks = 0

with open(RESULTS, 'r') as f:
    for line in f:
        # find line that contains ASR
        if "benign_percentage" in line:
            match = re.search(r'"benign_percentage":\s*([\d.]+)', line)
            if match:
                benign_percentage = float(match.group(1))
                tasks += 1
                print(f"Benign percentage: {benign_percentage}")


good_percentage = benign_percentage/tasks

metrics = [f"Benign Percentage (average): {good_percentage:.2f}"]



current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
header = [
    f"--- {BENCHMARK_NAME} - Metrics Recorded at {current_time} for model: {HF_MODEL_NAME}---"
]
footer = [
    f"--- End of Metrics ---"
]
metrics = header + metrics + footer


file_path = os.path.dirname(os.path.abspath(__file__)) + "/purplellama_results.txt"
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