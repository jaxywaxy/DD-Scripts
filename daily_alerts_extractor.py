import requests
import csv
import argparse
from datetime import datetime, timedelta

def extract_alerts(api_key, app_key, team_tag):
    today = datetime.utcnow().date()
    yesterday = today - timedelta(days=1)
    start = int(datetime(yesterday.year, yesterday.month, yesterday.day).timestamp())
    end = int(datetime(today.year, today.month, today.day).timestamp())

    url = "https://api.datadoghq.com/api/v1/events"
    headers = {
        "DD-API-KEY": api_key,
        "DD-APPLICATION-KEY": app_key
    }
    params = {
        "start": start,
        "end": end,
        "tags": team_tag,
        "priority": "normal"
    }
    response = requests.get(url, headers=headers, params=params)
    alerts = response.json().get("events", [])

    with open("daily_alerts.csv", mode="w", newline="", encoding="utf-8") as file:
        writer = csv.writer(file)
        writer.writerow(["Title", "Text", "Date", "Tags", "Alert Type"])
        for alert in alerts:
            writer.writerow([
                alert.get("title", ""),
                alert.get("text", "").replace("\n", " "),
                datetime.utcfromtimestamp(alert.get("date_happened")).strftime('%Y-%m-%d %H:%M:%S'),
                ",".join(alert.get("tags", [])),
                alert.get("alert_type", "")
            ])

    print(f"Extracted {len(alerts)} alerts to daily_alerts.csv")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Extract Datadog alerts for a specific team for the previous day.")
    parser.add_argument("--api_key", required=True, help="Datadog API key")
    parser.add_argument("--app_key", required=True, help="Datadog Application key")
    parser.add_argument("--team_tag", required=True, help="Team tag to filter alerts (e.g., team:platform)")

    args = parser.parse_args()
    extract_alerts(args.api_key, args.app_key, args.team_tag)
