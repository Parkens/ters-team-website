FROM grafana/alloy:latest AS alloy

FROM nginx:stable

COPY --from=alloy /usr/bin/alloy /usr/local/bin/alloy

RUN mkdir -p /etc/alloy /var/log/nginx /var/lib/alloy/data /etc/alloy/geoip \
    && apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY nginx.conf /etc/nginx/nginx.conf
COPY config.alloy /etc/alloy/config.alloy
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
