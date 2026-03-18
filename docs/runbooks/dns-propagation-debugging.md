# Runbook: DNS Propagation and Resolver Inconsistency

## Purpose
Diagnose DNS propagation delays, resolver inconsistencies, and caching issues affecting the public domain `www.ters-team.com`.

## Use when
- the website resolves differently across networks
- some regions cannot resolve the domain
- DNS changes were recently applied
- a DNS provider migration occurred
- CDN or DNS platform removal caused stale records

## Architecture reference

Current production DNS:
```
www.ters-team.com  →  A  216.24.57.3
ters-team.com      →  A  216.24.57.3
```

Canonical public entry point:
```
https://www.ters-team.com
```

The root domain redirects to `www`.

## Scenario 1: DNS works in some regions but not others

### Symptoms
- the website works locally but fails in China or Russia
- DNS queries return different results depending on the resolver
- `SERVFAIL` or empty answers appear

### Commands
Check resolution via multiple resolvers:
```
dig www.ters-team.com
dig www.ters-team.com @8.8.8.8
dig www.ters-team.com @1.1.1.1
dig www.ters-team.com @9.9.9.9
```

Check authoritative DNS:
```
dig www.ters-team.com +trace
```

### Interpretation
If results differ, possible causes include:
- resolver caching
- DNS provider propagation delay
- DNS filtering in certain regions
- stale NS records in resolver caches

## Scenario 2: Domain resolves but traffic fails

### Symptoms
DNS returns the correct IP but the website is unreachable.

Example:
```
dig www.ters-team.com
→ 216.24.57.3
```

But:
```
curl https://www.ters-team.com
```

fails.

### Verification
Bypass DNS:
```
curl -I https://www.ters-team.com \
--resolve www.ters-team.com:443:216.24.57.3
```

### Interpretation
- if this works, the problem is likely in the DNS resolution path or resolver cache
- if this fails, the issue is likely in ingress or upstream routing

## Scenario 3: Stale DNS after provider migration

### Symptoms
- the DNS provider was changed but old records still appear
- the domain previously used Gcore DNS
- authoritative servers were updated
- some networks still resolve old records

### Resolution
Force resolver cache refresh by:
- temporarily changing NS to a neutral provider
- waiting for TTL expiration
- restoring the intended authoritative NS

This approach helps flush stale DNS entries in recursive resolvers.

## Notes
DNS behavior may differ significantly across:
- Chinese recursive resolvers
- Russian ISP DNS infrastructure
- global public resolvers

For this reason, the DNS architecture intentionally avoids:
- GeoDNS
- dynamic routing logic
- CDN-managed DNS rewrites
