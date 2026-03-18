# Runbook: Render Deployment and Ingress Validation

## Purpose
Operational steps to verify correct deployment of the ingress proxy on Render.

## Use when
- a new deployment finished but behaves unstable
- Render shows a healthy container but the site is unavailable
- there is suspicion of ingress, edge, or routing path issues

## Step 1: Verify service responds externally
```
curl -I https://www.ters-team.com
```

### Expected
- the service responds
- the redirect chain matches expectations
- no platform-level timeout occurs

## Step 2: Verify health endpoints
```
curl -i https://www.ters-team.com/healthz
curl -i https://www.ters-team.com/readyz
```

### Expected
- `/healthz` → `200`
- `/readyz` → `200` or `503` if the upstream is not ready

### Step 3: Validate logs

Locally:
```
docker compose logs -f ters-proxy
```

On Render:
- check logs in the Render dashboard → Logs

### Look for
- `connect() failed`
- `SSL_do_handshake() failed`
- resolver errors
- port or `listen` misconfiguration

## Step 4: Compare custom domain vs Render origin
```
curl -I https://www.ters-team.com
curl -I https://<render-service>.onrender.com
```

### Interpretation
- if `onrender.com` is noticeably more stable or faster, the issue may be in the custom domain path, DNS, or edge routing
- if both paths degrade equally, the problem is more likely closer to the upstream or the global network path

## Step 5: Inspect Anycast / edge hints
```
curl -I https://www.ters-team.com
```

### Inspect headers
- `x-render-origin-server`
- `x-served-by`
- `cf-ray` (if a transit edge is present)

### Interpretation
These headers help identify which edge or routing path served the request.

## Notes
Render improves global reachability using Anycast and routing topology, but the exact network path is not fully deterministic and may change depending on the BGP route.
