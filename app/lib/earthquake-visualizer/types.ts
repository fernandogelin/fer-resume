export type FeedWindow = 'hour' | 'day' | 'week';

export type StatusTone = 'live' | 'stale' | 'error';

export interface RawUsgsFeature {
  id: string;
  geometry: { coordinates: [number, number, number] };
  properties: {
    mag: number | null;
    place: string;
    time: number;
  };
}

export interface RawUsgsResponse {
  features: RawUsgsFeature[];
}

export interface EarthquakeEvent {
  id: string;
  lng: number;
  lat: number;
  depth: number;
  mag: number;
  place: string;
  time: number;
  isOnLand?: boolean;
}

export interface DataUpdate {
  events: EarthquakeEvent[];
  newEvents: EarthquakeEvent[];
  feedWindow: FeedWindow;
}

export interface DataStatus {
  tone: StatusTone;
  lastUpdatedAt: number | null;
  message: string;
}

export interface TooltipState {
  quake: EarthquakeEvent;
  x: number;
  y: number;
}
