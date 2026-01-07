const express = require('express');

const avatarCache = require('../utils/avatarCache');

const router = express.Router();

/**
 * DiceBear Adventurer PNG proxy.
 *
 * Why: some clients/platforms have issues decoding the upstream response
 * and/or need consistent caching + CORS behavior.
 *
 * Curl example:
 *   curl -v "http://localhost:3000/avatars/dicebear/adventurer.png?seed=guest&size=256" -o avatar.png
 */
router.get('/avatars/dicebear/adventurer.png', async (req, res) => {
  try {
    console.log('[avatar-proxy] hit', req.originalUrl);

    const query = { ...req.query };
    if (query.size == null || String(query.size).trim() === '') {
      query.size = '256';
    }

    const upstreamUrl = new URL('https://api.dicebear.com/9.x/adventurer/png');
    upstreamUrl.search = new URLSearchParams(query).toString();

    const cacheKey = upstreamUrl.toString();

    const cached = avatarCache.get(cacheKey);
    if (cached) {
      res.set('Content-Type', 'image/png');
      res.set('Cache-Control', 'public, max-age=86400, immutable');
      res.set('X-Avatar-Cache', 'HIT');
      return res.status(200).send(cached);
    }

    console.log('[avatar-proxy] upstream', cacheKey);

    const upstreamRes = await fetch(upstreamUrl, { redirect: 'follow' });

    if (!upstreamRes.ok) {
      console.log(
        '[avatar-proxy] upstream status',
        upstreamRes.status,
        'ct',
        upstreamRes.headers.get('content-type')
      );

      const text = await upstreamRes.text();
      console.log('[avatar-proxy] upstream body', text.slice(0, 300));

      return res
        .status(502)
        .json({ error: 'UPSTREAM_ERROR', status: upstreamRes.status });
    }

    const arrayBuffer = await upstreamRes.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);

    // Cache successful upstream responses.
    avatarCache.set(cacheKey, buffer);

    res.set('Content-Type', 'image/png');
    // Allow aggressive client/proxy caching for generated avatars.
    // Clients may append a cache-busting query param on retry.
    res.set('Cache-Control', 'public, max-age=86400, immutable');
    res.set('X-Avatar-Cache', 'MISS');
    return res.status(200).send(buffer);
  } catch (e) {
    console.log('[avatar-proxy] exception', e);
    return res.status(500).json({ error: 'PROXY_ERROR' });
  }
});

router.get('/avatars/dicebear/adventurer.schema.json', async (_req, res) => {
  try {
    const upstreamUrl =
      'https://api.dicebear.com/9.x/adventurer/schema.json';

    const upstreamRes = await fetch(upstreamUrl, { redirect: 'follow' });

    if (!upstreamRes.ok) {
      return res.status(502).json({ error: 'UPSTREAM_ERROR' });
    }

    const json = await upstreamRes.json();

    res.set('Cache-Control', 'public, max-age=86400');
    return res.status(200).json(json);
  } catch (_e) {
    return res.status(502).json({ error: 'UPSTREAM_ERROR' });
  }
});

module.exports = router;
