import requests
import pandas as pd
import argparse
from typing import Dict, List, Any, Optional

def get_synthetic_tests(api_key: str, app_key: str) -> List[Dict[str, Any]]:
    """
    Fetch all synthetic tests from Datadog API.
    """
    url = "https://api.datadoghq.com/api/v1/synthetics/tests"
    headers = {
        "DD-API-KEY": api_key,
        "DD-APPLICATION-KEY": app_key
    }
    
    all_tests = []
    page = 0
    page_size = 100
    
    while True:
        params = {
            "page": page,
            "page_size": page_size
        }
        
        response = requests.get(url, headers=headers, params=params)
        
        try:
            response.raise_for_status()
        except requests.exceptions.HTTPError as e:
            print(f"Error fetching synthetic tests: {e}")
            print(f"Response status: {response.status_code}")
            if response.status_code == 403:
                print("403 Forbidden - Please check that your API key and Application key are valid and have proper permissions.")
            print(f"Response body: {response.text[:500]}")
            raise
        
        data = response.json()
        tests = data.get("tests", [])
        
        if not tests:
            break
            
        all_tests.extend(tests)
        
        # Check if there are more pages
        if len(tests) < page_size:
            break
            
        page += 1
    
    return all_tests


def extract_subtype(test: Dict[str, Any], test_type: str) -> str:
    """
    Extract subtype based on test type.
    - API: http, ssl, tcp, dns, icmp, websocket, grpc
    - Browser/Mobile: multistep or N/A
    """
    if test_type == "api":
        return test.get("subtype", "N/A")
    elif test_type in ["browser", "mobile"]:
        # Check if it's a multistep test
        steps = test.get("steps", [])
        if steps and len(steps) > 1:
            return "multistep"
        return "N/A"
    return "N/A"


def extract_frequency(test: Dict[str, Any], test_type: str) -> str:
    """
    Extract frequency based on test type.
    - API: options.tick_every (seconds)
    - Browser/Mobile: options.scheduling.timeframe.frequency + options.scheduling.timeframe.type
    """
    options = test.get("options", {})
    
    if test_type == "api":
        tick_every = options.get("tick_every")
        if tick_every:
            return f"{tick_every} seconds"
        return "N/A"
    elif test_type in ["browser", "mobile"]:
        scheduling = options.get("scheduling", {})
        timeframe = scheduling.get("timeframe", {})
        frequency = timeframe.get("frequency")
        freq_type = timeframe.get("type", "")
        
        if frequency and freq_type:
            return f"{frequency} {freq_type}"
        return "N/A"
    
    return "N/A"


def extract_locations(test: Dict[str, Any]) -> str:
    """
    Extract locations as comma-separated string.
    """
    locations = test.get("locations", [])
    if locations:
        return ", ".join(locations)
    return "N/A"


def extract_device_ids(test: Dict[str, Any]) -> str:
    """
    Extract device_ids for browser tests.
    """
    options = test.get("options", {})
    device_ids = options.get("device_ids", [])
    if device_ids:
        return ", ".join(device_ids)
    return "N/A"


def extract_tags(test: Dict[str, Any]) -> str:
    """
    Extract tags as comma-separated string.
    """
    tags = test.get("tags", [])
    if tags:
        return ", ".join(tags)
    return "N/A"


def extract_monitor_id(test: Dict[str, Any]) -> str:
    """
    Extract monitor_id if available.
    """
    monitor_id = test.get("monitor_id")
    if monitor_id:
        return str(monitor_id)
    return "N/A"


def get_status(test: Dict[str, Any]) -> str:
    """
    Determine test status (live or paused).
    """
    status = test.get("status")
    if status:
        return status.lower()
    return "N/A"


def process_synthetic_tests(tests: List[Dict[str, Any]]) -> pd.DataFrame:
    """
    Process synthetic tests and extract all required fields.
    """
    test_data = []
    
    for test in tests:
        test_type = test.get("type", "").lower()
        
        test_data.append({
            "public_id": test.get("public_id", "N/A"),
            "name": test.get("name", "N/A"),
            "type": test_type,
            "subtype": extract_subtype(test, test_type),
            "status": get_status(test),
            "frequency": extract_frequency(test, test_type),
            "locations": extract_locations(test),
            "monitor_id": extract_monitor_id(test),
            "device_ids": extract_device_ids(test),
            "tags": extract_tags(test)
        })
    
    return pd.DataFrame(test_data)


def export_to_csv(df: pd.DataFrame, filename: str = "synthetic_tests.csv"):
    """
    Export DataFrame to CSV file.
    """
    df.to_csv(filename, index=False)
    print(f"Exported {len(df)} synthetic tests to {filename}")


def export_to_excel(df: pd.DataFrame, filename: str = "synthetic_tests.xlsx"):
    """
    Export DataFrame to Excel file.
    """
    df.to_excel(filename, index=False)
    print(f"Exported {len(df)} synthetic tests to {filename}")


def main():
    parser = argparse.ArgumentParser(
        description="Extract synthetic tests from Datadog including all relevant fields."
    )
    parser.add_argument(
        "--api_key",
        required=True,
        help="Datadog API key"
    )
    parser.add_argument(
        "--app_key",
        required=True,
        help="Datadog Application key"
    )
    parser.add_argument(
        "--output",
        choices=["csv", "excel", "both"],
        default="csv",
        help="Output format (default: csv)"
    )
    parser.add_argument(
        "--filename",
        help="Output filename (without extension). Default: synthetic_tests"
    )
    
    args = parser.parse_args()
    
    # Fetch synthetic tests
    print("Fetching synthetic tests from Datadog...")
    tests = get_synthetic_tests(args.api_key, args.app_key)
    print(f"Found {len(tests)} synthetic tests")
    
    # Process tests
    print("Processing test data...")
    df = process_synthetic_tests(tests)
    
    # Export
    base_filename = args.filename or "synthetic_tests"
    
    if args.output in ["csv", "both"]:
        export_to_csv(df, f"{base_filename}.csv")
    
    if args.output in ["excel", "both"]:
        export_to_excel(df, f"{base_filename}.xlsx")
    
    # Display summary
    print("\nSummary:")
    print(f"Total tests: {len(df)}")
    print(f"By type:")
    print(df["type"].value_counts().to_string())
    print(f"\nBy status:")
    print(df["status"].value_counts().to_string())


if __name__ == "__main__":
    main()

