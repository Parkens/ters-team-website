# Platform / Network Infrastructure Roadmap (www.ters-team.com)

This document outlines the evolution of the platform and network architecture used to ensure reliable global accessibility of **www.ters-team.com**.

The project focuses on maintaining stable access to a SaaS-origin website (Wix) from regions with complex network environments, including:
- Europe / United States
- Russian ISP networks
- mainland China (Great Firewall)


# Milestone: Platform Migration (Google → Wix) — ✅ Completed

- [x] Migrate the website from Google Sites to Wix.
- [x] Move DNS management to Wix.
- [x] Migrate the Wix account from the Russian region to the Turkish region.
- [x] Validate Wix origin accessibility from Russia and mainland China using browser waterfall analysis and curl timing.

**Note:** Wix officially discontinued operations in Russia in 2024.


# Milestone: CDN & DNS Layer (Cloudflare DNS) — ⚠️ Historical

- [x] Delegate NS records to Cloudflare.
- [x] Configure DNS records for Wix origin.
- [x] Deploy minimal Cloudflare configuration (DNS + proxy).
- [x] Test TLS, network routing, and performance from Russia and China.

Initial results were positive.  
However, later testing revealed partial degradation in Russian ISP networks.

**Note:** Cloudflare infrastructure became partially filtered in Russia during 2025.


# Milestone: Cloudflare Tunnel Ingress — ⚠️ Historical

- [x] Deploy an ephemeral Cloudflare Tunnel (`trycloudflare`) for public ingress.
- [x] Migrate to a named tunnel (`cloudflared`).
- [x] Force HTTP/2 transport over IPv4 (`--protocol http2 --edge-ip-version 4`).
- [x] Disable QUIC / UDP ingress due to instability.
- [x] Validate accessibility from Russian networks including LTE/5G.

Partial degradation was later observed in mobile ISP networks.  
This approach was treated as a temporary solution.


# Milestone: Netlify Mirror (iframe ingress) — ⚠️ Historical

- [x] Deploy `ru.ters-team.com` on Netlify.
- [x] Embed the main site via iframe.
- [x] Validate accessibility from Russian networks.

Limitations discovered:
- SEO degradation
- media loading problems
- increased latency

Partial inaccessibility from mainland China was also observed.


# Milestone: Netlify Edge Reverse Proxy — ⚠️ Experiment

- [x] Delegate DNS to Netlify (NS1).
- [x] Implement reverse proxy logic using Edge Functions.
- [x] Attempt unified ingress through the main domain.
- [x] Encounter runtime failures in edge functions.
- [x] SPA runtime issues with Wix assets (JS/CSS domains).
- [x] Confirm filtering of Netlify CDN inside the Great Firewall.

Netlify was removed from the architecture.  
DNS was restored to GoDaddy.


# Milestone: Reverse Proxy Transport Layer (FRP / Docker / HTTP2) — ✅ Completed

- [x] Deploy FRP (Fast Reverse Proxy) as a temporary ingress transport layer.
- [x] Containerize the nginx reverse proxy.
- [x] Implement Docker Compose for local testing.
- [x] Deploy a VPS instance in Singapore (Kamatera).
- [x] Validate accessibility using curl timing and health checks.

This stage allowed rapid experimentation with ingress architecture.


# Milestone: Cloud Infrastructure Evaluation (Kamatera / Render) — ✅ Completed

- [x] Evaluate global accessibility using a single-region VPS (Kamatera).
- [x] Identify routing limitations caused by a single ASN and fixed network paths.
- [x] Test deployment on Render PaaS.

Render demonstrated significantly improved global reachability.


# Milestone: Deterministic Ingress Architecture (Render Production Edge) — ✅ Completed

- [x] Remove managed CDN ingress layers (Cloudflare proxy / Netlify Edge / Gcore).
- [x] Deploy nginx reverse proxy on Render (Docker container).
- [x] Use platform-level ingress routing without CDN-level logic.
- [x] Implement a single public entry point.
- [x] Avoid regional mirrors.

Transport architecture:
```
Client → HTTP/2 → nginx ingress → HTTP/1.1 → Wix origin
```

Additional improvements:
- disable HTTP/3 / QUIC due to DPI filtering
- ensure deterministic TLS handshake
- verify accessibility from Russian ISP networks (including LTE/5G)
- confirm reachability from mainland China
- proxy Wix media CDN to avoid image filtering in Russian networks


# Milestone: CI/CD Automation — ✅ Completed

## Continuous Integration (CI)

- [x] Docker image builds via GitHub Actions.
- [x] nginx configuration validation (`nginx -t`).
- [x] container smoke tests (`docker run` + health endpoints).
- [x] validation of redirect and routing logic.
- [x] Docker layer caching to accelerate CI builds.
- [x] fail-fast pipeline behavior.

## Continuous Deployment (CD)

- [x] separation of CI and CD workflows.
- [x] production deployment via Render deploy hook.
- [x] tag-gated deployment (`vX.Y.Z`).
- [x] verification that tag commit equals `main` branch HEAD.
- [x] concurrency control for production deploys.
- [x] automated smoke testing after deployment.

## Deployment Safety

- [x] liveliness endpoint `/healthz`.
- [x] readiness endpoint `/readyz`.
- [x] post-deploy upstream readiness validation.
- [x] internal nginx upstream verification (`auth_request`).
- [x] deployment failure if upstream returns errors (4xx / 5xx / TLS failures).

## Release Discipline

- [x] semantic versioning (`vX.Y.Z`).
- [x] pre-release versions (`alpha`, `beta`, `rc`).
- [x] production deploy only from tagged commits.

## Pipeline Observability

- [x] GitHub Actions logs used for CI/CD diagnostics.
- [x] curl-based production smoke tests.
- [x] CI tests reproducible locally via Docker.


# Milestone: GeoDNS Experiment (Gcore DNS) — ⚠️ Experiment

- [x] Deploy DNS zone on Gcore.
- [x] Test GeoDNS / dynamic DNS routing.
- [x] Validate accessibility from RU / CN / global networks.
- [x] Detect unstable DNS resolution from mainland China.

Result:
- Gcore DNS removed from architecture
- DNS restored to GoDaddy
- Simplified deterministic DNS used in production
- Avoid the use of GeoDNS


# Milestone: DNS Simplification (Single Ingress IP) — ✅ Completed

- [x] Simplify DNS configuration to a single ingress IP:

```
www.ters-team.com  A  216.24.57.3
ters-team.com      A  216.24.57.3
```

- [x] Handle domain canonicalization at the ingress proxy.

Benefits:
- simpler DNS behavior
- fewer resolver inconsistencies
- improved stability in networks with aggressive DNS caching
- easier diagnostics and operational maintenance
- fallback to other ips from validated ip pull in case of DPI / SNI filtering

**This configuration is currently used in production.**


# Milestone: Monitoring, Logging & SRE — ✅ Completed
- [x] Grafana cloud (nginx / container metrics).
- [x] Logs (Loki or ELK).
- [x] Upstream timing (nginx logs) - latency dashboards.
- [x] Synthetic probes (EU/USA/Asia/RU/CN test nodes).
- [x] SLO/SLA.
- [x] Runbooks, post-mortem documentation.


# Milestone: Alerting — ⚙️ In progress
- [ ] Alerts via Alertmanager (Telegram / Slack).
