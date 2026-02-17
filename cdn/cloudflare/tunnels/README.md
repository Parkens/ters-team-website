# Cloudflare Tunnel

## Временный туннель
cloudflared tunnel --url http://localhost:8080

# Запуск с конфигом
cloudflared tunnel --config ./tunnels/configs/tunnel_ephemeral.yml run

## Именной туннель

# Авторизация и создание
cloudflared login
cloudflared tunnel create ters-proxy-tunnel

# Список туннелей
cloudflared tunnel list

# Запуск с конфигом
cloudflared tunnel --config ./tunnels/configs/tunnel_named.yml run