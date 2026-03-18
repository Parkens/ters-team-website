# Runbook: Nginx Upstream Connectivity

## Purpose
Diagnose connectivity issues between an Nginx reverse proxy and an upstream SaaS origin.

## Use when
- nginx returns `502 Bad Gateway`
- logs contain `connect() failed`
- the upstream becomes unavailable after a deployment
- readiness checks fail due to network or connectivity errors

## Scenario 1: IPv6 Upstream Resolution Without an IPv6 Route

### Symptom
In container logs:
```
connect() failed (101: Network unreachable) upstream: "https://[2606:4700:...]:443"
```

### Cause
Nginx resolves the upstream to an AAAA record, but the container or platform does not have a working IPv6 route.

### Fix
Disable IPv6 in the nginx resolver inside `nginx.conf`:
```
resolver 1.1.1.1 8.8.8.8 valid=300s ipv6=off;
```

### Verification
```
docker compose logs -f ters-proxy
curl -I https://www.ters-team.com
```

### Expected result
- the `Network unreachable` error disappears
- the upstream starts connecting over IPv4

## Scenario 2: Container Healthy, but Site Unavailable

### Symptom
- the container is marked as healthy
- the site returns `502` or timeout
- on Render the application is technically running, but traffic does not reach it

### Cause
Nginx is listening on the wrong port.  
The PaaS only proxies traffic to the port defined by the platform.

### Fix
Ensure nginx listens on `${PORT}` on Render, or that the correct port is defined in the Docker/runtime configuration.

Example:
```
listen ${PORT};
```

Or correctly configure the exposed/runtime port according to the platform configuration.

### Verification
```
curl -I https://www.ters-team.com
```

### Expected result
- the service starts accepting external HTTP traffic
- platform-level `502` or timeout errors disappear

## Scenario 3: High TTFB With Normal TCP Connect

### Symptom
- `time_connect` is normal
- `time_starttransfer` is high
- the issue is more noticeable from China or Russia

### Cause
The problem is not in the local nginx ingress, but in the upstream path, global network topology, or route degradation.

### Verification
```
curl -w "time_connect: %{time_connect}\nstarttransfer: %{time_starttransfer}\n" -o /dev/null -s https://www.ters-team.com

traceroute www.ters-team.com

mtr -rw www.ters-team.com
```

### Expected interpretation
- if `time_connect` is low but `time_starttransfer` is high, the issue is usually not in the local accept layer but further upstream in the request chain
- if the origin URL responds faster, Anycast, DNS, or edge path degradation may be involved

## Scenario 4: DNS works but the website is unreachable

### Symptom
DNS resolves correctly:
```
dig www.ters-team.com
```

But the website fails to load from certain regions.

### Possible causes
- upstream SaaS degradation
- regional filtering
- routing degradation between ingress and the SaaS origin

### Verification
Compare ingress and origin endpoints:
```
curl -I https://www.ters-team.com
curl -I https://andyparkensw.wixsite.com
```

### Expected interpretation
- if both degrade similarly, the issue is likely not in the nginx ingress layer but further upstream
