# Дорожная карта platform/network-инфраструктуры (www.ters-team.com)

## Milestone: Platform migration (Google - Wix) — ✅ выполнено
- [x] Миграция веб-сайта с Google Sites на Wix (устранение фильтрации GFW origin-доменов Google).
- [x] Перенос DNS-управления с GoDaddy на Wix.
- [x] Миграция аккаунта Wix из российской зоны в турецкую (в связи с уходом Wix из РФ).
- [x] Проверка доступности Wix-origin из РФ и КНР (browser-level waterfall, curl timing).
### Примечание: в 2024 году Wix полностью ушел из РФ

## Milestone: CDN & DNS Layer (Cloudflare DNS) — ✅ выполнено
- [x] Перенос NS на Cloudflare.
- [x] Настройка CNAME/A записей для Wix origin.
- [x] Минимальный профиль Cloudflare (без proxy logic).
- [x] TLS / Network аудит доступности из РФ и КНР.
- [x] Зафиксировано как production-совместимое решение.
### Примечание: в 2025 году произошла частичная блокировка Cloudflare в РФ

## Milestone: Cloudflare Tunnel (cloudflared ingress) — ✅ выполнено
- [x] Развёртывание ephemeral Cloudflare Tunnel (trycloudflare) для публичного ingress.
- [x] Миграция на named tunnel (cloudflared) для постоянного entrypoint.
- [x] Использование HTTP/2 поверх IPv4 (--protocol http2 --edge-ip-version 4).
- [x] Отказ от QUIC / UDP ingress (нестабильность WSL2 и мобильных сетей РФ).
- [x] Проверка доступности через Cloudflare edge из РФ (включая LTE/5G).
- [x] Частичная деградация доступа с мобильных операторов РФ (подозрение на TLS 1.3 / QUIC filtering).
- [x] Зафиксировано как временное решение.

## Milestone: Netlify Mirror (iframe ingress) — ✅ выполнено
- [x] Развёртывание ru.ters-team.com на Netlify.
- [x] Встраивание основного сайта через iframe.
- [x] Проверка и подтверждение доступности из РФ.
- [x] Выявление ограничений iframe-подхода: SEO деградация / media loading issues / chained latency
- [x] Частичная недоступность из КНР (RST / DNS poisoning).

## Milestone: Netlify Edge Proxy (Edge Functions) — ✅ выполнено
- [x] Перенос NS на Netlify DNS (NS1).
- [x] Настройка Edge Functions для reverse-proxy Wix origin.
- [x] Попытка унифицированного ingress через основной домен.
- [x] Выявление runtime-ошибок (edge function crashed, rewrite issues).
- [x] Некорректная обработка Wix SPA runtime (JS / CSS domains).
- [x] Подтверждение фильтрации Netlify CDN под GFW.
- [x] Отказ от Edge Functions / Netlify CDN; возврат на Wix + Godaddy DNS.

## Milestone: Reverse Proxy, Transport Layer (FRP / Docker / Compose / IPv4 / HTTP2) — ✅ выполнено
- [x] Использование FRP (Fast Reverse Proxy) как временного публичного entrypoint (PoC).
- [x] Контейнеризация nginx reverse proxy.
- [x] Docker-compose для локального запуска.
- [x] Аренда VPS/VM в нейтральном регионе (Kamatera, Сингапур).
- [x] Проверки доступности (curl TTFB/connect), healthcheck, документация.

## Milestone: Cloud (Kamatera/Render) — ✅ выполнено
- [x] Оценка доступности веб-сайта на single-region VPS (Kamatera).
- [x] Выявление сетевых ограничений VPS (single ASN / route degradation).
- [x] Переход на Render cloud (PaaS) для Anycast-доступности.
- [x] Стабильная доступность SPA/JS из РФ (включая LTE/5G) и КНР.

## Milestone: Deterministic Ingress (Render production edge) — ✅ выполнено
- [x] Отказ от managed CDN ingress (Cloudflare proxy / Netlify Edge).
- [x] Деплой nginx reverse-proxy в Render (Docker, always-on instance).
- [x] Использование PaaS-level Anycast без CDN-level routing logic.
- [x] Единый публичный entrypoint (без GeoDNS / country mirrors).
- [x] Контроль транспортного уровня (HTTP/2 (client - proxy), HTTP/1.1 (proxy - Wix origin)).
- [x] Отказ от HTTP/3 / QUIC (DPI filtering в РФ и КНР).
- [x] Предсказуемый TLS handshake (без SaaS-level abstraction).
- [x] Подтверждённая доступность: РФ (включая мобильные LTE/5G сети), Материковый Китай (GFW)
- [x] Корректная работа SPA / JS runtime (Wix Thunderbolt).
- [x] Proxy-pass для Wix media CDN (устранение блокировок изображений в РФ).
- [x] Upstream readiness probe (/readyz) для проверки Wix origin перед завершением deployment.

## Milestone: CI/CD Automation — ✅ выполнено
### Continuous Integration (CI)
- [x] GitHub Actions: Docker build (BuildKit / buildx).
- [x] Проверка синтаксиса nginx (`nginx -t`) внутри контейнера.
- [x] Runtime smoke-test контейнера (`docker run` + health endpoint).
- [x] Проверка routing logic (Host header / canonical redirects).
- [x] Docker layer caching (GitHub Actions cache) для ускорения CI.
- [x] Fail-fast pipeline: остановка CI при любой ошибке конфигурации ingress.
### Continuous Deployment (CD)
- [x] Разделение CI и CD workflow.
- [x] Production deploy через Render deploy hook.
- [x] Tag-gated deployment (`vX.Y.Z` и pre-release tags).
- [x] Проверка соответствия tag → `main` branch HEAD (защита от случайного deploy).
- [x] Concurrency control (исключение параллельных production deploy).
- [x] Deployment smoke-test после rollout.
### Deployment Safety
- [x] Введение liveliness endpoint `/healthz`.
- [x] Введение readiness endpoint `/readyz`.
- [x] Post-deploy readiness validation (origin reachability check).
- [x] Проверка upstream Wix через internal nginx subrequest (`auth_request`).
- [x] Ошибка CI/CD при upstream errors (4xx/5xx/timeout/TLS failure) с помощью `/readyz`.
### Release discipline
- [x] Семантическое версионирование (`vX.Y.Z`).
- [x] Поддержка pre-release (`vX.Y.Z-rc`, `beta`, `alpha`).
- [x] Deploy только через tag (исключение случайных production изменений).
### Pipeline observability
- [x] GitHub Actions logs как основной источник CI/CD диагностики.
- [x] Curl-based smoke tests для production readiness.
- [x] Возможность воспроизведения CI тестов локально через Docker.

## Milestone: Monitoring, Logging & SRE — ⚙️ в работе
- [ ] Grafana cloud (nginx / container metrics).
- [ ] Централизованные логи (Loki или ELK).
- [ ] Alerting (Alertmanager/Telegram).
- [ ] Upstream timing (nginx logs) - latency dashboards.
- [ ] Synthetic probes (RU/CN test nodes).
- [ ] SLO/SLA.
- [ ] Runbooks, post-mortem documentation.
