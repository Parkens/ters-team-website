# Runbook: Basic Diagnostics

## Purpose
Basic commands for quick availability diagnostics of ingress-proxy, DNS, redirect chains, and latency.

## Use when
- the website is unavailable
- first page load is unstable
- you need to check the redirect chain
- you need to compare DNS and direct IP availability
- you need to quickly gather preliminary symptoms before deeper analysis

## Quick checks

### Check HTTP response and redirects
```
curl -I -L https://www.ters-team.com
```

### Measure connection and first byte timing
```
curl -w "time_connect: %{time_connect}\nstarttransfer: %{time_starttransfer}\n" -o /dev/null -s https://www.ters-team.com
```

### Check DNS / NS
```
nslookup -type=ns ters-team.com
nslookup www.ters-team.com
dig www.ters-team.com
dig www.ters-team.com @1.1.1.1
dig www.ters-team.com @8.8.8.8
```

### Test ingress IP directly

```
curl -v https://www.ters-team.com --resolve www.ters-team.com:443:216.24.57.3
```

### Note
`216.24.57.3` is the current Render ingress IP used for direct diagnostics.

This test bypasses DNS and validates the ingress proxy path directly.

### Check container logs
```
docker compose logs -f ters-proxy
```

## Interpretation

### Healthy state
- `curl -I -L` returns the expected redirect chain and final `200 OK`
- `time_connect` is stable
- `time_starttransfer` is within the expected regional baseline
- DNS responses are consistent across resolvers
- nginx logs contain no upstream handshake or resolver errors

### Suspicious state
- large differences between DNS resolvers
- connection reset, timeout, or `502/503`
- normal `time_connect` but very high `time_starttransfer`
- direct IP works with `--resolve`, but hostname access fails

## Next steps
- If DNS answers differ: see `regional-access-debugging.md`
- If upstream connection fails: see `nginx-upstream-connectivity.md`
- If TLS or certificate errors appear: see `tls-sni-routing.md`
- If `/readyz` fails: see `readiness-checks.md`
