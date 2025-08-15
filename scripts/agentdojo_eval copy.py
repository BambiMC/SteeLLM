import json
import sys
import os
import pathlib
import datetime

# First N-1 arguments are the average utilities, last one is the model name
AVG_UTILITIES = sys.argv[1:-1]
HF_MODEL_NAME = sys.argv[-1]

# Load centralized logging config
CENTRALIZED_LOGGING = json.loads(pathlib.Path("../config.json").read_text()).get("CENTRALIZED_LOGGING")
BENCHMARK_NAME = "AgentDojo"

# Define scenario names in same order as Bash script
SCENARIOS = ["workspace", "banking", "slack", "travel"]

# Create metrics lines
metrics = [f"{scenario} Average Utility: {score}"
           for scenario, score in zip(SCENARIOS, AVG_UTILITIES)]

# Add timestamp and headers
current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
header = [
    f"--- {BENCHMARK_NAME} - Metrics Recorded at {current_time} for model: {HF_MODEL_NAME} ---"
]
footer = [
    f"--- End of Metrics ---"
]
metrics = header + metrics + footer

# Determine file path
file_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "agentdojo_results.txt")
if CENTRALIZED_LOGGING:
    file_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "centralized_results.txt")

# Write to file
print(f"Writing results to {file_path}")
with open(file_path, "a" if os.path.exists(file_path) else "w") as file:
    file.write("\n")
    file.write("\n".join(metrics) + "\n")
