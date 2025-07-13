import json
import sys
import os
import pathlib
import datetime

RESULTS = sys.argv[1]
HF_MODEL_NAME = sys.argv[2] 
CENTRALIZED_LOGGING = json.loads(pathlib.Path("../config.json").read_text()).get("CENTRALIZED_LOGGING")
BENCHMARK_NAME = "AutoDan"


success = 0
tries = 0

with open(RESULTS) as f:
    data = json.load(f)

    for key, value in data.items():
        tries += 1
        print("Found data: " + str(data[key]['log']['success']))
        if True in data[key]['log']['success']:
            # print(f"Task {key} success: {data[key]['log']['success']}")
            success += 1
            # for val in data[key]['log']['success']:
            #     if val is False:

print("Total success:", success)
print("Total tries:", tries)

metrics = [f"Total success: {success}", f"Total tries: {tries}", f"Success rate: {success/tries * 100:.2f}%",
           f"Total tasks: {len(data)}", f"Average success rate per task: {success / len(data) * 100:.2f}%",
           f"Average tries per task: {tries / len(data):.2f}"]


current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
header = [
    f"--- {BENCHMARK_NAME} - Metrics Recorded at {current_time} for model: {HF_MODEL_NAME}---"
]
footer = [
    f"--- End of Metrics ---"
]
metrics = header + metrics + footer


file_path = os.path.dirname(os.path.abspath(__file__)) + "/autodan_results.txt"
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