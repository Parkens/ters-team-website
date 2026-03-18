# Postmortem: DNS Poisoning and GFW Connectivity Issues

## Incident summary
During testing of website accessibility from mainland China, the domain name showed unstable behavior.

Sometimes the site was reachable, while at other times the connection reset or DNS returned unexpected results.

## Symptoms
The following symptoms were observed:
- unstable TLS handshake
- `connection reset`
- the site sometimes loaded, sometimes failed

DNS checks returned inconsistent responses.

## Investigation
The following checks were performed:
```
dig www.ters-team.com
dig www.ters-team.com @8.8.8.8
dig www.ters-team.com @1.1.1.1
```

Direct IP access was also tested:
```
curl -I https://www.ters-team.com --resolve www.ters-team.com:443:IP
```

In some cases, direct IP access worked while domain-based access remained unstable.

External tools were also used:
- GreatFire
- OONI Probe
- Globalping
- DNS Checker

## Root cause
The Great Firewall may apply several filtering mechanisms:
- DNS poisoning
- TCP reset
- TLS fingerprint filtering
- selective IP blocking

In some situations DNS responses may be replaced or delayed, resulting in unstable domain-based connectivity.

## Resolution
The following methods were used for diagnosis and mitigation:
- testing IP access with `curl --resolve`
- comparing results across multiple DNS resolvers
- testing from external vantage points

A decision was also made to avoid complex CDN routing mechanisms that could complicate diagnostics.

## Result
- website accessibility from China became more predictable
- network diagnostics became faster and clearer

## Lessons learned
- DNS filtering can behave inconsistently
- testing the IP path helps distinguish DNS issues from network problems
- global services should be tested from multiple geographic regions
