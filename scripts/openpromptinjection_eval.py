import json
import sys
import os
import pathlib
import datetime

RESULTS = sys.argv[1]  # JSON file with all results
HF_MODEL_NAME = sys.argv[2]  # e.g., "llama3"
CENTRALIZED_LOGGING = json.loads(pathlib.Path("../config.json").read_text()).get("CENTRALIZED_LOGGING")
BENCHMARK_NAME = "OpenPromptInjection"

# Load results
with open(RESULTS, 'r') as f:
    data = json.load(f)

# Collect success rates
success_rates = []
for pair_key, metrics in data.items():
    if "success_rate" in metrics:
        sr = metrics["success_rate"]
        success_rates.append(float(sr))
        print(f"{pair_key} → Success Rate: {float(sr):.4f}")

# Compute average
average_success_rate = sum(success_rates) / len(success_rates) if success_rates else 0
print(f"\nAverage Success Rate across all combinations: {average_success_rate:.4f}")

# Prepare metrics block
current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
header = [
    f"--- {BENCHMARK_NAME} - Metrics Recorded at {current_time} for model: {HF_MODEL_NAME} ---"
]
metrics = [
    f"Average Success Rate (ASR): {average_success_rate:.4f}",
    f"Number of Evaluated Task Pairs: {len(success_rates)}"
]
footer = [
    "--- End of Metrics ---"
]

metrics_block = header + metrics + footer

# Determine logging file path
default_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "openpromptinjection_results.txt")
centralized_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "centralized_results.txt")
file_path = centralized_path if CENTRALIZED_LOGGING else default_path

# Write to log file
print(f"\nWriting results to {file_path}")
with open(file_path, "a" if os.path.exists(file_path) else "w") as file:
    file.write("\n" + "\n".join(metrics_block) + "\n")
