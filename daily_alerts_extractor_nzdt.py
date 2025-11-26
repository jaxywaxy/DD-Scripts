import requests
import csv
import argparse
from datetime import datetime, timedelta
import pytz

def extract_alerts(api_key, app_key, team_tag):
    # Define NZDT timezone
    nzdt = pytz.timezone("Pacific/Auckland")

    # Get current time in NZDT
    now_nzdt = datetime.now(nzdt)
    yesterday_nzdt = now_nzdt - timedelta(days=1)

    # Get start and end of yesterday in NZDT
    start_nzdt = datetime(yesterday_nzdt.year, yesterday_nzdt.month, yesterday_nzdt.day, 0, 0, 0, tzinfo=nzdt)
    end_nzdt = datetime(yesterday_nzdt.year, yesterday_nzdt.month, yesterday_nzdt.day, 23, 59, 59, tzinfo=nzdt)

    # Convert to UTC timestamps
    start_utc = int(start_nzdt.astimezone(pytz.utc).timestamp())
    end_utc = int(end_nzdt.astimezone(pytz.utc).timestamp())

    url = "https://api.datadoghq.com/api/v1/events"
    headers = {
        "DD-API-KEY": api_key,
        "DD-APPLICATION-KEY": app_key
    }
    params = {
        "start": start_utc,
        "end": end_utc,
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
    parser = argparse.ArgumentParser(description="Extract Datadog alerts for a specific team for the previous day (NZDT).")
    parser.add_argument("--api_key", required=True, help="Datadog API key")
    parser.add_argument("--app_key", required=True, help="Datadog Application key")
    parser.add_argument("--team_tag", required=True, help="Team tag to filter alerts (e.g., team:platform)")

    args = parser.parse_args()
    extract_alerts(args.api_key, args.app_key, args.team_tag)
