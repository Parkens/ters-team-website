FROM grafana/alloy:latest AS alloy

FROM nginx:stable-alpine

COPY --from=alloy /bin/alloy /usr/local/bin/alloy

RUN mkdir -p /etc/alloy /var/log/nginx /var/lib/alloy/data

COPY nginx.conf /etc/nginx/nginx.conf
COPY config.alloy /etc/alloy/config.alloy
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
