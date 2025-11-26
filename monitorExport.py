import requests
import pandas as pd

# Replace with your actual Datadog API and application keys
API_KEY = '18e183169f294e1ca086aad04f79a8ab'
APP_KEY = 'deef80f300fbb478c1d2f2f16b33bcdc591185c4'

# Team tag to filter monitors
TEAM_TAG = 'team:ge-integration'

# Datadog API endpoint for monitors
url = 'https://api.datadoghq.com/api/v1/monitor'
headers = {
    'Content-Type': 'application/json'
}
params = {
    'api_key': API_KEY,
    'application_key': APP_KEY,
    'monitor_tags': TEAM_TAG
}

# Make the API request
response = requests.get(url, headers=headers, params=params)
monitors = response.json()

# Extract relevant fields
monitor_data = []
for monitor in monitors:
    monitor_data.append({
        'Name': monitor.get('name'),
        'Type': monitor.get('type'),
        'Query': monitor.get('query'),
        'Tags': ', '.join(monitor.get('tags', [])),
        'Priority': monitor.get('priority'),
        'Message': monitor.get("message", ""),
        'recipients': re.findall(r"@[\w\-_]+", message)
    })

# Convert to DataFrame and export to Excel
df = pd.DataFrame(monitor_data)
df.to_excel('team_monitors.xlsx', index=False)

print("Exported monitors to team_monitors.xlsx")

