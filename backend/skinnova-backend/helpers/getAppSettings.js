const AppSettings = require("../models/AppSettings");

let _cache = null;
let _cacheAt = 0;
const CACHE_TTL_MS = 30 * 1000; // 30-second cache so routes aren't DB-heavy

/**
 * Returns the singleton AppSettings document.
 * Creates it with defaults if it doesn't exist yet.
 * Results are cached for 30 s to avoid hitting MongoDB on every request.
 */
async function getAppSettings() {
  const now = Date.now();
  if (_cache && now - _cacheAt < CACHE_TTL_MS) return _cache;

  let settings = await AppSettings.findOne();
  if (!settings) settings = await AppSettings.create({});

  _cache = settings;
  _cacheAt = now;
  return settings;
}

/** Call this after a PUT /api/admin/settings to flush the cache immediately. */
function invalidateSettingsCache() {
  _cache = null;
  _cacheAt = 0;
}

module.exports = { getAppSettings, invalidateSettingsCache };
