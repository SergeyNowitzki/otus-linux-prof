import json
import sys
import requests

api_token = ""
dashboard_file_path = "CPU_RAM_NET_DISK.json"
grafana_url = "http://192.168.99.111:3000"

with open(dashboard_file_path, 'r') as dashboard_file:
    dashboard_json = json.load(dashboard_file)

data = {
    "dashboard": dashboard_json,
    "overwrite": False,
    "message": "Made changes to xyz"
}

headers = {
    "Authorization": f"Bearer {api_token}",
    "Content-Type": "application/json"
}

response = requests.post(f"{grafana_url}/api/dashboards/db", headers=headers, json=data)

if response.status_code == 200:
    print("Dashboard imported successfully.")
else:
    print(f"Failed to import dashboard. Status Code: {response.status_code}")
    sys.exit(1)
