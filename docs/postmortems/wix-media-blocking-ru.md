# Postmortem: Wix Media CDN Blocking in Russian Networks

## Incident summary
The website loaded correctly, but images did not appear for users in Russia.

## Symptoms
- the SPA runtime works
- JS and CSS load normally
- images do not display

The issue was observed only in Russian networks.

## Investigation
Network request inspection showed that images were loaded from:
```
media.wixstatic.com
static.wixstatic.com
```

Requests to these domains were:
- blocked
- or reset by some ISPs

## Root cause
Selective filtering of Wix media CDN domains by certain Russian providers.

The main website uses different domains and was not affected by the filtering.

## Resolution
Images were proxied through the nginx ingress.
```
location /wix-media/ {
    proxy_pass https://static.wixstatic.com/media/;
}
```
Media URLs were rewritten to pass through the proxy path:
```
/wix-media/
```

## Result
- images loaded through the main ingress path
- the site became fully functional from Russia

## Lessons learned
- media CDN domains may be filtered independently of the main site
- proxying assets through the ingress layer may be required to ensure reachability
