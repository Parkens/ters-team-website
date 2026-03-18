# Postmortem: Cloudflare Tunnel QUIC Instability
⚠️ Historical incident
Cloudflare Tunnel was used during early infrastructure experiments.
It is no longer part of the production architecture.

## Incident summary
While using Cloudflare Tunnel to proxy a local ingress server, the connection became unstable.  
The tunnel periodically disconnected, causing the service to become unavailable.

## Symptoms
cloudflared logs:
```
failed to accept QUIC stream
timeout: no recent network activity
```

Sometimes the tunnel connection recovered automatically; in other cases it dropped completely.

## Environment
- WSL2 environment
- mobile networks
- IPv6 enabled
- Cloudflare Tunnel (default QUIC transport)

## Investigation
The following were verified:
- the local service was reachable
- DNS resolution worked
- the HTTP endpoint responded correctly

The issue appeared only at the transport layer of the tunnel.

Log analysis showed that the connection used:
```
QUIC (UDP)
```

## Root cause
QUIC uses UDP as its transport.

In certain network environments:
- mobile networks
- WSL2 networking
- some ISPs
- GFW-controlled environments

UDP traffic may:
- be filtered
- degrade under load
- be dropped by stateful firewalls

This resulted in unstable tunnel connectivity.

## Resolution
The tunnel was switched to HTTP/2 transport over TCP.
```
cloudflared tunnel \
--url http://localhost:8080 \
--protocol http2 \
--edge-ip-version 4
```

## Result
- the connection became stable
- the tunnel stopped disconnecting
- QUIC-related errors disappeared

## Lessons learned
- QUIC is not always more reliable than TCP in hostile network environments
- UDP transport may degrade in mobile or filtered networks
- HTTP/2 over TCP is often more predictable under DPI and network filtering
