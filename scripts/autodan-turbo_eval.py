import json
import sys
import os
import pathlib
import datetime
import re

RESULTS = sys.argv[1]
HF_MODEL_NAME = sys.argv[2] 

success = 0
tries = 0

# with open(RESULTS) as f:
    # data = json.load(f)

    # for key, value in data.items():
    #     print(data[key]['log']['success'])
    #     if True in data[key]['log']['success']:
    #         # print(f"Task {key} success: {data[key]['log']['success']}")
    #         success += 1
    #         for val in data[key]['log']['success']:
    #             if val is False:
    #                 tries += 1
    # Extract scores from lines containing "INFO" and "Score:"






pattern = re.compile(
    r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3} - INFO - Request ID: \d+, Iteration: \d+, Epoch: \d+, Score: (\d+(?:\.\d+)?)$'
)
scores = []

with open('logfile.txt', 'r') as f:
    for line in f:
        line = line.strip()
        match = pattern.match(line)
        if match:
            scores.append(float(match.group(1)))

print(scores)

added_up = 0
for score in scores:
    added_up += score
rate = added_up / len(scores) if scores else 0


metrics = [f"Total tries: {len(scores)}", f"Average score: {rate:.2f}",
              f"Total tasks: {len(scores)}", f"Average score per task: {added_up / len(scores) if scores else 0:.2f}"]


# metrics = [f"Total success: {success}", f"Total tries: {tries}", f"Success rate: {success/tries * 100:.2f}%",
#            f"Total tasks: {len(data)}", f"Average success rate per task: {success / len(data) * 100:.2f}%",
#            f"Average tries per task: {tries / len(data):.2f}"]


current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
header = [
    f"--- Metrics Recorded at {current_time} for model: {HF_MODEL_NAME}---"
]
footer = [
    f"--- End of Metrics ---"
]
metrics = header + metrics + footer


file_path = os.path.dirname(os.path.abspath(__file__)) + "/autodan-turbo_results.txt"
print(f"Writing results to {file_path}")
if not os.path.exists(file_path):
    with open(file_path, "w") as file:
        file.write("\n")
        file.write("\n".join(metrics) + "\n")
else:
    with open(file_path, "a") as file:
        file.write("\n")
        file.write("\n".join(metrics) + "\n")