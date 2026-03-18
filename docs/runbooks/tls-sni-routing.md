# Runbook: TLS / SNI / Host Routing

## Purpose
Diagnose TLS handshake failures and Host/SNI routing issues when proxying a multi-tenant SaaS origin.

## Use when
- nginx returns `502 Bad Gateway`
- TLS handshake errors appear in logs
- readiness checks fail while the upstream is alive
- the upstream uses multi-tenant routing (Wix, Shopify, Notion, etc.)

## Scenario 1: TLS/SNI mismatch

### Symptom
nginx error log:
```
SSL_do_handshake() failed
no alternative certificate subject name matches target host name
```

Or external symptoms:
- `502 Bad Gateway`
- intermittent TLS failures

### Cause
The upstream uses SNI to select the certificate and tenant routing.  
If `proxy_ssl_server_name on` is not enabled or Host/SNI are passed incorrectly, the TLS handshake fails.

### Fix
Ensure the following directives are enabled:
```
proxy_ssl_server_name on;
proxy_ssl_name $host;
proxy_set_header Host $host;
```

If a separate upstream host is used, verify consistency between:
- DNS target
- SNI name
- Host header
- canonical domain mapping on the SaaS origin

### Verification
```
curl -v https://www.ters-team.com --resolve www.ters-team.com:443:IP
curl -I https://andyparkens.wixsite.com -H "Host: www.ters-team.com"
```

### Expected result
- the handshake succeeds
- the certificate matches the expected hostname
- the upstream routes the request correctly

## Scenario 2: Full proxy chain validation

### Purpose
Validate the full request chain:
DNS → ingress IP → TLS handshake → SNI → HTTP response → redirects

### Command
```
curl -v https://www.ters-team.com --resolve www.ters-team.com:443:216.24.57.3
```

### What to inspect
- whether the TLS handshake was established
- which certificate was returned
- whether a redirect occurred
- which HTTP status was returned
- whether there are signs of incorrect Host/SNI routing

### Expected result
- handshake completed successfully
- HTTP response matches expectations
- redirect chain is deterministic and predictable
