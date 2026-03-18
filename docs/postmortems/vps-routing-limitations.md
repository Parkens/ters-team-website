# Postmortem: VPS Routing Limitations

## Incident summary
The initial architecture used a Kamatera VPS as the ingress proxy.

Testing revealed degraded availability and higher latency from certain regions.

## Symptoms
- high latency from Russia
- high latency from China
- unstable TTFB

Typical measurements:
```
time_connect: 0.25
time_starttransfer: 3.8
```

## Investigation
The following were verified:
- nginx configuration
- reverse proxy behavior
- TLS handshake
- upstream connectivity

All checks indicated that the proxy was functioning correctly.

## Root cause
The issue was not related to nginx or the reverse proxy configuration.

A single VPS typically has:
- one ASN
- a fixed network routing path
- limited transit options

As a result, some regions received inefficient BGP routes to the VPS.

## Resolution
The ingress layer was migrated to Render.

Render provides:

- globally distributed ingress routing
- optimized network paths through multiple upstream providers
- managed platform ingress infrastructure

The ingress proxy itself remains a single container instance,
but the platform routing significantly improves global reachability.

## Result
- improved latency
- more stable first page load
- better availability from Russia and China

## Lessons learned
- network routing can be more important than reverse proxy configuration
- a single-region VPS may not be suitable for global ingress
- Anycast ingress can significantly improve global reachability
