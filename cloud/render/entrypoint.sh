#!/bin/sh
set -eu

# allow overriding entrypoint command (`docker run image nginx -t`)
if [ "$#" -gt 0 ]; then
  exec "$@"
fi

GEOIP_DIR="/etc/alloy/geoip"
COUNTRY_DB="$GEOIP_DIR/ip-to-country.mmdb"
ASN_DB="$GEOIP_DIR/ip-to-asn.mmdb"

COUNTRY_URL="https://raw.githubusercontent.com/iplocate/ip-address-databases/main/ip-to-country/ip-to-country.mmdb"
ASN_URL="https://raw.githubusercontent.com/iplocate/ip-address-databases/main/ip-to-asn/ip-to-asn.mmdb"

mkdir -p /var/log/nginx /var/lib/alloy/data "$GEOIP_DIR"
touch /var/log/nginx/access.json

download_geoip() {
  echo "Updating GeoIP databases..."

  tmp_country="$(mktemp)"
  tmp_asn="$(mktemp)"

  if curl -fsSL "$COUNTRY_URL" -o "$tmp_country"; then
    mv "$tmp_country" "$COUNTRY_DB"
    echo "Country DB updated"
  else
    echo "Country DB update failed"
    rm -f "$tmp_country"
  fi

  if curl -fsSL "$ASN_URL" -o "$tmp_asn"; then
    mv "$tmp_asn" "$ASN_DB"
    echo "ASN DB updated"
  else
    echo "ASN DB update failed"
    rm -f "$tmp_asn"
  fi
}

# initial download
download_geoip || true

# background updater (every 24h)
(
  while true; do
    sleep 86400
    download_geoip || true
  done
) &
GEOIP_UPDATER_PID="$!"

alloy run \
  --server.http.listen-addr=127.0.0.1:12345 \
  --storage.path=/var/lib/alloy/data \
  /etc/alloy/config.alloy &
ALLOY_PID="$!"

term_handler() {
  kill -TERM "$ALLOY_PID" 2>/dev/null || true
  kill -TERM "$GEOIP_UPDATER_PID" 2>/dev/null || true
  wait "$ALLOY_PID" 2>/dev/null || true
  wait "$GEOIP_UPDATER_PID" 2>/dev/null || true
  exit 0
}

trap term_handler INT TERM

nginx -g 'daemon off;' &
NGINX_PID="$!"

wait "$NGINX_PID"

kill -TERM "$ALLOY_PID" 2>/dev/null || true
kill -TERM "$GEOIP_UPDATER_PID" 2>/dev/null || true
wait "$ALLOY_PID" 2>/dev/null || true
wait "$GEOIP_UPDATER_PID" 2>/dev/null || true
