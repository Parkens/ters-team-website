# Postmortem: Netlify Edge Blocking in Mainland China

## Incident summary
An experiment using Netlify Iframe / Edge Functions and the Netlify CDN revealed partial site inaccessibility from mainland China.

## Symptoms
Tests using:
- GreatFire
- OONI

reported:
- connection resets
- DNS poisoning
- intermittent connectivity

## Investigation
The site was deployed on:
```
Netlify CDN + Iframe / Edge Functions
```

Testing showed:
- the site worked from Europe, Russia and the United States
- connections from China frequently reset or failed

Traceroute and network tests indicated issues within the CDN infrastructure path.

## Root cause
Parts of the Netlify CDN infrastructure appear to be filtered or degraded inside the Great Firewall.

This resulted in:
- unstable TCP connections
- DNS poisoning
- connection resets

## Resolution
The architecture was redesigned.

Netlify CDN was removed from the stack.

New architecture:
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

## Result
- stable accessibility from China
- predictable routing behavior
- full control over L7 proxy behavior

## Lessons learned
- not all global CDNs are equally accessible from China
- CDN edge logic can complicate diagnostics
- in some cases a controllable ingress proxy is more reliable than a managed CDN
