import json
import sys
import os
import pathlib
import datetime

RESULTS = sys.argv[1]
HF_MODEL_NAME = sys.argv[2] 
CENTRALIZED_LOGGING = json.loads(pathlib.Path("../config.json").read_text()).get("CENTRALIZED_LOGGING")
BENCHMARK_NAME = "PurpleLlama - " + sys.argv[3]

print(f"Reading results from {RESULTS} for model {HF_MODEL_NAME}")

with open(RESULTS, 'r') as f:
    data = json.load(f)

metrics = []

if "MITRE" in BENCHMARK_NAME:
    for model_name, categories in data.items():
        for category, stats in categories.items():
            total_count = stats.get("total_count", 0)
            benign_percentage = stats.get("benign_percentage", 0.0) * 100  # convert 1.0 → 100%
            metrics.append(f"Category: {category}\nTotal count: {total_count}\nBenign percentage: {benign_percentage:.2f}%")
elif "FRR" in BENCHMARK_NAME:
    for model_name, stats in data.items():
        accept_count = stats.get("accept_count", 0)
        refusal_count = stats.get("refusal_count", 0)
        refusal_rate = stats.get("refusal_rate", 0.0) * 100  # convert fraction → %
        metrics.append(
            f"Accept count: {accept_count}\n"
            f"Refusal count: {refusal_count}\n"
            f"Refusal rate: {refusal_rate:.2f}%"
        )
elif "PI" in BENCHMARK_NAME:
    for model_name, categories in data.items():
        # Overall per-model stats
        overall = categories.get("stat_per_model", {})
        inj_success = overall.get("injection_successful_count", 0)
        inj_unsuccess = overall.get("injection_unsuccessful_count", 0)
        total_count = overall.get("total_count", 0)
        inj_success_pct = overall.get("injection_successful_percentage", 0.0) * 100
        inj_unsuccess_pct = overall.get("injection_unsuccessful_percentage", 0.0) * 100
        metrics.append(
            f"Injection Successful: {inj_success} ({inj_success_pct:.2f}%)\n"
            f"Injection Unsuccessful: {inj_unsuccess} ({inj_unsuccess_pct:.2f}%)\n"
            f"Total count: {total_count}"
        )

        # Breakdowns by injection type
        for inj_type, stats in categories.get("stat_per_model_per_injection_type", {}).items():
            inj_success = stats.get("injection_successful_count", 0)
            inj_unsuccess = stats.get("injection_unsuccessful_count", 0)
            total_count = stats.get("total_count", 0)
            inj_success_pct = stats.get("injection_successful_percentage", 0.0) * 100
            inj_unsuccess_pct = stats.get("injection_unsuccessful_percentage", 0.0) * 100
            metrics.append(
                f"Injection Type: {inj_type}\n"
                f"  Successful: {inj_success} ({inj_success_pct:.2f}%)\n"
                f"  Unsuccessful: {inj_unsuccess} ({inj_unsuccess_pct:.2f}%)\n"
                f"  Total: {total_count}"
            )


current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
header = [
    f"--- {BENCHMARK_NAME} - Metrics Recorded at {current_time} for model: {HF_MODEL_NAME} ---"
]
footer = [
    f"--- End of Metrics ---"
]

metrics = header + metrics + footer
print("Metrics:\n" + "\n".join(metrics))

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
