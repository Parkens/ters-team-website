# Postmortem: Root Domain Redirect Latency

## Incident summary
Initial tests showed higher latency for users accessing the root domain:
```
https://ters-team.com
```
compared to the canonical domain:
```
https://www.ters-team.com
```

## Symptoms
Synthetic tests showed an additional redirect stage:
```
https://ters-team.com
↓
https://www.ters-team.com
```

In high-latency environments (such as mainland China), this introduced:
```
~500–1500 ms additional latency
```

## Investigation
Network timing measurements showed that each redirect adds one RTT.

Example measurement:
```
curl -w "redirect: %{time_redirect}\n" -o /dev/null -s https://ters-team.com
```

In networks with high RTT, this became noticeable.

## Root cause
The architecture intentionally canonicalizes the `www` subdomain.

Root domain traffic therefore requires an HTTP redirect.

## Resolution
Operational guidance was updated.

All public references should use:
```
https://www.ters-team.com
```

This avoids the redirect and improves first-load latency.

## Lessons learned
- canonical domain design affects latency in high-RTT regions
- minimizing redirect chains improves global performance
