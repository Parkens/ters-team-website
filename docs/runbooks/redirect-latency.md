# Runbook: Redirect Latency

## Purpose
Diagnose high page-load latency caused by HTTP redirect chains.

## Use when
- Lighthouse or WebPageTest reports high Redirect Time
- the site loads slowly from China
- multiple sequential redirects are observed

## Typical redirect chain
```
http://ters-team.com
↓
https://ters-team.com
↓
https://www.ters-team.com
↓
200 OK
```

Each redirect adds **one RTT**.

In high-latency networks (for example, China):
```
1 redirect ≈ 300–700 ms
```

Three redirects may add:
```
1.5–2 seconds of latency
```

## Diagnose redirect chain
```
curl -I -L https://ters-team.com
```

Or:
```
curl -v https://ters-team.com
```

## Recommended architecture
Redirects should be handled **at the ingress proxy**, not at the SaaS origin.

Benefits:
- deterministic behavior
- lower latency variability
- full control over redirect logic

## Example nginx configuration
```
server {
    listen 80;

    return 301 https://www.ters-team.com$request_uri;
}

server {
    listen 443 ssl;

    if ($host != "www.ters-team.com") {
        return 301 https://www.ters-team.com$request_uri;
    }
}
```

## Alternative (rejected)
Rely entirely on canonical redirects from the SaaS origin (for example, Wix).

### Why rejected
- behavior may be non-deterministic
- additional redirects may occur
- the SaaS origin may change redirect logic

## Expected result
After optimization:
```
Client
↓
Ingress proxy
↓
200 OK
```

Or at most **one redirect**:
```
https://ters-team.com
↓
https://www.ters-team.com
↓
200 OK
```

### Operational recommendation:
When sharing links publicly (buisness cards, presentations, papers, QR codes), prefer:
```
https://www.ters-team.com
```
This avoids the additional redirect RTT.
