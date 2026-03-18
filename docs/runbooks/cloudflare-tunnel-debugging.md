# Runbook: Cloudflare Tunnel Debugging
⚠️ Historical runbook
Cloudflare Tunnel was used during earlier infrastructure testing and development.
**It is no longer part of the production architecture.**

## Purpose
Diagnose issues when using Cloudflare Tunnel (`cloudflared`).

## Use when
- the tunnel is unstable
- QUIC errors appear
- the connection drops intermittently
- the tunnel works only from certain networks

## Scenario: QUIC / UDP instability

### Symptom
cloudflared logs:
```
failed to accept QUIC stream
timeout: no recent network activity
```

The tunnel connection becomes unstable or periodically disconnects.

## Cause
QUIC uses:
```
UDP
```

In some networks:
- mobile carriers
- WSL2 environments
- corporate networks
- GFW (China)

UDP traffic may be filtered or degraded.

## Fix
Force the tunnel to use **HTTP/2 transport over TCP and IPv4**.
```
cloudflared tunnel \
--url http://localhost:8080 \
--protocol http2 \
--edge-ip-version 4
```

## Verification
Start the tunnel and inspect logs:
```
cloudflared tunnel --loglevel debug
```

### Expected result
- stable connection
- no QUIC-related errors

## Additional checks

### Verify local service availability
```
curl http://localhost:8080
```

### Verify external access via the tunnel URL
Confirm that the service is reachable through the Cloudflare tunnel endpoint.

## Notes
QUIC / HTTP/3 can provide **lower latency**, but in some network environments it may be:
- unstable
- filtered by DPI
- completely blocked

In such cases, **HTTP/2 over TCP** is often more reliable.
