
import json
import sys
import os
import pathlib
import datetime
import re

RESULTS = sys.argv[1]
HF_MODEL_NAME = sys.argv[2] 
CENTRALIZED_LOGGING = sys.argv[3] if len(sys.argv) > 3 else "false"


asr_value = 0

with open(RESULTS, 'r') as f:
    for line in f:
        # find line that contains ASR
        if "success_rate" in line:
            match = re.search(r'"success_rate":\s*([\d.]+)', line)
            if match:
                asr_value = float(match.group(1))
                print(f"Success Rate: {asr_value}")




metrics = [f"Average score: {asr_value:.2f}"]



current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
header = [
    f"--- Metrics Recorded at {current_time} for model: {HF_MODEL_NAME}---"
]
footer = [
    f"--- End of Metrics ---"
]
metrics = header + metrics + footer


file_path = os.path.dirname(os.path.abspath(__file__)) + "/openpromptinjection_results.txt"
if CENTRALIZED_LOGGING.lower() == "true":
    file_path = os.path.dirname(os.path.abspath(__file__)) + "/centralized_results.txt"

print(f"Writing results to {file_path}")
if not os.path.exists(file_path):
    with open(file_path, "w") as file:
        file.write("\n")
        file.write("\n".join(metrics) + "\n")
else:
    with open(file_path, "a") as file:
        file.write("\n")
        file.write("\n".join(metrics) + "\n")