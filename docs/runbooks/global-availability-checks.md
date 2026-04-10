# `docs/runbooks/global-availability-checks.md`

```md
# Runbook: Global Availability Checks

## Purpose
Quick external availability diagnostics for `www.ters-team.com` using `globalping` from multiple world regions.

## Use when
- the website is reported as unavailable from multiple regions
- you need to confirm whether the issue is local or global
- you suspect CDN, routing, or regional edge problems
- you need broad external reachability data before escalation
- local checks are inconclusive

## Quick checks

### Run global availability check (50 probes)
```bash
printf "Globalping report for https://www.ters-team.com | %s | 50 probes\n\n" "$(date '+%Y-%m-%d %H:%M:%S %Z')" && \
globalping http https://www.ters-team.com --from world --limit 50 --method HEAD --json \
| python3 -c '
import sys, json

def pick(d, *keys, default="?"):
    if not isinstance(d, dict):
        return default
    for k in keys:
        v = d.get(k)
        if v not in (None, "", [], {}):
            return v
    return default

data = json.load(sys.stdin)
rows = []

for r in data.get("results", []):
    probe = r.get("probe", {}) or {}
    result = r.get("result", {}) or {}

    city = pick(probe, "city", default="?")
    country = pick(probe, "country", default="?")
    region = pick(probe, "region", "continent", default="")
    network = pick(probe, "network", default="")

    status_code = result.get("statusCode")
    status_text = pick(result, "status", default="")
    error = result.get("error")

    headers = result.get("headers", {}) or {}
    cf_ray = headers.get("cf-ray") or headers.get("CF-RAY") or ""
    pop = cf_ray.rsplit("-", 1)[-1] if "-" in cf_ray else "-"

    timing = result.get("timings", {}) or {}
    total_ms = (
        timing.get("total")
        or (timing.get("phases", {}) or {}).get("total")
        or timing.get("duration")
        or ""
    )

    if error:
        http = "ERR"
    elif status_code is not None:
        http = f"HTTP {status_code}"
    elif status_text:
        http = f"HTTP {status_text}"
    else:
        http = "HTTP ?"

    loc_str = f"{city}, {country}"
    if region:
        loc_str += f" [{region}]"
    if network:
        loc_str += f" [{network}]"

    latency = f"{total_ms}ms" if total_ms else "-"

    rows.append((loc_str, http, pop, latency))

if not rows:
    print("No results")
    sys.exit(0)

lw = max(len(r[0]) for r in rows)
hw = max(len(r[1]) for r in rows)
pw = max(len(r[2]) for r in rows)

for loc, http, pop, lat in rows:
    print(f"{loc:<{lw}} | {http:<{hw}} | {pop:<{pw}} | {lat}")
'
Interpretation
Healthy state
most probes return successful HTTP responses
response codes are consistent across regions
latency is within expected regional baselines
there are no widespread ERR results
no clear regional cluster of failures is visible
Suspicious state
many probes return ERR
responses differ significantly by region
some regions return success while others consistently fail
latency is abnormally high in a specific geography
CDN edge POPs appear inconsistent across successful responses
Notes
What this test shows

This test helps distinguish:

local workstation / ISP issue
regional routing issue
CDN edge issue
broad public availability incident
POP visibility

The parsed output includes a POP value derived from the cf-ray header when available.

This is useful for spotting:

edge-specific failures
inconsistent CDN behavior
regional response concentration
Scope

This command checks external HTTP availability from distributed probes.

It does not replace:

local workstation testing
DNS resolver comparison
direct ingress diagnostics
backend application checks
Next steps
If global probes are healthy but local checks fail: see local-network-checks.md
If only some regions fail: continue with regional-access-debugging.md
If HTTP fails broadly across probes: treat as a public availability incident
If responses are inconsistent but not fully down: investigate CDN, redirects, and origin reachability
