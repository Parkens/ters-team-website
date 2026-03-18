# Runbook: sub_filter Rewrite Issues

## Purpose
Diagnose problems with rewriting HTML/CSS/JS using nginx `sub_filter` when reverse-proxying a SaaS origin.

## Use when
- links in HTML are not rewritten
- the proxy works but resources load from the original origin
- `sub_filter` appears to have no effect
- browser DevTools show original URLs in returned HTML

## Scenario 1: sub_filter does not modify content

### Symptom
HTML/CSS are returned from the upstream, but links are not rewritten.

Example:  
`https://www.ters-team.com` is not replaced with the local proxy endpoint.

### Cause
The upstream returns the response in compressed form (`gzip` or `brotli`).  
nginx cannot apply `sub_filter` to a compressed response body.

## Fix
Disable compression from the upstream:
```
proxy_set_header Accept-Encoding "";
```

This forces the upstream to return **plain text**, allowing nginx to apply `sub_filter`.

## Reference configuration
```
proxy_set_header Accept-Encoding "";

sub_filter_once off;
sub_filter 'https://www.ters-team.com
' 'http://localhost:8080
';

sub_filter_types text/html text/css application/javascript;
```

## Verification
```
curl -s https://www.ters-team.com | grep localhost
```

Alternatively, inspect the HTML in the browser via **DevTools → Network → Response**.

## Notes
- gzip compression can remain enabled **for the client**, but **not for the upstream**
- `sub_filter` works only with the specified MIME types
- `sub_filter_once off` allows rewriting multiple matches

## Log noise: duplicate MIME type

### Symptom
nginx log:
```
duplicate MIME type "text/html"
```

### Cause
`text/html` is already enabled by default in nginx.

### Fix
```
sub_filter_types text/css application/javascript;
```

### Impact
No functional impact; this only reduces log noise.
