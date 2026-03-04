# Troubleshooting

## IPv6 у upstream (Nginx)
**Симптом:** в логах контейнера:
```
connect() failed (101: Network unreachable) upstream: "https://[2606:4700:...]:443"
```
**Причина:** резолв AAAA и отсутствие IPv6-маршрута.
**Фикс (nginx.conf):**
```
resolver 1.1.1.1 8.8.8.8 valid=300s ipv6=off;
proxy_ssl_server_name on;
proxy_set_header Host www.ters-team.com;
proxy_set_header Accept-Encoding "";
sub_filter_once off;
sub_filter 'https://www.ters-team.com' 'http://localhost:8080';
sub_filter_types text/html text/css application/javascript;
```

## trycloudflare: QUIC/UDP/IPv6
**Симптом:** `failed to accept QUIC stream`, `timeout: no recent network activity`.
**Причина:** WSL2/мобильные сети фильтруют UDP/QUIC/IPv6.
**Фикс (cloudflared):**
```
cloudflared tunnel --url http://localhost:8080 --protocol http2 --edge-ip-version 4
```

## Netlify Edge Function: падение при переадресации
**Симптом:** страница "This edge function has crashed", `uncaught exception`.
**Причина:** некорректный rewrite и/или обработка `event.request.url`.
**Шаги:**
- Локальная отладка: `netlify dev --edge-handlers` + `console.log`.
- Проверить парсинг URL/хедеров, валидацию путей, обработку ошибок.

## Netlify частично недоступен из КНР
**Симптом:** GreatFire/OONI показывают `Connection Reset`, `DNS poisoning`.
**Причина:** GFW фильтрует CDN Netlify.
**Решение:** вернуться на Wix DNS/хостинг и/или перенести proxy на VPS в нейтральной зоне.

## Проверочные команды
```
# HTTP заголовки/время:
curl -I -L https://ters-team.com
curl -w "time_connect: %{time_connect}\nstarttransfer: %{time_starttransfer}\n" -o /dev/null -s https://ru.ters-team.com

# DNS/NS:
nslookup -type=ns ters-team.com
nslookup ru.ters-team.com

# Логи контейнера:
docker compose logs -f ters-proxy
```

## TLS/SNI mismatch при проксировании Wix
**Симптом:** `502 Bad Gateway` или в логах nginx: `SSL_do_handshake() failed no alternative certificate subject name matches target host name`
**Причина:** Wix использует SNI для выбора сертификата. При проксировании без `proxy_ssl_server_name on` или с неправильным Host - TLS рукопожатие ломается.
**Фикс:**
```
proxy_ssl_server_name on;
proxy_ssl_name $host;
proxy_set_header Host $host;
```
**Комментарий:**
Критично при проксировании multi-tenant SaaS (Wix, Notion, Shopify и т.п.).

## Медленный первый байт (TTFB) из КНР при проксировании SaaS
**Симптом:** `time_connect` нормальный, `time_starttransfer` 2–4+ секунды (особенно из Китая)
**Причина:**
- SaaS-origin (Wix) находится за AWS/Akamai
- GFW не блокирует, но деградирует TCP window/congestion control
- При повторных запросах ситуация улучшается
**Что НЕ помогает:**
- HTTP/2 к upstream
- aggressive keepalive
- gzip к upstream
**Что помогает:**
- Минимизация количества запросов (layout - static image)
- Уменьшение DOM/sections
- Отказ от iframe / chained proxies
- Облачная edge-платформа с хорошими маршрутами (Render cloud)
**Статус:** Оптимизировано на уровне контента + выбор хостинга.

## HTTP - HTTPS - www редиректы: лишняя латентность
**Симптом:** Lighthouse/WebPageTest показывает Redirect Time: ~1.5–2s, Особенно заметно в КНР
**Причина:** Дополнительный RTT на каждый redirect. В Китае RTT ×2–3 от Европы/США
**Решение (принятое):** Сделать редирект на стороне reverse-proxy, не отдавать канонизацию Wix-у
**Альтернатива (отклонена):** Убрать редирект и надеяться на Wix canonical logic - нестабильно, не детерминировано

## sub_filter + gzip: контент не переписывается
**Симптом:** HTML/CSS приходит, но ссылки не заменяются, `sub_filter` «не срабатывает»
**Причина:** upstream отдаёт gzip/br, nginx не может делать `sub_filter` по сжатому телу
**Фикс:** `proxy_set_header Accept-Encoding ""`
**Важно:** gzip включаем только к клиенту, upstream - всегда plain text

## wix-thunderbolt/layout.js долго грузится
**Симптом:** wix-thunderbolt или layout.js 2–4 секунды, особенно видно в Network waterfall
**Причина:** runtime Wix SPA тянется с Wix CDN, а проксирование ломает часть логики (уже подтверждено)
**Решение:**
- Не проксировать JS runtime Wix
- Убрать layout (hero - static image)
**Статус:**
- Решено на уровне дизайна (самое эффективное решение).

## Render vs VPS: различие в сетевой модели
**Симптом:**
- На VPS (Kamatera) хуже скорость из КНР/РФ
- На Render - стабильно лучше без тонкой настройки
**Причина:**
Render использует:
- Anycast / smart routing
- оптимизированные egress-пути
- VPS = один ASN, один маршрут
**Вывод:** Проблема была не в nginx, а в сетевой топологии
**Статус:** Зафиксировано, принято как архитектурное решение

## Контейнер стартует, но сайт недоступен (Render)
**Симптом:** Container healthy, но HTTP 502/timeout
**Причина:** nginx слушает не $PORT, а Render проксирует только на заданный порт
**Фикс:** listen ${PORT} или EXPOSE 10000
**Комментарий:** типичная ошибка при миграции с VPS - PaaS

## Диагностика из РФ/КНР (рекомендуемый минимум)
### Проверка TLS/SNI
curl -v https://www.ters-team.com --resolve www.ters-team.com:443:IP
### Проверка TTFB
curl -w "@curl-format.txt" -o /dev/null -s https://www.ters-team.com
### Проверка media
curl -I https://www.ters-team.com/wix-media/...

## Изображения Wix не загружаются в РФ
**Симптом:** 
- Сайт полностью работает (SPA, карусели, меню, JS)
- Изображения (hero, carousel, custom media) не отображаются только в РФ
**Причина:** 
- Фильтрация image CDN Wix или сторонних media-hosts со стороны провайдеров РФ
- Функционал Wix (JS/CSS) грузится с других доменов, не попавших под блокировки
**Подтверждение:** 
- Из Китая - работает
- Из РФ - блокируются только media-запросы (media.wixstatic.com, static.wixstatic.com).
**Решения:** Reverse-proxy media через nginx (proxy_pass для image-хостов) или перенос изображений на собственный CDN/VPS
**Статус:** Проблема решена настройкой proxy_pass и sub_filter.

## /readyz возвращает 404 или HTML Wix вместо "ok"
**Симптом:**
- curl https://www.ters-team.com/readyz возвращает HTTP/2 404 или HTML-страницу Wix
**Причина:**
- `/readyz` проксируется напрямую на upstream Wix вместо internal readiness-check. Это происходит если:
    - отсутствует `auth_request`
    - upstream location не помечен `internal`
В этом случае nginx отдаёт реальный ответ Wix.
**Правильная схема:**
```
/readyz
↓
auth_request /_readyz_upstream
↓
internal proxy to Wix
```
**Правильная конфигурация:**
```nginx
location = /readyz {
    access_log off;

    auth_request /_readyz_upstream;

    default_type text/plain;
    return 200 "ok\n";
}

location = /_readyz_upstream {
    internal;

    proxy_pass https://wix_origin/;
}
```
**Комментарий:** `/readyz` должен возвращать только 200 или 503, а не upstream HTML.

## CI зелёный, но CD падает на readiness (`/readyz`)
**Симптом:** GitHub CI: nginx -t, /healthz, routing checks - проходят, однако CD: Smoke test FAILED: service didn't become ready.
**Причина:**
- CI проверяет только локальный контейнер
- CD дополнительно проверяет: доступность Wix upstream, TLS handshake, правильный Host/SNI routing
- Если Wix временно недоступен или сеть деградировала - `/readyz` вернёт 503
**Проверка:**
- curl -i https://www.ters-team.com/readyz
**Комментарий:** Это ожидаемое поведение readiness-gated deployment.

## Wix доступен, но /readyz возвращает 503
**Симптом:**
- curl https://www.ters-team.com/readyz - HTTP 503 upstream not ready
- curl https://andyparkens.wixsite.com - работает
**Причина:** Readiness-проверка выполняется с тем же Host/SNI, что пользовательский трафик:
- Host: www.ters-team.com
- SNI: andyparkens.wixsite.com
Если Wix не принимает этот Host routing - readiness падает.
**Проверка:** curl -I https://andyparkens.wixsite.com -H "Host: www.ters-team.com".
**Комментарий:** Это защищает от ошибок multi-tenant routing у SaaS origin.

## duplicate MIME type "text/html"
**Симптом:** В логах nginx: duplicate MIME type "text/html".
**Причина:** sub_filter_types включает text/html, который уже добавлен nginx по умолчанию.
**Фикс:** sub_filter_types text/css;
**Комментарий:** Не влияет на работу, но уменьшает шум в логах.

## Полная диагностика reverse-proxy цепочки (DNS → TLS → SNI → HTTP)
**Команда:** curl -v https://www.ters-team.com --resolve www.ters-team.com:443:IP, где IP - IP ingress-сервера.
**Что показывает:** DNS bypass, TLS handshake, SNI routing, HTTP response, redirect chain.
**Пример:** curl -v https://www.ters-team.com --resolve www.ters-team.com:443:216.24.x.x.
**Когда использовать:** подозрение на DNS poisoning, проверка TLS/SNI, диагностика CDN / Anycast маршрута.

## Anycast routing деградация (Render / PaaS edge)
**Симптом:**
- из Европы сайт работает быстро
- из РФ или КНР TTFB резко увеличивается
- `curl` показывает нормальный `time_connect`, но высокий `time_starttransfer` (time_connect: 0.25 / time_starttransfer: 3.8)
**Причина:** Anycast ingress-платформы (Render/Fly/Cloudflare) могут менять edge POP в зависимости от BGP-маршрутов.
В отдельных случаях трафик может:
- идти через неоптимальный POP
- проходить дополнительный транзит
- деградировать из-за маршрута через GFW.
**Проверка POP:**
curl -I https://www.ters-team.com
Смотреть заголовки:
```
x-render-origin-server
x-served-by
cf-ray (если используется Cloudflare edge)
```
**Traceroute диагностика:** traceroute www.ters-team.com или mtr -rw www.ters-team.com
**Проверка альтернативного пути:** curl -I https://<render-service>.onrender.com
Если origin быстрее — проблема в DNS / CDN / Anycast маршрутизации.
**Комментарий:** Это не ошибка nginx или контейнера, а эффект глобальной маршрутизации.

## DNS poisoning / GFW filtering detection
**Симптом:**
- сайт недоступен только из КНР
- или работает нестабильно
- `curl` иногда возвращает `connection reset`
**Проверка DNS:**
- dig www.ters-team.com
- dig www.ters-team.com @8.8.8.8
- dig www.ters-team.com @1.1.1.1
Если ответы отличаются — возможен DNS poisoning.
**Проверка IP напрямую:**
- curl -I https://www.ters-team.com --resolve www.ters-team.com:443:IP
Если IP работает, а домен нет — проблема в DNS.
**Проверка из внешних vantage points:**
- GreatFire
- OONI Probe
- Globalping
- RIPE Atlas
**Типичные признаки GFW:**
- TCP RST после TLS ClientHello
- нестабильный handshake
- DNS ответы с неправильным IP
**Комментарий:** GFW может фильтровать: конкретные IP, ASN, CDN, DNS, TLS fingerprint - поэтому важно проверять и DNS, и IP напрямую.
