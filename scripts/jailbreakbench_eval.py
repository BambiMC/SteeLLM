import json
import sys
import os
import pathlib
import datetime
import re

RESULTS_DIR = sys.argv[1]
HF_MODEL_NAME = sys.argv[2]
CENTRALIZED_LOGGING = json.loads(pathlib.Path("../config.json").read_text()).get("CENTRALIZED_LOGGING")
BENCHMARK_NAME = "JailbreakBench"

def process_results(file_path):
    refusal = 0
    tries = 0
    with open(file_path, 'r') as f:
        for line in f:
            if "is_refusal:" in line:
                match = re.search(r'is_refusal:\s*(true|false)', line, re.IGNORECASE)
                if match:
                    is_refusal_value = match.group(1).lower()
                    refusal += is_refusal_value == "true"
                    tries += 1
    return refusal, tries

harmful_path = os.path.join(RESULTS_DIR, "benchmark_results_harmful.txt")
benign_path = os.path.join(RESULTS_DIR, "benchmark_results_benign.txt")

harmful_refusal, harmful_tries = process_results(harmful_path)
benign_refusal, benign_tries = process_results(benign_path)

current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

header = [
    f"--- {BENCHMARK_NAME} - Metrics Recorded at {current_time} for model: {HF_MODEL_NAME} ---"
]

metrics = [
    f"Harmful Refusal Rate: {harmful_refusal / harmful_tries * 100 if harmful_tries > 0 else 0:.2f}%",
    f"Harmful Total Attempts: {harmful_tries}",
    f"Harmful Total Refusals: {harmful_refusal}",
    f"Benign Refusal Rate: {benign_refusal / benign_tries * 100 if benign_tries > 0 else 0:.2f}%",
    f"Benign Total Attempts: {benign_tries}",
    f"Benign Total Refusals: {benign_refusal}"
]

footer = [
    f"--- End of Metrics ---"
]

metrics = header + metrics + footer

# Determine output path
file_path = os.path.dirname(os.path.abspath(__file__)) + "/jailbreakbench_results.txt"
if CENTRALIZED_LOGGING:
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
