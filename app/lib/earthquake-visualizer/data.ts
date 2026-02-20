import {
  EVICT_AFTER_BY_FEED_MS,
  FALLBACK_INITIAL_URL,
  FEED_URLS,
  POLL_INTERVAL_MS,
} from './config';
import type {
  DataStatus,
  DataUpdate,
  EarthquakeEvent,
  FeedWindow,
  RawUsgsFeature,
  RawUsgsResponse,
} from './types';

interface DataSourceArgs {
  onUpdate: (update: DataUpdate) => void;
  onStatus: (status: DataStatus) => void;
}

export class EarthquakeDataSource {
  private eventsById = new Map<string, EarthquakeEvent>();
  private feedWindow: FeedWindow = 'hour';
  private timer: number | null = null;
  private polling = false;
  private paused = false;

  constructor(private readonly args: DataSourceArgs) {}

  start(feedWindow: FeedWindow): void {
    this.feedWindow = feedWindow;
    this.stop();
    void this.poll(true);
    this.timer = window.setInterval(() => void this.poll(false), POLL_INTERVAL_MS);
  }

  stop(): void {
    if (this.timer) {
      window.clearInterval(this.timer);
      this.timer = null;
    }
  }

  setFeedWindow(feedWindow: FeedWindow): void {
    if (this.feedWindow === feedWindow) return;
    this.feedWindow = feedWindow;
    this.eventsById.clear();
    void this.poll(true);
  }

  setPaused(paused: boolean): void {
    this.paused = paused;
  }

  getSnapshot(): EarthquakeEvent[] {
    return [...this.eventsById.values()].sort((a, b) => b.time - a.time);
  }

  private async poll(initial: boolean): Promise<void> {
    if (this.polling || this.paused) return;
    this.polling = true;

    try {
      const response = await this.fetchFeed(initial);
      const now = Date.now();
      const incoming = this.normalize(response.features);

      const newEvents: EarthquakeEvent[] = [];
      for (const event of incoming) {
        const existing = this.eventsById.get(event.id);
        this.eventsById.set(event.id, existing ? { ...existing, ...event } : event);
        if (!initial && !existing) {
          newEvents.push(event);
        }
      }

      const evictAfterMs = EVICT_AFTER_BY_FEED_MS[this.feedWindow];

      for (const [id, event] of this.eventsById.entries()) {
        if (now - event.time > evictAfterMs) {
          this.eventsById.delete(id);
        }
      }

      const events = this.getSnapshot();
      this.args.onUpdate({ events, newEvents, feedWindow: this.feedWindow });

      this.args.onStatus({
        tone: 'live',
        message: 'Live',
        lastUpdatedAt: now,
      });
    } catch (error) {
      this.args.onStatus({
        tone: 'error',
        message: 'Reconnecting...',
        lastUpdatedAt: null,
      });
      console.error('Failed to fetch earthquakes', error);
    } finally {
      this.polling = false;
    }
  }

  private async fetchFeed(initial: boolean): Promise<RawUsgsResponse> {
    const primary = FEED_URLS[this.feedWindow];
    try {
      const response = await fetch(primary, { cache: 'no-store' });
      if (!response.ok) throw new Error(`USGS ${response.status}`);
      return (await response.json()) as RawUsgsResponse;
    } catch (error) {
      if (!(initial && this.feedWindow === 'hour')) throw error;
      const fallbackResponse = await fetch(FALLBACK_INITIAL_URL, { cache: 'no-store' });
      if (!fallbackResponse.ok) throw new Error(`USGS fallback ${fallbackResponse.status}`);
      return (await fallbackResponse.json()) as RawUsgsResponse;
    }
  }

  private normalize(features: RawUsgsFeature[]): EarthquakeEvent[] {
    return features
      .filter((feature) => Number.isFinite(feature.properties.mag) && feature.geometry.coordinates)
      .map((feature) => {
        const [lng, lat, depth] = feature.geometry.coordinates;

        return {
          id: feature.id,
          lng,
          lat,
          depth,
          mag: feature.properties.mag ?? 0,
          place: feature.properties.place || 'Unknown location',
          time: feature.properties.time,
        } satisfies EarthquakeEvent;
      });
  }
}
