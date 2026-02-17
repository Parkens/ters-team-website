// netlify/edge-functions/proxy.js
// Reverse proxy for Wix via Netlify Edge with stronger rewriting and safer fallbacks.

const ORIGIN_HOST = "andyparkensw.wixsite.com";
const ORIGIN_PATH = "/website";
const ORIGIN_BASE = `https://${ORIGIN_HOST}${ORIGIN_PATH}`;

const HOST_WHITELIST = new Set([
  ORIGIN_HOST,
  "static.wixstatic.com",
  "www.wix.com",
  "wix.com",
  "apps.wix.com",
]);

function isHtml(ct){ return (ct||"").toLowerCase().includes("text/html"); }
function isAssetPath(p){ return /\.(png|jpe?g|gif|webp|svg|ico|css|js|mjs|woff2?|ttf|eot|otf|mp4|webm|avi|mov|map)(\?|$)/i.test(p); }

function normalizeIncomingPath(p){
  if (p === "/") return ORIGIN_PATH + "/";
  if (p.startsWith("/__p__/https/")) return p;
  if (p.startsWith(ORIGIN_PATH + "/")) return p;
  return ORIGIN_PATH + p;
}

function chooseCacheHeaders(pathname, upstreamHeaders){
  const h = new Headers(upstreamHeaders);
  ["content-security-policy","content-security-policy-report-only","x-frame-options","report-to","nel","x-xss-protection","x-content-type-options"].forEach(k=>h.delete(k));
  if (isAssetPath(pathname)) {
    if (!h.has("cache-control")) h.set("cache-control","public, max-age=604800, immutable");
  } else {
    if (!h.has("cache-control")) h.set("cache-control","no-cache");
  }
  return h;
}

function rewriteHtml(html){
  // <base href="https://andy.../website/"> -> <base href="/">
  html = html.replace(/<base\s+href=(['"])https:\/\/andyparkensw\.wixsite\.com\/website\/?\1\s*\/?>/i, '<base href="/" />');

  // protocol-relative -> https
  html = html.replace(/(["'(])\/\/(static\.wixstatic\.com|[\w.-]*wixsite\.com)(\/[^"'()\s>]*)/gi, (m,p1,host,rest)=>`${p1}https://${host}${rest}`);

  // absolute wix urls -> router
  html = html.replace(/https:\/\/((?:static\.wixstatic\.com|[\w.-]*wixsite\.com))([^\s"'<>)]*)/gi, (_m,host,rest)=>`/__p__/https/${host}${rest}`);

  // explicit base to root
  html = html.split(ORIGIN_BASE).join("");

  // fallback: pure host to router
  html = html.split(`https://${ORIGIN_HOST}`).join(`/__p__/https/${ORIGIN_HOST}`);

  // collapse wrong router forms like /__p__/https//host -> /__p__/https/host
  html = html.replace(/\/__p__\/https\/+([a-z0-9.-])/gi, "/__p__/https/$1");

  return html;
}

function targetFromRouter(url){
  const { pathname, search } = url;
  const prefix = "/__p__/https/";
  if (!pathname.startsWith(prefix)) return null;
  let remainder = pathname.slice(prefix.length);
  while (remainder.startsWith("/")) remainder = remainder.slice(1);
  const firstSlash = remainder.indexOf("/");
  const host = firstSlash === -1 ? remainder : remainder.slice(0, firstSlash);
  const rest = firstSlash === -1 ? "/" : remainder.slice(firstSlash);
  if (!host || !HOST_WHITELIST.has(host)) return { error: new Response("Host not allowed", { status: 403 }) };
  return { url: `https://${host}${rest}${search}` };
}

export default async function proxy(request){
  try{
    const url = new URL(request.url);

    if (url.pathname === "/__healthz") {
      return new Response("ok", { status: 200, headers: { "content-type": "text/plain" } });
    }

    let upstreamUrl;
    const routed = targetFromRouter(url);
    if (routed && routed.error) return routed.error;
    if (routed && routed.url) {
      upstreamUrl = routed.url;
    } else {
      const upstreamPath = normalizeIncomingPath(url.pathname);
      upstreamUrl = `https://${ORIGIN_HOST}${upstreamPath}${url.search}`;
    }

    const isGetLike = request.method === "GET" || request.method === "HEAD";
    const fwd = new Headers(request.headers);
    fwd.set("referer", upstreamUrl);
    if (request.headers.get("origin")) fwd.set("origin", `https://${ORIGIN_HOST}`);
    ["connection","keep-alive","transfer-encoding","upgrade","proxy-authorization","proxy-authenticate","te","trailers"].forEach(h=>fwd.delete(h));

    const init = { method: request.method, headers: fwd, redirect: "manual", body: isGetLike ? undefined : await request.arrayBuffer() };
    const upstream = await fetch(upstreamUrl, init);
    const contentType = upstream.headers.get("content-type") || "";
    const status = upstream.status;
    let headers = chooseCacheHeaders(url.pathname, upstream.headers);

    const loc = upstream.headers.get("location");
    if (loc) {
      try {
        const locUrl = new URL(loc, upstreamUrl);
        if (locUrl.host.endsWith("wixsite.com")) {
          let path = locUrl.pathname;
          if (path.startsWith(ORIGIN_PATH)) path = path.slice(ORIGIN_PATH.length) || "/";
          const proxied = `${path}${locUrl.search}` || "/";
          headers.set("location", proxied);
        } else if (HOST_WHITELIST.has(locUrl.host)) {
          headers.set("location", `/__p__/https/${locUrl.host}${locUrl.pathname}${locUrl.search}`);
        } else {
          headers.set("location", locUrl.toString());
        }
      } catch (_) {}
    }

    const setCookie = upstream.headers.get("set-cookie");
    if (setCookie) {
      headers.delete("set-cookie");
      for (const raw of setCookie.split("\n")) {
        let v = raw.replace(/;\s*Domain=[^;]+/i, `; Domain=${url.hostname}`);
        if (!/;\s*Path=/i.test(v)) v += "; Path=/";
        headers.append("set-cookie", v);
      }
    }

    if (isHtml(contentType)) {
      let html = await upstream.text();
      html = rewriteHtml(html);
      headers.set("content-type", "text/html; charset=utf-8");
      headers.delete("content-length");
      return new Response(html, { status, headers });
    }

    return new Response(upstream.body, { status, headers });

  } catch (err){
    // Safer fallback: stay on our domain
    return new Response("Temporary edge error, reloading...", { status: 302, headers: { "location": "/" } });
  }
}
