# Postmortems

This section contains analyses of real network incidents encountered during the development of the ingress proxy infrastructure for the website **www.ters-team.com**.

Postmortems document:
- incident symptoms
- technical root cause
- the resolution that was implemented
- lessons learned for future architecture decisions

Unlike **runbooks**, postmortems explain **why a problem occurred**, rather than providing step-by-step diagnostic procedures.

## Infrastructure context

The project operates a deterministic ingress architecture designed to ensure stable accessibility of a SaaS origin (Wix) from regions with complex network environments:
- Europe / United States
- Russian ISP networks
- mainland China (GFW)

Production architecture:
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

The ingress proxy itself is relatively simple; most incidents originate from:
- DNS infrastructure
- CDN filtering
- SaaS multi-tenant routing
- global network topology
- transport protocol behavior

## Available postmortems

### Transport / tunneling
- `cloudflare-quic-instability.md` — instability of Cloudflare Tunnel when using QUIC transport

### CDN / regional filtering
- `netlify-cn-blocking.md` — partial Netlify CDN inaccessibility in mainland China
- `wix-media-blocking-ru.md` — filtering of Wix media CDN in Russian ISP networks

### Routing / network topology
- `vps-routing-limitations.md` — limitations of single-region VPS for global ingress routing
- `root-domain-redirect-latency.md` — possible redirects latency that can occure

### SaaS routing
- `readiness-sni-routing.md` — readiness check failures caused by Host/SNI routing behavior in Wix

### Network filtering
- `dns-poisoning-gfw.md` — DNS poisoning and connectivity instability under the Great Firewall

### DNS infrastructure
- `dns-provider-incompatibility-gcore.md` — DNS resolution instability caused by switching authoritative DNS providers

**These postmortems follow a simplified SRE incident review model inspired by Google SRE practices.**

## How to use postmortems

Postmortems serve several purposes:
- documenting **real incidents**
- preserving **institutional knowledge**
- explaining **architectural decisions**
- improving operational diagnostics

They complement the operational procedures described in:
```
docs/runbooks/
```

Runbooks explain **how to diagnose a problem**, while postmortems explain **why the system behaved the way it did**.
