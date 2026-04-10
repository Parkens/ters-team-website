docs/runbooks/local-network-checks.md
# Runbook: Local Network Checks

## Purpose
Quick local network diagnostics for `www.ters-team.com` and `ters-team.com`, including provider detection, public IP lookup, HTTPS reachability, and ICMP stability.

## Use when
- the website is reported as unavailable from a specific workstation
- you need to validate local reachability from your current network
- you need to compare `www` vs apex domain behavior
- you suspect ISP, VPN, firewall, or local routing issues
- you need quick local symptoms before deeper debugging

## Quick checks

### Run network test for `www.ters-team.com`
```bash
nettest () {
  local HOST="www.ters-team.com"

  echo "NETWORK TEST: $(date)"
  echo "Provider : $(curl -fsS ipinfo.io/org)"
  echo "Public IP: $(curl -fsS ipinfo.io/ip)"
  echo

  echo "HTTPS TEST:"
  curl -o /dev/null -s -w "HTTPS $HOST -> HTTP %{http_code} | connect %{time_connect}s | total %{time_total}s\n" "https://$HOST"
  echo

  echo "PING TEST (10 packets):"
  powershell -NoProfile -Command "ping -n 10 $HOST | Select-Object -Last 12"
}

Run:

nettest
Run network test for apex domain
nettestforapex () {
  local HOST="ters-team.com"

  echo "NETWORK TEST: $(date)"
  echo "Provider : $(curl -fsS ipinfo.io/org)"
  echo "Public IP: $(curl -fsS ipinfo.io/ip)"
  echo

  echo "HTTPS TEST:"
  curl -o /dev/null -s -w "HTTPS $HOST -> HTTP %{http_code} | connect %{time_connect}s | total %{time_total}s\n" "https://$HOST"
  echo

  echo "PING TEST (10 packets):"
  powershell -NoProfile -Command "ping -n 10 $HOST | Select-Object -Last 12"
}

Run:

nettestforapex
Interpretation
Healthy state
HTTPS returns expected status (200, 301, 302)
time_connect is stable across repeated runs
time_total is within expected range for the local region
ping completes without packet loss
www and apex behave consistently
Suspicious state
HTTPS returns timeout, connection error, or 5xx
high time_connect suggests network path or provider issues
high time_total with normal connect time suggests server-side delay
ping shows packet loss or unstable round-trip times
www works while apex fails, or apex works while www fails
Notes
Provider and public IP

The output shows:

the current ISP / provider
the current public IP used for egress

This helps identify:

VPN impact
ISP-specific failures
office vs home network differences
whether the issue is reproducible from the same public network
WWW vs apex comparison

Run both functions when possible.

Differences between:

www.ters-team.com
ters-team.com

may indicate:

redirect issues
DNS inconsistencies
hostname-specific proxy/CDN behavior
Next steps
If local checks fail but other users are unaffected: investigate ISP, VPN, firewall, or local DNS
If www and apex behave differently: see basic-diagnostics.md
If HTTPS fails but ping is healthy: investigate TLS, ingress, or upstream connectivity
If the problem needs external confirmation: see global-availability-checks.md
