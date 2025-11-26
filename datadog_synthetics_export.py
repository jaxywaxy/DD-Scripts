# -*- coding: utf-8 -*-
"""
Datadog Synthetics export script
- Fetch all synthetic tests
- Extract subtype, status, frequency (tick_every), advanced scheduling (timezone + timeframes),
  locations, monitor_id, device_ids, tags
- Export to CSV/Excel

Usage:
  python datadog_synthetics_export.py --api_key <DD_API_KEY> --app_key <DD_APP_KEY> \
      --output csv|excel|both --filename <base_name>

Author: M365 Copilot for Jacqui Rennie
Date: 2025-11-27
"""

import requests
import pandas as pd
import argparse
from typing import Dict, List, Any, Optional

# Map Datadog day numbers to readable labels.
DAY_MAP = {1: "Mon", 2: "Tue", 3: "Wed", 4: "Thu", 5: "Fri", 6: "Sat", 7: "Sun"}


def get_synthetic_tests(api_key: str, app_key: str) -> List[Dict[str, Any]]:
    """
    Fetch all synthetic tests from Datadog API with pagination.
    """
    url = "https://api.datadoghq.com/api/v1/synthetics/tests"
    headers = {"DD-API-KEY": api_key, "DD-APPLICATION-KEY": app_key}

    all_tests: List[Dict[str, Any]] = []
    page = 0
    page_size = 100

    while True:
        params = {"page": page, "page_size": page_size}
        response = requests.get(url, headers=headers, params=params)
        try:
            response.raise_for_status()
        except requests.exceptions.HTTPError as e:
            print(f"Error fetching synthetic tests: {e}")
            print(f"Response status: {response.status_code}")
            if response.status_code == 403:
                print("403 Forbidden - Check API and Application keys and permissions.")
            print(f"Response body: {response.text[:500]}")
            raise

        data = response.json() or {}
        tests = data.get("tests", [])
        if not tests:
            break
        all_tests.extend(tests)
        if len(tests) < page_size:
            break
        page += 1

    return all_tests


def extract_subtype(test: Dict[str, Any], test_type: str) -> str:
    """
    Extract subtype based on test type.
    - API: http, ssl, tcp, dns, icmp, websocket, grpc, udp, multi
    - Browser/Mobile: multistep (if steps > 1) or N/A
    """
    if test_type == "api":
        return test.get("subtype", "N/A")
    elif test_type in ["browser", "mobile"]:
        steps = test.get("steps", [])
        if steps and len(steps) > 1:
            return "multistep"
        return "N/A"
    return "N/A"


def format_seconds_to_human(seconds: Optional[int]) -> str:
    """Format seconds into a friendly string (e.g., '5 minutes', '1 hour')."""
    if not seconds and seconds != 0:
        return "N/A"
    try:
        sec = int(seconds)
    except (ValueError, TypeError):
        return "N/A"
    if sec == 0:
        return "0 seconds"
    if sec % 3600 == 0:
        hours = sec // 3600
        return f"{hours} hour{'s' if hours != 1 else ''}"
    if sec % 60 == 0:
        minutes = sec // 60
        return f"{minutes} minute{'s' if minutes != 1 else ''}"
    return f"{sec} seconds"


def extract_frequency(test: Dict[str, Any], test_type: str) -> str:
    """
    Extract run frequency for ALL test types from options.tick_every (seconds).
    Fallback to 'N/A' if not present.
    """
    options = test.get("options", {})
    tick_every = options.get("tick_every")
    return format_seconds_to_human(tick_every)


def extract_schedule(test: Dict[str, Any]) -> Dict[str, str]:
    """
    Extract advanced scheduling details:
    - timezone: options.scheduling.timezone
    - windows: joined 'DAY HH:MM-HH:MM' for each timeframe in options.scheduling.timeframes
    """
    options = test.get("options", {})
    scheduling = options.get("scheduling", {}) or {}
    timezone = scheduling.get("timezone") or "N/A"
    timeframes = scheduling.get("timeframes") or []

    windows: List[str] = []
    for tf in timeframes:
        day_num = tf.get("day")
        start = tf.get("from")
        end = tf.get("to")
        day_str = DAY_MAP.get(day_num, str(day_num) if day_num is not None else "N/A")
        if start and end:
            if day_num is None:
                windows.append(f"{start}-{end}")
            else:
                windows.append(f"{day_str} {start}-{end}")

    return {
        "schedule_timezone": timezone,
        "schedule_windows": "; ".join(windows) if windows else "N/A",
    }


def extract_locations(test: Dict[str, Any]) -> str:
    """Extract locations as comma-separated string."""
    locations = test.get("locations", [])
    if locations:
        return ", ".join(locations)
    return "N/A"


def extract_device_ids(test: Dict[str, Any]) -> str:
    """Extract device_ids for browser tests."""
    options = test.get("options", {})
    device_ids = options.get("device_ids", [])
    if device_ids:
        return ", ".join(device_ids)
    return "N/A"


def extract_tags(test: Dict[str, Any]) -> str:
    """Extract tags as comma-separated string."""
    tags = test.get("tags", [])
    if tags:
        return ", ".join(tags)
    return "N/A"


def extract_monitor_id(test: Dict[str, Any]) -> str:
    """Extract monitor_id if available."""
    monitor_id = test.get("monitor_id")
    if monitor_id is not None:
        return str(monitor_id)
    return "N/A"


def get_status(test: Dict[str, Any]) -> str:
    """Determine test status (live or paused)."""
    status = test.get("status")
    if status:
        return status.lower()
    return "N/A"


def process_synthetic_tests(tests: List[Dict[str, Any]]) -> pd.DataFrame:
    """Process synthetic tests and extract all required fields."""
    rows: List[Dict[str, Any]] = []
    for test in tests:
        test_type = (test.get("type") or "").lower()
        schedule = extract_schedule(test)
        rows.append({
            "public_id": test.get("public_id", "N/A"),
            "name": test.get("name", "N/A"),
            "type": test_type,
            "subtype": extract_subtype(test, test_type),
            "status": get_status(test),
            "frequency": extract_frequency(test, test_type),
            "locations": extract_locations(test),
            "monitor_id": extract_monitor_id(test),
            "device_ids": extract_device_ids(test),
            "tags": extract_tags(test),
            "schedule_timezone": schedule["schedule_timezone"],
            "schedule_windows": schedule["schedule_windows"],
        })
    return pd.DataFrame(rows)


def export_to_csv(df: pd.DataFrame, filename: str = "synthetic_tests.csv"):
    """Export DataFrame to CSV file."""
    df.to_csv(filename, index=False)
    print(f"Exported {len(df)} synthetic tests to {filename}")


def export_to_excel(df: pd.DataFrame, filename: str = "synthetic_tests.xlsx"):
    """Export DataFrame to Excel file."""
    df.to_excel(filename, index=False, engine="openpyxl")
    print(f"Exported {len(df)} synthetic tests to {filename}")


def main():
    parser = argparse.ArgumentParser(
        description="Extract Datadog synthetic tests including frequency and advanced scheduling."
    )
    parser.add_argument("--api_key", required=True, help="Datadog API key")
    parser.add_argument("--app_key", required=True, help="Datadog Application key")
    parser.add_argument(
        "--output", choices=["csv", "excel", "both"], default="csv",
        help="Output format (default: csv)"
    )
    parser.add_argument(
        "--filename",
        help="Output filename (without extension). Default: synthetic_tests"
    )

    args = parser.parse_args()

    print("Fetching synthetic tests from Datadog...")
    tests = get_synthetic_tests(args.api_key, args.app_key)
    print(f"Found {len(tests)} synthetic tests")

    print("Processing test data...")
    df = process_synthetic_tests(tests)

    base_filename = args.filename or "synthetic_tests"

    if args.output in ["csv", "both"]:
        export_to_csv(df, f"{base_filename}.csv")
    if args.output in ["excel", "both"]:
        export_to_excel(df, f"{base_filename}.xlsx")

    # Summary
    print("\nSummary:")
    print(f"Total tests: {len(df)}")
    if not df.empty:
        print("By type:")
        print(df["type"].value_counts().to_string())
        print("\nBy status:")
        print(df["status"].value_counts().to_string())


if __name__ == "__main__":
    main()
