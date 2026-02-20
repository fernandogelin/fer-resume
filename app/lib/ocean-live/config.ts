import type { BuoyStation, Species } from './types';

export const OCEAN_LIVE_POLL_MS = 10 * 60_000;

export const ALL_BUOYS: BuoyStation[] = [
  { id: '41001', lat: 34.7, lng: -72.7, label: 'East Hatteras' },
  { id: '41002', lat: 32.3, lng: -75.4, label: 'South Hatteras' },
  { id: '41004', lat: 32.5, lng: -79.1, label: 'Edisto' },
  { id: '41009', lat: 28.5, lng: -80.2, label: 'Canaveral Nearshore' },
  { id: '41010', lat: 28.9, lng: -78.5, label: 'Canaveral East' },
  { id: '41012', lat: 30.0, lng: -80.6, label: 'St. Augustine' },
  { id: '41025', lat: 35.0, lng: -75.4, label: 'Diamond Shoals' },
  { id: '41049', lat: 27.5, lng: -63.0, label: 'Western Atlantic Offshore' },
  { id: '41043', lat: 21.0, lng: -64.9, label: 'Northeast Caribbean' },
  { id: '41044', lat: 21.6, lng: -58.6, label: 'Southeast Caribbean' },
  { id: '41046', lat: 23.8, lng: -68.4, label: 'Bermuda East' },
  { id: '41047', lat: 27.5, lng: -71.5, label: 'Cape Charles East' },
  { id: '41048', lat: 31.9, lng: -69.6, label: 'Central Atlantic' },
  { id: '44011', lat: 41.1, lng: -66.6, label: 'Georges Bank' },
  { id: '44008', lat: 40.5, lng: -69.4, label: 'Nantucket East' },
  { id: '44020', lat: 41.4, lng: -70.2, label: 'Cape Cod Bay' },
  { id: '44014', lat: 36.6, lng: -74.8, label: 'Virginia Beach' },
  { id: '42001', lat: 25.9, lng: -89.7, label: 'Gulf of Mexico North' },
  { id: '42003', lat: 26.0, lng: -85.6, label: 'Gulf of Mexico East' },
  { id: '42019', lat: 27.9, lng: -95.3, label: 'Freeport Offshore' },
  { id: '42020', lat: 26.9, lng: -96.7, label: 'Corpus Christi Offshore' },
  { id: '42022', lat: 27.5, lng: -89.7, label: 'Louisiana Offshore' },
  { id: '46042', lat: 36.8, lng: -122.4, label: 'Monterey Bay' },
  { id: '46013', lat: 38.2, lng: -123.3, label: 'Bodega Bay' },
  { id: '46014', lat: 39.2, lng: -123.9, label: 'Point Arena' },
  { id: '46012', lat: 38.2, lng: -120.9, label: 'Half Moon Bay' },
  { id: '46022', lat: 40.7, lng: -124.5, label: 'Eel River' },
  { id: '46027', lat: 41.9, lng: -124.4, label: 'St. George Reef' },
  { id: '46028', lat: 35.7, lng: -121.9, label: 'Cape San Martin' },
  { id: '46050', lat: 44.7, lng: -124.5, label: 'Stonewall Bank' },
  { id: '46089', lat: 45.9, lng: -125.8, label: 'Tillamook' },
  { id: '46036', lat: 48.4, lng: -133.9, label: 'West Vancouver Island' },
  { id: '46059', lat: 38.0, lng: -129.9, label: 'Northern CA Offshore' },
  { id: '46026', lat: 37.8, lng: -122.8, label: 'San Francisco' },
  { id: '46011', lat: 34.9, lng: -120.9, label: 'Santa Maria' },
  { id: '51001', lat: 23.4, lng: -162.3, label: 'Hawaii Northwest' },
  { id: '51002', lat: 17.0, lng: -157.8, label: 'Hawaii South' },
  { id: '51003', lat: 19.2, lng: -160.7, label: 'Hawaii Central' },
];

/** Lat/lng points sampled from OpenMeteo Marine + Weather APIs for ocean layer overlays. */
export const OCEAN_SAMPLE_GRID: { lat: number; lng: number }[] = [
  // North Atlantic
  { lat: 45.0, lng: -40.0 },
  { lat: 35.0, lng: -50.0 },
  { lat: 25.0, lng: -45.0 },
  // South Atlantic
  { lat: -15.0, lng: -25.0 },
  { lat: -35.0, lng: -15.0 },
  // Caribbean / Gulf of Mexico
  { lat: 18.0, lng: -75.0 },
  { lat: 24.0, lng: -90.0 },
  // North Pacific (Eastern)
  { lat: 40.0, lng: -150.0 },
  { lat: 25.0, lng: -140.0 },
  { lat: 10.0, lng: -120.0 },
  // South Pacific
  { lat: -20.0, lng: -150.0 },
  { lat: -40.0, lng: -130.0 },
  // North Pacific (Western)
  { lat: 30.0, lng: 160.0 },
  { lat: 15.0, lng: 140.0 },
  // Indian Ocean
  { lat: -10.0, lng: 75.0 },
  { lat: 10.0, lng: 65.0 },
  // Mediterranean
  { lat: 36.0, lng: 15.0 },
  // Norwegian / North Sea
  { lat: 60.0, lng: 0.0 },
  // Southern Ocean
  { lat: -55.0, lng: -60.0 },
  { lat: -55.0, lng: 90.0 },
];

export const SPECIES_LABELS: Record<Species, string> = {
  shark: 'Sharks',
  turtle: 'Turtles',
  dolphin: 'Dolphins',
  seal: 'Seals',
  swordfish: 'Swordfish',
  alligator: 'Alligators',
};

export const SPECIES_ICONS: Record<Species, string> = {
  shark: `<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12.5c3.2-3.5 8.1-5 14.7-4.4l3.3-1.7-1.1 3.6 1.1 3.6-3.3-1.7c-6.6.6-11.5-.9-14.7-4.4Z"/><path d="m10.3 8.4-.8-2.8 2.7 1.8"/><circle cx="15.8" cy="10.1" r="0.9" fill="currentColor" stroke="none"/></svg>`,
  turtle: `<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><ellipse cx="12" cy="12.4" rx="5.2" ry="4.1"/><path d="M12 8.5v7.8M9.6 10.1l4.8 4.6M14.4 10.1l-4.8 4.6"/><path d="M12 6.1a1.3 1.3 0 1 0 0-2.6 1.3 1.3 0 0 0 0 2.6Z"/><path d="M6.1 10.9a1.1 1.1 0 1 0 0-2.2 1.1 1.1 0 0 0 0 2.2ZM17.9 10.9a1.1 1.1 0 1 0 0-2.2 1.1 1.1 0 0 0 0 2.2"/></svg>`,
  dolphin: `<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M3 13.2c2.8-3.8 7.3-5.7 13.5-5.5 2 0 3.5 1.6 3.5 3.5s-1.5 3.5-3.5 3.5h-2.3l-1.5 2.1-1.1-2c-2.8-.1-5.7-.8-8.6-1.6Z"/><path d="m9.5 8.7 1-2.6 2.1 1.8"/><circle cx="15.6" cy="10.2" r="0.9" fill="currentColor" stroke="none"/></svg>`,
  seal: `<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M3.2 13.8c2.4-3 5.6-4.6 9.7-4.6h2.5a3.9 3.9 0 1 1 0 7.8h-2.8c-3.7 0-6.8-1.1-9.4-3.2Z"/><path d="m4.8 14.1-1.6 1.7 2.2.1"/><circle cx="15.3" cy="11.1" r="0.9" fill="currentColor" stroke="none"/></svg>`,
  swordfish: `<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M2 12.1 9 10.5h7.4l5.6-2.8-3.3 4.4 3.3 4.2-5.6-2.8H9Z"/><path d="M9 10.5 7.5 8.3M9 13.7 7.5 15.9"/><circle cx="14.3" cy="11.2" r="0.9" fill="currentColor" stroke="none"/></svg>`,
  alligator: `<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M3 13h9.2c2.7 0 5-1.4 6.6-3.5L22 10l-2.1 2.2L22 14.5l-3.2.5c-1.6-2.1-3.9-3.5-6.6-3.5H3Z"/><path d="M7.4 11.4h2.3M7.4 13.8h2.3"/><circle cx="16.8" cy="10.9" r="0.9" fill="currentColor" stroke="none"/></svg>`,
};
