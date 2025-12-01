#!/usr/bin/env python3
"""
Export Datadog RUM Retention Filters to an Excel spreadsheet or master CSV.

Usage examples:
  # By application ID
  python rum_retention_filters_export.py --app-id 1d4b9c34-7ac4-423a-91cf-9902d926e9b3 --out rum_filters.xlsx

  # By application name (exact match)
  python rum_retention_filters_export.py --app-name "My Browser App" --out rum_filters.xlsx

  # All applications (one sheet per app + a master sheet)
  python rum_retention_filters_export.py --all-apps --out rum_filters_all.xlsx

  # All applications and also write a master CSV
  python rum_retention_filters_export.py --all-apps --out rum_filters_all.xlsx --master-csv rum_filters_all.csv

Environment variables (recommended):
  DD_SITE           (default: datadoghq.com)
  DD_API_KEY        Your Datadog API Key
  DD_APP_KEY        Your Datadog Application Key

Requires: datadog-api-client (v2), pandas, openpyxl
  pip install datadog-api-client pandas openpyxl
"""

import os
import sys
import argparse
from typing import Optional, List, Dict

import pandas as pd
from datadog_api_client import ApiClient, Configuration
from datadog_api_client.v2.api.rum_api import RUMApi
from datadog_api_client.v2.api.rum_retention_filters_api import RumRetentionFiltersApi
from datadog_api_client.exceptions import ApiException


def resolve_app_id(api_client: ApiClient, app_id: Optional[str], app_name: Optional[str]) -> str:
    """Resolve and return a RUM application ID using either direct ID or an exact name match.
    Raises ValueError if not found or ambiguous.
    """
    if app_id:
        return app_id
    if not app_name:
        raise ValueError("Either --app-id or --app-name must be provided when not using --all-apps.")

    rum_api = RUMApi(api_client)
    apps = rum_api.get_rum_applications()
    matches = [a for a in apps.data if getattr(a.attributes, 'name', None) == app_name]
    if not matches:
        raise ValueError(f"No RUM application found with name: {app_name}")
    if len(matches) > 1:
        ids = ", ".join([str(getattr(a, 'id', '')) for a in matches])
        raise ValueError(f"Multiple applications matched name '{app_name}'. Specify --app-id. Matches: {ids}")
    return str(getattr(matches[0], 'id'))


def fetch_retention_filters(api_client: ApiClient, app_id: str) -> List[dict]:
    """Fetch retention filters for a given RUM application ID and return a list of dicts suitable for DataFrame."""
    rf_api = RumRetentionFiltersApi(api_client)
    resp = rf_api.list_retention_filters(app_id=app_id)
    rows = []
    for item in resp.data:
        attrs = item.attributes
        rows.append({
            'application_id': app_id,
            'retention_filter_id': str(getattr(item, 'id', '')),
            'name': getattr(attrs, 'name', None),
            'event_type': getattr(attrs, 'event_type', None),
            'query': getattr(attrs, 'query', None),
            'sample_rate': getattr(attrs, 'sample_rate', None),
            'enabled': getattr(attrs, 'enabled', None)
        })
    return rows


def fetch_all_apps(api_client: ApiClient) -> List[Dict[str, str]]:
    """Return a list of dicts with app_id and app_name for all RUM applications."""
    rum_api = RUMApi(api_client)
    apps = rum_api.get_rum_applications()
    result = []
    for a in apps.data:
        result.append({
            'id': str(getattr(a, 'id', '')),
            'name': getattr(a.attributes, 'name', None) or ''
        })
    return result


def main():
    parser = argparse.ArgumentParser(description='Export Datadog RUM Retention Filters to Excel and/or master CSV')
    group = parser.add_mutually_exclusive_group(required=False)
    group.add_argument('--app-id', help='RUM application ID (UUID)')
    group.add_argument('--app-name', help='Exact name of the RUM application')
    parser.add_argument('--all-apps', action='store_true', help='Export retention filters for all RUM applications')
    parser.add_argument('--out', default='rum_retention_filters.xlsx', help='Output Excel file path (.xlsx)')
    parser.add_argument('--sheet', default='RUM Retention Filters', help='Worksheet name (used only for single-app export)')
    parser.add_argument('--master-csv', default=None, help='(Optional) Path to write a master CSV containing all filters across apps')
    parser.add_argument('--site', default=os.getenv('DD_SITE', 'datadoghq.com'), help='Datadog site (e.g. datadoghq.com, datadoghq.eu)')
    args = parser.parse_args()

    if not args.all_apps and not (args.app_id or args.app_name):
        print("ERROR: Provide --app-id or --app-name, or use --all-apps.", file=sys.stderr)
        sys.exit(2)

    # Configure Datadog client using env vars or provided site
    config = Configuration()
    config.server_variables = {"site": args.site}

    # Auth via env vars; alternatively set in code: config.api_key['apiKeyAuth'] / ['appKeyAuth']
    if not os.getenv('DD_API_KEY') or not os.getenv('DD_APP_KEY'):
        print("ERROR: DD_API_KEY and DD_APP_KEY environment variables must be set.", file=sys.stderr)
        sys.exit(2)

    try:
        with ApiClient(config) as api_client:
            if args.all_apps:
                apps = fetch_all_apps(api_client)
                master_rows = []
                with pd.ExcelWriter(args.out, engine='openpyxl') as writer:
                    for app in apps:
                        app_id = app['id']
                        app_name = app['name'] or app_id
                        rows = fetch_retention_filters(api_client, app_id)
                        df = pd.DataFrame(rows)
                        # Use a safe sheet name (Excel limit 31 chars)
                        safe_name = (app_name[:31]).strip() or app_id[:31]
                        if df.empty:
                            # Write an empty sheet with headers for visibility
                            df = pd.DataFrame(columns=['application_id','retention_filter_id','name','event_type','query','sample_rate','enabled'])
                        df.to_excel(writer, index=False, sheet_name=safe_name)
                        master_rows.extend(rows)
                    # Master sheet with all filters across apps
                    master_df = pd.DataFrame(master_rows)
                    master_df.to_excel(writer, index=False, sheet_name='__ALL__')
                print(f"Exported retention filters for {len(apps)} applications to {args.out}")

                # Also write master CSV if requested
                if args.master_csv:
                    master_df.to_csv(args.master_csv, index=False)
                    print(f"Wrote master CSV with {len(master_df)} rows to {args.master_csv}")
            else:
                target_app_id = resolve_app_id(api_client, args.app_id, args.app_name)
                rows = fetch_retention_filters(api_client, target_app_id)
                df = pd.DataFrame(rows)
                with pd.ExcelWriter(args.out, engine='openpyxl') as writer:
                    df.to_excel(writer, index=False, sheet_name=args.sheet)
                print(f"Exported {len(rows)} retention filters for app '{target_app_id}' to {args.out}")
    except ApiException as e:
        print(f"Datadog API error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
