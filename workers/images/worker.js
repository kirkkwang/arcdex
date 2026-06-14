// Cloudflare Worker fronting the R2 card-image bucket on images.arcdex.dev.
//
// Card images sync to R2 *behind* the Bulbapedia data, so a newly-indexed card
// can 404 until its image is uploaded. Serving the bucket through this Worker
// lets us return a fallback card back on a miss — which fixes broken images
// everywhere the URL is consumed (gallery <img>, IIIF manifest, Mirador viewer)
// without any app-side changes.
//
// The fallback object key comes from env.FALLBACK_KEY (set per bucket/game in
// wrangler.toml), so the same code is reused for each game's bucket.

export default {
  async fetch(request, env) {
    // Only GET/HEAD make sense for image serving.
    if (request.method !== 'GET' && request.method !== 'HEAD') {
      return new Response('Method Not Allowed', { status: 405 });
    }

    const key = decodeURIComponent(new URL(request.url).pathname.slice(1)); // "/b3a-001.webp" -> "b3a-001.webp"
    if (!key) return new Response('Not Found', { status: 404 });

    const object = await env.BUCKET.get(key);
    if (object) return serve(object); // hit: serve as-is (keeps its immutable cache-control)

    // miss: per-game card back, with a SHORT cache so the real image shows up
    // as soon as it's synced (rather than being pinned for a year).
    const fallback = await env.BUCKET.get(env.FALLBACK_KEY);
    if (!fallback) return new Response('Not Found', { status: 404 });
    return serve(fallback, { 'cache-control': 'public, max-age=300', 'x-arcdex-fallback': '1' });
  },
};

function serve(object, overrides = {}) {
  const headers = new Headers();
  object.writeHttpMetadata(headers); // content-type, cache-control, etc. from the stored object
  headers.set('etag', object.httpEtag);
  for (const [k, v] of Object.entries(overrides)) headers.set(k, v);
  return new Response(object.body, { headers });
}
