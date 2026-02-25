FROM nginx:stable-alpine

RUN mkdir -p /var/cache/nginx/wix && chown -R nginx:nginx /var/cache/nginx

COPY nginx.conf /etc/nginx/nginx.conf
