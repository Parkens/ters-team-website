FROM nginx:stable-alpine

# cache для proxy_cache (wix-static / _partials / wix-media)
RUN mkdir -p /var/cache/nginx/wix && chown -R nginx:nginx /var/cache/nginx

COPY nginx.conf /etc/nginx/nginx.conf
