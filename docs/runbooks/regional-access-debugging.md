# Runbook: Regional Access Debugging (RU / CN / Global)

## Purpose
Diagnose regional accessibility issues, including DNS poisoning, GFW filtering, ISP-specific degradation, and selective CDN blocking.

## Use when
- the site is unavailable only from Russia or China
- `connection reset`, unstable TLS handshake, or unusual DNS responses are observed
- the SPA loads but media assets fail
- availability depends on ISP or mobile network

## Scenario 1: DNS poisoning / filtering detection

### Symptoms
- the site is unstable or unavailable only from China
- `connection reset` may occur
- different DNS resolvers return different responses

### Commands
```
dig www.ters-team.com
dig www.ters-team.com @8.8.8.8
dig www.ters-team.com @1.1.1.1
curl -I https://www.ters-team.com --resolve www.ters-team.com:443:IP
```

### Interpretation
- if DNS responses differ, DNS poisoning may be occurring
- if the IP works via `--resolve` but the hostname does not, the issue is likely DNS-related
- if the direct IP path also degrades, the problem is deeper in the network layer, filtering environment, or TLS path

### External vantage points
- GreatFire
- OONI Probe
- Globalping
- RIPE Atlas

## Scenario 2: Anycast routing degradation

### Symptoms
- the site is fast from Europe
- TTFB is significantly higher from Russia or China
- `time_connect` is normal but `time_starttransfer` is high

### Commands
```
curl -w "time_connect: %{time_connect}\nstarttransfer: %{time_starttransfer}\n" -o /dev/null -s https://www.ters-team.com
curl -I https://www.ters-team.com
traceroute www.ters-team.com
mtr -rw www.ters-team.com
curl -I https://<render-service>.onrender.com
```

### Interpretation
Possible causes:
- an unfavorable edge POP selection
- a changed BGP routing path
- degraded transit through a filtering environment
- the custom domain path performing worse than the origin path

This is usually not an nginx configuration issue.

## Scenario 3: Wix images fail only in Russia

### Symptoms
- the site generally works
- JS, CSS, and SPA runtime load normally
- images fail to load only from Russia

### Likely cause
Selective filtering of media hosts:
- `media.wixstatic.com`
- `static.wixstatic.com`

### Verification
```
curl -I https://www.ters-team.com/wix-media/...
```

Also test direct access to the media hosts from a Russian vantage point.

### Resolution
- proxy media through nginx (`proxy_pass`)
- optionally rewrite media URLs through a controlled proxy path

**Example proxy path:**
```
location /wix-media/ {
    proxy_pass https://media.wixstatic.com/;
}
```
This allows media assets to be delivered through the same ingress path.

### Expected result
Images load through the same ingress path as the main website.

## Scenario 4: CDN partially blocked in China

### Symptoms
- connection reset
- DNS poisoning
- partial or full edge deployment unavailability from mainland China

### Interpretation
This typically indicates filtering not at the application level but at the CDN, ASN, or routing level.

### Operational decision
In this situation, return to a deterministic ingress path:
- use a custom domain
- use a controlled reverse proxy
- avoid reliance on CDN-level rewrites or edge logic

### Notes
- DNS providers and CDN-managed DNS may behave differently in filtering environments
- in previous experiments some DNS providers produced inconsistent resolution behavior from mainland China
- for this reason production DNS is currently hosted on GoDaddy without GeoDNS or dynamic routing logic
