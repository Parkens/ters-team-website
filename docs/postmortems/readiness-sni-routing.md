# Postmortem: Readiness Check Failure due to Host/SNI Routing

## Incident summary
The CI pipeline passed successfully, but deployment failed during the readiness check stage.

## Symptoms
```
/healthz → 200
/readyz → 503
```

At the same time, the Wix upstream was reachable when accessed directly.

## Investigation
CI validated:
- nginx configuration
- container startup
- basic routing

CD validated:
- upstream connectivity
- TLS handshake
- Host/SNI routing

## Root cause
Wix uses multi-tenant routing.

The readiness check was executed using the same:
- Host
- SNI

as real user traffic.

If the upstream did not accept this routing combination, the readiness endpoint returned `503`.

## Resolution
An internal readiness proxy was implemented.
```
/readyz
↓
auth_request /_readyz_upstream
↓
internal upstream request
```

This approach allows:
- validation of the real upstream routing path
- assurance that the user traffic path will function correctly

## Result
- the readiness check accurately reflected upstream availability
- the deployment pipeline became more reliable

## Lessons learned
- readiness checks must validate the real user traffic path
- SaaS multi-tenant routing can break naive health checks
