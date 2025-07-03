import requests
from datetime import datetime, timedelta
import pkg_resources
from datetime import timezone

# CUTOFF_DATE = datetime.now(timezone.utc) - timedelta(days=10*30)
CUTOFF_DATE = datetime(2024, 7, 1, tzinfo=timezone.utc)

def get_versions_older_than(package_name, cutoff_date):
    url = f"https://pypi.org/pypi/{package_name}/json"
    response = requests.get(url)
    if not response.ok:
        print(f"Failed to fetch {package_name}")
        return None

    data = response.json()
    versions = []
    for ver, files in data["releases"].items():
        if not files:
            continue
        upload_time = files[0]["upload_time_iso_8601"]
        upload_datetime = datetime.fromisoformat(upload_time.replace("Z", "+00:00"))
        if upload_datetime < cutoff_date:
            versions.append((upload_datetime, ver))
    if not versions:
        return None
    return sorted(versions, reverse=True)[0][1]  # latest older version

new_requirements = []
with open("requirements.txt") as f:
    for line in f:
        package = line.strip().split("==")[0]  # ignore existing pin
        print(f"Checking {package}...")
        version = get_versions_older_than(package, CUTOFF_DATE)
        if version:
            new_requirements.append(f"{package}<={version}")
        else:
            print(f"⚠️ No version older than 10 months for {package}")
            new_requirements.append(package)  # fallback

with open("requirements_pinned.txt", "w") as f:
    for line in new_requirements:
        f.write(line + "\n")

print("Generated requirements_pinned.txt")
