
import json
import sys
import os
import pathlib
import datetime
import re
import pandas as pd

RESULTS = sys.argv[1]
HF_MODEL_NAME = sys.argv[2] 
CENTRALIZED_LOGGING = sys.argv[3] if len(sys.argv) > 3 else "false"



df = pd.read_parquet(RESULTS)
print(df.head())

metrics = df['judge_scores']
metrics_line = ', '.join(metrics.astype(str).tolist())  # Join scores with commas
print (f"Metrics: {metrics_line}")

current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
header = [
    f"--- Metrics Recorded at {current_time} for model: {HF_MODEL_NAME}---"
]
footer = [
    f"--- End of Metrics ---"
]
metrics = header + [metrics_line] + footer


file_path = os.path.dirname(os.path.abspath(__file__)) + "/tap_results.txt"
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


