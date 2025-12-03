
import requests
import pandas as pd
import re

# --- Configuration ---
API_KEY = '04fc0e440c511f276734d7880b682e23'
APP_KEY = 'fa74a5626ea6022f1338232276561cebcd955ff7'
TEAM_TAG = 'team:ge-digital-services'  # filter monitors by tag

URL = 'https://api.datadoghq.com/api/v1/monitor'

# Datadog recommends sending keys in headers; query params also work, but headers are clearer.
headers = {
    'Content-Type': 'application/json',
    'DD-API-KEY': API_KEY,
    'DD-APPLICATION-KEY': APP_KEY,
}
params = {
    'monitor_tags': TEAM_TAG,
}

# --- Request ---
response = requests.get(URL, headers=headers, params=params, timeout=60)

# Fail fast on non-200 and print server-provided message
try:
    response.raise_for_status()
except requests.HTTPError as e:
    # Surface Datadog error payload (often a dict with 'errors')
    print('HTTP error:', e)
    print('Response text:', response.text)
    raise

# Parse JSON; Datadog returns a list of monitor dicts on success.
monitors = response.json()

# Defensive check: if we got a dict, it's an error or unexpected shape
if isinstance(monitors, dict):
    # Common shape: {'errors': [...]} or {'message': '...'}
    raise ValueError(f"Expected a list of monitors but got dict: {monitors}")

monitor_data = []
for monitor in monitors:
    # Ensure each item is a dict
    if not isinstance(monitor, dict):
        # Skip/convert unexpected entries
        continue

    message = monitor.get('message', '') or ''

    # Extract @mentions (e.g., @user, @team, @slack-foo). Allow letters, digits, dash, underscore, dot
    recipients = re.findall(r'@([A-Za-z0-9_.\\-]+)', message)

    monitor_data.append({
        'Name': monitor.get('name'),
        'Type': monitor.get('type'),
        'Query': monitor.get('query'),
        'Tags': ', '.join(monitor.get('tags', []) or []),
        'Priority': monitor.get('priority'),
        'Message': message,
        'Recipients': ', '.join(recipients),
    })

# --- Export ---
df = pd.DataFrame(monitor_data)
output_file = 'team_monitors.xlsx'
df.to_excel(output_file, index=False)
print(f"Exported {len(df)} monitors to {output_file}")

