// Cloudflare Worker: serves Shravan audio from the R2 bucket bound as AUDIO.
// GET /<path> → the object, cached for a year (files never change; a new
// recording gets a new name). Supports Range requests for streaming.
export default {
  async fetch(request, env) {
    if (request.method !== 'GET' && request.method !== 'HEAD') {
      return new Response('Method not allowed', { status: 405 });
    }
    const key = decodeURIComponent(new URL(request.url).pathname.slice(1));
    if (!key || key.includes('..')) return new Response('Not found', { status: 404 });
    const ranged = request.headers.has('range');
    const object = await env.AUDIO.get(key, ranged
      ? { range: request.headers, onlyIf: request.headers }
      : { onlyIf: request.headers });
    if (!object) return new Response('Not found', { status: 404 });
    const headers = new Headers();
    object.writeHttpMetadata(headers);
    headers.set('etag', object.httpEtag);
    headers.set('accept-ranges', 'bytes');
    headers.set('cache-control', key.endsWith('manifest.json')
      ? 'public, max-age=300' : 'public, max-age=31536000, immutable');
    let status = 200;
    if (ranged && object.range) {
      const { offset = 0, length = object.size - offset } = object.range;
      headers.set('content-range', `bytes ${offset}-${offset + length - 1}/${object.size}`);
      status = 206;
    }
    return new Response('body' in object ? object.body : null, { status, headers });
  },
};
