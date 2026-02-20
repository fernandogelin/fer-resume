import type { FeedWindow } from './types';

export const POLL_INTERVAL_MS = 60_000;
export const EVICT_AFTER_BY_FEED_MS: Record<FeedWindow, number> = {
  hour: 10 * 60_000,
  day: 24 * 60 * 60_000,
  week: 7 * 24 * 60 * 60_000,
};

export const FEED_URLS: Record<FeedWindow, string> = {
  hour: 'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_hour.geojson',
  day: 'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.geojson',
  week: 'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_week.geojson',
};

export const FALLBACK_INITIAL_URL = FEED_URLS.day;

export const MAG_COLORS = [
  { min: 7, color: '#9c27b0' },
  { min: 6, color: '#f44336' },
  { min: 4, color: '#ff9800' },
  { min: 2, color: '#ffeb3b' },
  { min: -Infinity, color: '#4caf50' },
] as const;

export const SHALLOW_DEPTH_COLOR = '#ef6c00';
export const DEEP_DEPTH_COLOR = '#4fc3f7';

export const TECTONIC_PLATES_URL =
  'https://raw.githubusercontent.com/fraxen/tectonicplates/master/GeoJSON/PB2002_boundaries.json';
