# Runbooks

This section contains **operational instructions** for diagnosing and resolving common issues in the ingress proxy infrastructure for the website **www.ters-team.com**.

Runbooks are used during system operations and help quickly localize problems in the request chain:
```
Client → DNS → Ingress → Reverse Proxy → SaaS Origin
```

Unlike **postmortems**, runbooks describe **what to do when a problem occurs**, rather than documenting the history of an incident.

## DNS architecture (production)

The current production DNS configuration intentionally avoids:
- GeoDNS
- dynamic routing
- CDN-managed DNS logic

This keeps the request path deterministic and easier to diagnose in filtering environments.

```
www.ters-team.com  A  216.24.57.3
ters-team.com      A  216.24.57.3
```

### Behavior
```
ters-team.com
↓
HTTP redirect
↓
www.ters-team.com
```

The canonical public entry point is:
```
https://www.ters-team.com
```

Direct access to `www` avoids an additional redirect RTT, which is particularly noticeable in high-latency environments such as mainland China.

### Why both records use the same IP
Both `@` and `www` currently resolve to the same ingress IP:
```
216.24.57.3
```

This is intentional.

Using a single ingress IP:
- simplifies DNS behavior
- avoids resolver inconsistencies
- improves stability in regions with aggressive DNS caching or filtering
- keeps the routing path deterministic

Canonicalization to `www` is handled at the **application / ingress layer**, not at DNS.

## Request path overview
```
Client
↓
GoDaddy DNS
↓
Render ingress
↓
Docker container
↓
nginx reverse proxy
↓
Wix SaaS origin
```

## Available runbooks

### Diagnostics
- `basic-diagnostics.md` — basic checks for HTTP, DNS, and latency
- `local-netwok-checks` — local checks for HTTP response and latency
- `global-availability-checks` — global checks for HTTP response and tracing

### Reverse proxy
- `nginx-upstream-connectivity.md` — nginx upstream connection issues
- `sub-filter-rewrite.md` — `sub_filter` and HTML rewrite problems

### TLS / routing
- `tls-sni-routing.md` — TLS handshake and SNI routing errors

### Health checks
- `readiness-checks.md` — diagnostics for `/healthz` and `/readyz`

### Platform / deployment
- `render-deployment.md` — deployment and ingress validation on Render

### Network / regional issues
- `dns-propagation-debugging.md` — diagnose DNS propagation, resolver, and caching issues
- `regional-access-debugging.md` — accessibility diagnostics from Russia and China
- `redirect-latency.md` — redirect latency analysis

### Historical infrastructure
- `cloudflare-tunnel-debugging.md` — troubleshooting Cloudflare Tunnel used during early infrastructure experiments

## Related documentation
Incident analysis and historical network incidents are documented in:
```
docs/postmortems/
```

These documents explain **why incidents occurred** and what architectural decisions were made as a result.
