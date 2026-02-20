'use strict';

const { onRequest } = require('firebase-functions/v2/https');

const NDBC_ORIGIN = 'https://www.ndbc.noaa.gov';
const NHC_ORIGIN = 'https://www.nhc.noaa.gov';

/**
 * Proxies /api/ndbc/* and /api/nhc/* to NOAA so the Ocean Live app can
 * load buoy and storm data in production (NDBC/NHC do not send CORS headers).
 */
exports.apiProxy = onRequest(
  {
    cors: true,
    timeoutSeconds: 60,
  },
  async (req, res) => {
    const path = (req.url || '').split('?')[0];
    let upstreamUrl;

    if (path.startsWith('/api/ndbc/')) {
      const suffix = path.slice('/api/ndbc'.length);
      upstreamUrl = `${NDBC_ORIGIN}${suffix}`;
    } else if (path.startsWith('/api/nhc/')) {
      const suffix = path.slice('/api/nhc'.length);
      upstreamUrl = `${NHC_ORIGIN}${suffix}`;
    } else {
      res.status(404).send('Not found');
      return;
    }

    try {
      const upstream = await fetch(upstreamUrl, {
        headers: { 'User-Agent': 'fer-resume-ocean-live/1.0' },
      });
      const contentType = upstream.headers.get('content-type') || 'application/octet-stream';
      res.set('Cache-Control', 'public, max-age=300');
      res.set('Content-Type', contentType);
      const body = await upstream.text();
      res.status(upstream.status).send(body);
    } catch (err) {
      console.error('apiProxy error:', err);
      res.status(502).send('Proxy error');
    }
  },
);
