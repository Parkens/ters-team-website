#!/bin/sh
set -eu

# allow overriding entrypoint command (`docker run image nginx -t`)
if [ "$#" -gt 0 ]; then
  exec "$@"
fi

mkdir -p /var/log/nginx /var/lib/alloy/data /etc/alloy/geoip
touch /var/log/nginx/access.json

COUNTRY_DB="/etc/alloy/geoip/ip-to-country.mmdb"
ASN_DB="/etc/alloy/geoip/ip-to-asn.mmdb"

COUNTRY_URL="https://cdn.jsdelivr.net/npm/@ip-location-db/geolite2-geo-whois-asn-country-mmdb/geolite2-geo-whois-asn-country.mmdb"
ASN_URL="https://cdn.jsdelivr.net/npm/@ip-location-db/geolite2-asn-mmdb/geolite2-asn.mmdb"

download_file() {
  url="$1"
  dst="$2"

  tmp="$(mktemp)"

  if curl -fsSL --max-time 20 "$url" -o "$tmp"; then
    if [ -s "$tmp" ]; then
      mv "$tmp" "$dst"
      return 0
    fi
  fi

  rm -f "$tmp"
  return 1
}

echo "Updating GeoIP databases..."

COUNTRY_OK=0
ASN_OK=0

if download_file "$COUNTRY_URL" "$COUNTRY_DB"; then
  echo "Country DB updated"
  COUNTRY_OK=1
else
  echo "Country DB update failed"
fi

if download_file "$ASN_URL" "$ASN_DB"; then
  echo "ASN DB updated"
  ASN_OK=1
else
  echo "ASN DB update failed"
fi

# start nginx immediately for Render/GitHub health checks
nginx -g 'daemon off;' &
NGINX_PID="$!"

# choose Alloy config depending on GeoIP availability
ALLOY_CONFIG="/etc/alloy/config.alloy.no-geoip"
if [ "$COUNTRY_OK" -eq 1 ] && [ "$ASN_OK" -eq 1 ]; then
  ALLOY_CONFIG="/etc/alloy/config.alloy"
  echo "Starting Alloy with GeoIP enrichment"
else
  echo "Starting Alloy without GeoIP enrichment"
fi

alloy run \
  --server.http.listen-addr=127.0.0.1:12345 \
  --storage.path=/var/lib/alloy/data \
  "$ALLOY_CONFIG" &
ALLOY_PID="$!"

# background updater every 24h
(
  while true; do
    sleep 86400

    echo "Refreshing GeoIP databases..."

    if download_file "$COUNTRY_URL" "$COUNTRY_DB"; then
      echo "Country DB refreshed"
    else
      echo "Country DB refresh failed"
    fi

    if download_file "$ASN_URL" "$ASN_DB"; then
      echo "ASN DB refreshed"
    else
      echo "ASN DB refresh failed"
    fi
  done
) &
GEOIP_UPDATER_PID="$!"

term_handler() {
  kill -TERM "$ALLOY_PID" 2>/dev/null || true
  kill -TERM "$GEOIP_UPDATER_PID" 2>/dev/null || true
  kill -TERM "$NGINX_PID" 2>/dev/null || true

  wait "$ALLOY_PID" 2>/dev/null || true
  wait "$GEOIP_UPDATER_PID" 2>/dev/null || true
  wait "$NGINX_PID" 2>/dev/null || true
  exit 0
}

trap term_handler INT TERM

wait "$NGINX_PID"

kill -TERM "$ALLOY_PID" 2>/dev/null || true
kill -TERM "$GEOIP_UPDATER_PID" 2>/dev/null || true
wait "$ALLOY_PID" 2>/dev/null || true
wait "$GEOIP_UPDATER_PID" 2>/dev/null || true
