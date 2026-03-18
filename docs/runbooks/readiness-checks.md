# Runbook: Readiness Checks

## Purpose
Diagnose `/healthz` and `/readyz` endpoints for the ingress proxy.

## Model
- `/healthz` checks ingress liveliness
- `/readyz` verifies actual availability of the upstream SaaS origin

## Use when
- deployment partially succeeded
- CI is green but CD fails
- `/readyz` returns `404`, `503`, or upstream HTML
- there is suspicion of upstream TLS/SNI/routing issues

## Scenario 1: `/readyz` returns 404 or upstream HTML

### Symptom
```
curl -i https://www.ters-team.com/readyz
```

Possible responses:
- `404`
- Wix HTML page
- any upstream body instead of `ok`

### Cause
`/readyz` is proxied directly to the upstream instead of going through an internal readiness check.

This usually happens when:
- `auth_request` is missing
- the upstream location is not marked as `internal`

### Correct design
```
/readyz
↓
auth_request /_readyz_upstream
↓
internal proxy to upstream
↓
200 ok / 503 upstream not ready
```

### Reference config
```
location = /readyz {
    access_log off;

    auth_request /_readyz_upstream;

    default_type text/plain;
    return 200 "ok\n";
}

location = /_readyz_upstream {
    internal;

    proxy_pass https://wix_origin/;
}
```

### Expected result
`/readyz` returns only:
- `200 ok`
- `503 upstream not ready`

## Scenario 2: CI passes, CD fails on readiness

### Symptom
- CI successfully passes `nginx -t`, `/healthz`, and basic routing checks
- CD fails during the smoke/readiness stage

### Cause
CI validates container configuration locally, while CD additionally checks real upstream availability:
- TCP connect
- TLS handshake
- Host/SNI routing
- HTTP response readiness

### Verification
```
curl -i https://www.ters-team.com/readyz
```

### Interpretation
This is expected behavior for readiness-gated deployments.  
If the upstream is temporarily unavailable, `/readyz` must return `503`.

## Scenario 3: Upstream seems reachable, but `/readyz` returns 503

### Symptom
- `curl https://www.ters-team.com/readyz` → `503 upstream not ready`
- direct access to the upstream hostname works

### Cause
The readiness check uses the same routing context as real user traffic:
- Host
- SNI
- canonical domain mapping

The upstream may be alive but not accept the required Host/SNI combination.

### Verification
```
curl -I https://andyparkens.wixsite.com -H "Host: www.ters-team.com"
```

### Expected interpretation
If this request does not behave correctly, the problem is not upstream liveliness but tenant routing, TLS, or Host handling.

## Operational rule
- use `/healthz` for platform liveliness
- use `/readyz` for deployment validation and user-path readiness

### Notes
`/readyz` intentionally verifies the full upstream routing path including:

- DNS resolution
- TCP connectivity
- TLS handshake
- SNI routing
- HTTP response availability
