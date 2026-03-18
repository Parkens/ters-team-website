# Postmortem: DNS Provider Incompatibility (Gcore DNS)

## Incident summary
During DNS infrastructure experiments, the authoritative DNS provider was temporarily moved from GoDaddy to Gcore DNS.

After the migration, the website became intermittently inaccessible from mainland China.

The same domain configuration worked correctly when the DNS zone was hosted on GoDaddy.

## Symptoms
From mainland China:
- DNS queries returned inconsistent results
- some resolvers failed to resolve the domain
- connection attempts failed even though the ingress infrastructure was operational

Tests showed:
- successful connectivity from Europe and Russia
- inconsistent or failed DNS resolution from Chinese networks

Example test:
```
dig www.ters-team.com
```
Return 200 for RU/EU/US IPs

But for CN testers this returned no answer or inconsistent responses.

## Investigation
Several checks were performed using specialized tools:
- WebSitePulse
- AppInChina
- Itdog

Ingress connectivity was also tested directly:
```
curl --resolve www.ters-team.com:443:216.24.57.1 https://www.ters-team.com
```

The ingress proxy was reachable, indicating that the issue was not related to:
- nginx configuration
- Render ingress
- upstream SaaS routing

Additional experiments included:
- switching the DNS provider back to GoDaddy
- temporarily changing NS records to force resolver cache invalidation

## Root cause
Some Chinese recursive resolvers behaved inconsistently when resolving records from the Gcore DNS infrastructure.

Possible contributing factors include:
- resolver filtering policies
- DNS infrastructure reachability
- recursive resolver caching behavior

The exact filtering mechanism could not be fully determined.

However, repeated tests confirmed that:
- the domain consistently resolved when authoritative DNS was hosted on GoDaddy
- the issue disappeared immediately after switching back.

## Resolution
The authoritative DNS provider was restored to GoDaddy.

Final DNS architecture:
```
www.ters-team.com → A → 216.24.57.3
ters-team.com     → A → 216.24.57.3
```

This configuration proved stable across:
- Russia
- mainland China
- Asia
- Europe
- US

## Result
- DNS resolution became stable across all tested regions
- synthetic monitoring confirmed consistent accessibility

## Lessons learned
- DNS provider choice can affect reachability in filtering environments
- GeoDNS or advanced DNS routing may introduce unpredictable behavior
- simple DNS architectures often provide more predictable global behavior
