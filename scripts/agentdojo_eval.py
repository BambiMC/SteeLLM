import json
import sys
import os
import pathlib
import datetime
import re

AVG_UTILITY = sys.argv[1]
HF_MODEL_NAME = sys.argv[2] 
CENTRALIZED_LOGGING = json.loads(pathlib.Path("../config.json").read_text()).get("CENTRALIZED_LOGGING")
BENCHMARK_NAME = "AgentDojo"

success = 0
tries = 0

metrics = [f"Average Utility: {AVG_UTILITY}"]

current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
header = [
    f"--- {BENCHMARK_NAME} - Metrics Recorded at {current_time} for model: {HF_MODEL_NAME}---"
]
footer = [
    f"--- End of Metrics ---"
]
metrics = header + metrics + footer




file_path = os.path.dirname(os.path.abspath(__file__)) + "/agentdojo_results.txt"
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