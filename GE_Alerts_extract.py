import requests
from requests import HTTPError

def _list_teams_by_keyword(keyword: str):
    """
    Use Teams API v2 to find the team and its handle.
    Docs: GET /api/v2/team with filter[keyword]
    """
    url = f"https://api.{SITE}/api/v2/team"
    params = {"filter[keyword]": keyword, "page[size]": 100}
    r = requests.get(url, headers=HEADERS, params=params, timeout=60)
    r.raise_for_status()
    return r.json().get("data", []) or []

def _extract_team_handle(keyword: str) -> str:
    """
    Attempt to resolve a team handle from either a display name or an existing handle.
    Prefer exact name/handle match; otherwise take the first hit.
    """
    teams = _list_teams_by_keyword(keyword)
    if not teams:
        # If keyword already looks like a handle, return it as-is
        return keyword.strip().lower().replace(" ", "-")
    # Try exact match on name or handle
    for t in teams:
        attrs = t.get("attributes", {}) or {}
        name = attrs.get("name", "")
        handle = attrs.get("handle", "")
        if keyword.lower() in (name.lower(), handle.lower()):
            return handle
    # Fallback to first
    return teams[0].get("attributes", {}).get("handle", keyword.strip().lower().replace(" ", "-"))

def find_monitors_for_team(team_input: str):
    """
    Resolves team handle, then queries Monitors Search API using robust variants.
    """
    handle = _extract_team_handle(team_input)
    # Build query variants (singular vs plural field; quoted vs unquoted)
    variants = [
        f'team:{handle}',
        f'team:"{handle}"',
        f'teams:{handle}',
        f'teams:"{handle}"',
    ]

    last_err = None
    for q in variants:
        try:
            data = datadog_get(f"{BASE_V1}/monitor/search", params={"query": q})
            candidates = []
            if isinstance(data, dict):
                if "data" in data and isinstance(data["data"], dict) and "monitors" in data["data"]:
                    candidates = data["data"]["monitors"]
                elif "monitors" in data:
                    candidates = data["monitors"]
            monitors = [{"id": m.get("id"), "name": m.get("name")} for m in (candidates or []) if m.get("id") is not None]
            if monitors:
                return monitors
            # If the call worked but no monitors returned, try next variant
        except HTTPError as e:
            # 400 implies an unrecognized field/query grammar; try next variant
            last_err = e
            continue

    # If all variants failed or yielded nothing, surface a helpful message
    if last_err:
        raise RuntimeError(
            f"Failed to search monitors for team '{team_input}' (resolved handle '{handle}'). "
            f"Last error: {last_err}"
        )
