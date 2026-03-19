#!/bin/sh
set -eu

# allow overriding entrypoint command (`docker run image nginx -t`)
if [ "$#" -gt 0 ]; then
  exec "$@"
fi

mkdir -p /var/log/nginx /var/lib/alloy/data
touch /var/log/nginx/access.json

alloy run \
  --server.http.listen-addr=127.0.0.1:12345 \
  --storage.path=/var/lib/alloy/data \
  /etc/alloy/config.alloy &
ALLOY_PID="$!"

term_handler() {
  kill -TERM "$ALLOY_PID" 2>/dev/null || true
  wait "$ALLOY_PID" 2>/dev/null || true
  exit 0
}

trap term_handler INT TERM

nginx -g 'daemon off;' &
NGINX_PID="$!"

wait "$NGINX_PID"

kill -TERM "$ALLOY_PID" 2>/dev/null || true
wait "$ALLOY_PID" 2>/dev/null || true
