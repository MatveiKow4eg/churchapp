// Simple in-memory LRU-ish cache with TTL.
//
// Requirements:
// - key: upstream URL string
// - TTL: 24h
// - max entries: 2000
//
// Implementation: Map preserves insertion order. On get, we refresh recency
// by deleting + re-setting. Eviction removes oldest.

const MAX_ENTRIES = 2000;
const TTL_MS = 24 * 60 * 60 * 1000;

/** @type {Map<string, {expiresAt: number, buffer: Buffer}>} */
const cache = new Map();

function get(key) {
  const entry = cache.get(key);
  if (!entry) return null;

  if (Date.now() > entry.expiresAt) {
    cache.delete(key);
    return null;
  }

  // refresh recency
  cache.delete(key);
  cache.set(key, entry);
  return entry.buffer;
}

function set(key, buffer) {
  cache.set(key, {
    expiresAt: Date.now() + TTL_MS,
    buffer,
  });

  if (cache.size > MAX_ENTRIES) {
    // evict oldest
    const oldestKey = cache.keys().next().value;
    if (oldestKey) cache.delete(oldestKey);
  }
}

module.exports = {
  get,
  set,
};
