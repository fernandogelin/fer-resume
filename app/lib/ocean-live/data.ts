import { ALL_BUOYS, OCEAN_LIVE_POLL_MS, OCEAN_SAMPLE_GRID } from './config';
import type {
  BuoyReading,
  OceanLayerType,
  OceanLayersUpdate,
  OceanLiveUpdate,
  OceanSample,
  Species,
  StormCenter,
  TrackedAnimal,
} from './types';

interface OceanLiveArgs {
  onUpdate: (update: OceanLiveUpdate) => void;
  onAnimalsLoadingChange?: (isLoading: boolean) => void;
}

const OCEARCH_MAP_ID = 3413;
// In dev, Vite proxy rewrites /api/mapotic -> mapotic.com; in production (e.g. Firebase Hosting) there is no proxy, so call Mapotic directly.
const OCEARCH_BASE_URL =
  typeof import.meta !== 'undefined' && import.meta.env?.DEV
    ? `/api/mapotic/maps/${OCEARCH_MAP_ID}`
    : `https://www.mapotic.com/api/v1/maps/${OCEARCH_MAP_ID}`;
const NDBC_REALTIME_BASE_URL =
  typeof import.meta !== 'undefined' && import.meta.env?.DEV
    ? '/api/ndbc/data/realtime2'
    : 'https://www.ndbc.noaa.gov/data/realtime2';
const OCEARCH_PAGE_SIZE = 50;
const OCEARCH_MAX_ANIMALS = 500;
const OCEARCH_MOTION_CHUNK = 20;

interface OcearchLocalized {
  en?: string;
}

interface OcearchAttribute {
  code?: string;
  name?: OcearchLocalized;
  settings?: {
    choices?: Record<string, OcearchLocalized>;
  };
}

interface OcearchAttributeValue {
  value?: string | string[];
  value_html?: string | null;
  attribute?: OcearchAttribute;
}

interface OcearchPoi {
  id: number;
  name: string;
  slug?: string;
  point?: { coordinates?: [number, number] };
  last_move_datetime?: string | null;
  attributes_values?: OcearchAttributeValue[];
  category?: {
    name?: string | OcearchLocalized;
  };
}

interface OcearchPoisResponse {
  num_pages?: number;
  results?: OcearchPoi[];
}

interface OcearchMotionPoint {
  dt_move?: string;
  point?: { coordinates?: [number, number] };
}

function safeTimestamp(value: string | null | undefined): number | null {
  if (!value) return null;
  const timestamp = Date.parse(value);
  return Number.isFinite(timestamp) ? timestamp : null;
}

function attributeValue(attribute: OcearchAttributeValue | undefined): string | null {
  if (!attribute) return null;

  if (Array.isArray(attribute.value)) {
    return attribute.value[0] ?? null;
  }

  if (typeof attribute.value === 'string') {
    return attribute.value;
  }

  return null;
}

function attributeByCode(poi: OcearchPoi, codeFragment: string): OcearchAttributeValue | undefined {
  return poi.attributes_values?.find((entry) =>
    (entry.attribute?.code ?? '').toLowerCase().includes(codeFragment),
  );
}

function speciesFromOcearchPoi(poi: OcearchPoi): Species | null {
  const mapSpeciesFromText = (rawText: string | null | undefined): Species | null => {
    if (!rawText) return null;

    const normalized = rawText.toLowerCase();

    if (
      normalized.includes('shark') ||
      normalized.includes('mako') ||
      normalized.includes('hammerhead') ||
      normalized.includes('tiger shark') ||
      normalized.includes('bull shark')
    ) {
      return 'shark';
    }

    if (normalized.includes('leatherback') || normalized.includes('turtle')) {
      return 'turtle';
    }

    if (normalized.includes('dolphin')) {
      return 'dolphin';
    }

    if (normalized.includes('seal')) {
      return 'seal';
    }

    if (normalized.includes('swordfish')) {
      return 'swordfish';
    }

    if (normalized.includes('alligator')) {
      return 'alligator';
    }

    return null;
  };

  const speciesAttr = attributeByCode(poi, 'species:');
  const choiceKey = attributeValue(speciesAttr);
  const choiceLabel =
    speciesAttr && choiceKey ? speciesAttr.attribute?.settings?.choices?.[choiceKey]?.en : null;

  const categoryName =
    typeof poi.category?.name === 'string' ? poi.category.name : poi.category?.name?.en;

  return (
    mapSpeciesFromText(choiceLabel) ??
    mapSpeciesFromText(categoryName) ??
    mapSpeciesFromText(poi.slug) ??
    mapSpeciesFromText(poi.name)
  );
}

function profileFromOcearchPoi(poi: OcearchPoi): string {
  const desc = attributeByCode(poi, 'description');
  const text = attributeValue(desc) ?? desc?.value_html ?? '';
  const compact = text
    .replace(/<[^>]+>/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
  return compact || `Live OCEARCH tracked animal: ${poi.name}.`;
}

function latestTimestampFromPoi(poi: OcearchPoi): number {
  const fromLastMove = safeTimestamp(poi.last_move_datetime);
  if (fromLastMove) return fromLastMove;

  const latestAttr = attributeByCode(poi, 'latest');
  const fromLatest = safeTimestamp(attributeValue(latestAttr));
  if (fromLatest) return fromLatest;

  return Date.now();
}

async function fetchOcearchPoisPage(page: number): Promise<OcearchPoisResponse> {
  const url = `${OCEARCH_BASE_URL}/public-pois/?per_page=${OCEARCH_PAGE_SIZE}&page=${page}`;
  const response = await fetch(url, { cache: 'no-store' });
  if (!response.ok) {
    throw new Error(`OCEARCH public-pois ${response.status}`);
  }

  return (await response.json()) as OcearchPoisResponse;
}

async function fetchOcearchMotions(ids: number[]): Promise<Record<string, OcearchMotionPoint[]>> {
  if (ids.length === 0) return {};

  const chunks: number[][] = [];
  for (let index = 0; index < ids.length; index += OCEARCH_MOTION_CHUNK) {
    chunks.push(ids.slice(index, index + OCEARCH_MOTION_CHUNK));
  }

  const responses = await Promise.all(
    chunks.map(async (chunk) => {
      const url = `${OCEARCH_BASE_URL}/pois/motions/?poi=${chunk.join(',')}`;
      const response = await fetch(url, { cache: 'no-store' });
      if (!response.ok) {
        throw new Error(`OCEARCH motions ${response.status}`);
      }

      return (await response.json()) as Record<string, OcearchMotionPoint[]>;
    }),
  );

  return responses.reduce<Record<string, OcearchMotionPoint[]>>((acc, payload) => {
    for (const [key, value] of Object.entries(payload)) {
      acc[key] = value;
    }
    return acc;
  }, {});
}

async function fetchOcearchAnimals(): Promise<TrackedAnimal[]> {
  try {
    const first = await fetchOcearchPoisPage(1);
    const totalPages = Math.max(1, first.num_pages ?? 1);
    const firstResults = first.results ?? [];

    const maxPages = Math.max(1, Math.ceil(OCEARCH_MAX_ANIMALS / OCEARCH_PAGE_SIZE));
    const pagesToFetch = Math.min(totalPages, maxPages);

    const otherPages = await Promise.all(
      Array.from({ length: Math.max(0, pagesToFetch - 1) }, (_, index) =>
        fetchOcearchPoisPage(index + 2),
      ),
    );

    const pois = [...firstResults, ...otherPages.flatMap((page) => page.results ?? [])]
      .filter((poi) => Boolean(poi.point?.coordinates))
      .slice(0, OCEARCH_MAX_ANIMALS);

    const withSupportedSpecies = pois
      .map((poi) => ({ poi, species: speciesFromOcearchPoi(poi) }))
      .filter((row): row is { poi: OcearchPoi; species: Species } => Boolean(row.species));

    const ids = withSupportedSpecies.map((row) => row.poi.id);
    const motions = await fetchOcearchMotions(ids);

    return withSupportedSpecies.map(({ poi, species }) => {
      const motionRows = motions[String(poi.id)] ?? [];
      const pings = motionRows
        .map((row) => {
          const coordinates = row.point?.coordinates;
          const timestamp = safeTimestamp(row.dt_move);
          if (!coordinates || coordinates.length < 2 || !timestamp) return null;
          return {
            timestamp,
            lat: coordinates[1],
            lng: coordinates[0],
          };
        })
        .filter((row): row is { timestamp: number; lat: number; lng: number } => Boolean(row))
        .sort((a, b) => a.timestamp - b.timestamp);

      if (pings.length === 0) {
        const coords = poi.point?.coordinates ?? [0, 0];
        pings.push({
          timestamp: latestTimestampFromPoi(poi),
          lat: coords[1],
          lng: coords[0],
        });
      }

      return {
        id: `ocearch-${poi.id}`,
        name: poi.name,
        species,
        source: 'OCEARCH',
        profile: profileFromOcearchPoi(poi),
        pings,
      } satisfies TrackedAnimal;
    });
  } catch {
    return [];
  }
}

function parseNumber(value: string): number | null {
  if (!value || value === 'MM') return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

async function fetchStation(stationId: string): Promise<Partial<BuoyReading> | null> {
  try {
    const url = `${NDBC_REALTIME_BASE_URL}/${stationId}.txt`;
    const text = await fetch(url, { cache: 'no-store' }).then((res) => {
      if (!res.ok) throw new Error(`NOAA ${res.status}`);
      return res.text();
    });

    const lines = text
      .split('\n')
      .map((line) => line.trim())
      .filter(Boolean);
    if (lines.length < 3) return null;

    const headers = lines[0]?.split(/\s+/) ?? [];
    const latest = lines[2]?.split(/\s+/) ?? [];

    const get = (name: string): number | null => {
      const idx = headers.indexOf(name);
      if (idx < 0) return null;
      const raw = latest[idx];
      if (!raw) return null;
      return parseNumber(raw);
    };

    const waveHeightM = get('WVHT');
    const wavePeriodS = get('DPD');
    const windSpeedMs = get('WSPD');
    const windDirDeg = get('WDIR');
    const waterTempC = get('WTMP');

    if (
      waveHeightM === null ||
      wavePeriodS === null ||
      windSpeedMs === null ||
      windDirDeg === null ||
      waterTempC === null
    ) {
      return null;
    }

    const yy = Number(latest[0]);
    const mm = Number(latest[1]) - 1;
    const dd = Number(latest[2]);
    const hh = Number(latest[3]);
    const min = Number(latest[4]);
    const observedAt = Date.UTC(yy, mm, dd, hh, min);

    return {
      waveHeightM,
      wavePeriodS,
      windSpeedMs,
      windDirDeg,
      waterTempC,
      observedAt,
    };
  } catch {
    return null;
  }
}

export class OceanLiveSource {
  private timer: number | null = null;

  constructor(private readonly args: OceanLiveArgs) {}

  start(): void {
    this.stop();
    void this.poll();
    this.timer = window.setInterval(() => void this.poll(), OCEAN_LIVE_POLL_MS);
  }

  stop(): void {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  private async poll(): Promise<void> {
    this.args.onAnimalsLoadingChange?.(true);

    try {
      const [stationResults, animals] = await Promise.all([
        Promise.all(
          ALL_BUOYS.map(async (station) => ({
            station,
            reading: await fetchStation(station.id),
          })),
        ),
        fetchOcearchAnimals(),
      ]);

      const liveBuoys: BuoyReading[] = stationResults.reduce<BuoyReading[]>((acc, item) => {
        if (!item.reading) return acc;

        acc.push({
          stationId: item.station.id,
          lat: item.station.lat,
          lng: item.station.lng,
          waveHeightM: item.reading.waveHeightM ?? 0,
          wavePeriodS: item.reading.wavePeriodS ?? 0,
          windSpeedMs: item.reading.windSpeedMs ?? 0,
          windDirDeg: item.reading.windDirDeg ?? 0,
          waterTempC: item.reading.waterTempC ?? 0,
          observedAt: item.reading.observedAt ?? Date.now(),
        });

        return acc;
      }, []);

      const buoys = liveBuoys;

      const buoyUpdatedAt = buoys.reduce((max, row) => Math.max(max, row.observedAt), 0) || null;
      const animalUpdatedAt =
        animals
          .flatMap((animal) => animal.pings)
          .reduce((max, row) => Math.max(max, row.timestamp), 0) || null;

      this.args.onUpdate({
        buoys,
        animals,
        buoyUpdatedAt,
        animalUpdatedAt,
      });
    } finally {
      this.args.onAnimalsLoadingChange?.(false);
    }
  }
}

// ---------------------------------------------------------------------------
// Ocean Layers: Marine grid + NHC storms
// ---------------------------------------------------------------------------

const OPENMETEO_MARINE_BASE = 'https://marine-api.open-meteo.com/v1/marine';
const OPENMETEO_WEATHER_BASE = 'https://api.open-meteo.com/v1/forecast';
const NHC_STORMS_URL =
  typeof import.meta !== 'undefined' && import.meta.env?.DEV
    ? '/api/nhc/CurrentStorms.json'
    : 'https://www.nhc.noaa.gov/CurrentStorms.json';
const OCEAN_LAYERS_POLL_MS = 3 * 60 * 60_000; // 3 hours

async function fetchMarineGrid(): Promise<OceanSample[]> {
  const lats = OCEAN_SAMPLE_GRID.map((p) => p.lat).join(',');
  const lngs = OCEAN_SAMPLE_GRID.map((p) => p.lng).join(',');
  const marineFields =
    'wave_height,wave_direction,wave_period,sea_surface_temperature,ocean_current_velocity,ocean_current_direction';
  const weatherFields = 'wind_speed_10m,wind_direction_10m';

  const [marineRes, weatherRes] = await Promise.all([
    fetch(
      `${OPENMETEO_MARINE_BASE}?latitude=${lats}&longitude=${lngs}&current=${marineFields}&timezone=UTC`,
      { cache: 'no-store' },
    ),
    fetch(
      `${OPENMETEO_WEATHER_BASE}?latitude=${lats}&longitude=${lngs}&current=${weatherFields}&timezone=UTC`,
      { cache: 'no-store' },
    ),
  ]);

  if (!marineRes.ok || !weatherRes.ok) {
    throw new Error(
      `OpenMeteo fetch failed: marine=${marineRes.status} weather=${weatherRes.status}`,
    );
  }

  // When multiple locations are requested, OpenMeteo returns an array; single location returns an object.
  const marineJson = (await marineRes.json()) as unknown;
  const weatherJson = (await weatherRes.json()) as unknown;

  // These are always objects with a 'current' property, but types are unknown
  const marineArr = Array.isArray(marineJson) ? marineJson : [marineJson];
  const weatherArr = Array.isArray(weatherJson) ? weatherJson : [weatherJson];

  const fetchedAt = Date.now();
  const samples: OceanSample[] = [];

  for (let i = 0; i < OCEAN_SAMPLE_GRID.length; i++) {
    const point = OCEAN_SAMPLE_GRID[i];
    if (!point) continue;

    const marineRaw: unknown = marineArr[i];
    const weatherRaw: unknown = weatherArr[i];
    let marine: Record<string, number> | undefined = undefined;
    let weather: Record<string, number> | undefined = undefined;
    if (
      marineRaw &&
      typeof marineRaw === 'object' &&
      Object.prototype.hasOwnProperty.call(marineRaw, 'current') &&
      typeof (marineRaw as { current?: unknown }).current === 'object'
    ) {
      marine = (marineRaw as { current: Record<string, number> }).current;
    }
    if (
      weatherRaw &&
      typeof weatherRaw === 'object' &&
      Object.prototype.hasOwnProperty.call(weatherRaw, 'current') &&
      typeof (weatherRaw as { current?: unknown }).current === 'object'
    ) {
      weather = (weatherRaw as { current: Record<string, number> }).current;
    }
    if (!marine || !weather) continue;

    samples.push({
      lat: point.lat,
      lng: point.lng,
      sstC: marine['sea_surface_temperature'] ?? 15,
      waveHeightM: marine['wave_height'] ?? 0,
      waveDirDeg: marine['wave_direction'] ?? 0,
      wavePeriodS: marine['wave_period'] ?? 8,
      windSpeedMs: weather['wind_speed_10m'] ?? 0,
      windDirDeg: weather['wind_direction_10m'] ?? 0,
      currentSpeedMs: marine['ocean_current_velocity'] ?? 0,
      currentDirDeg: marine['ocean_current_direction'] ?? 0,
      fetchedAt,
    });
  }

  return samples;
}

interface NhcStormJson {
  activeStorms?: {
    id?: string;
    name?: string;
    centerLat?: number | string;
    centerLon?: number | string;
    intensity?: number | string;
    category?: number | string;
    movementDir?: number | string;
  }[];
}

async function fetchNhcStorms(): Promise<StormCenter[]> {
  const res = await fetch(NHC_STORMS_URL, { cache: 'no-store' });
  if (!res.ok) throw new Error(`NHC storms ${res.status}`);

  const json = (await res.json()) as NhcStormJson;
  const fetchedAt = Date.now();

  return (json.activeStorms ?? []).flatMap((s) => {
    const lat = Number(s.centerLat);
    const lng = Number(s.centerLon);
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) return [];
    return [
      {
        id: s.id ?? `storm-${lat}-${lng}`,
        name: s.name ?? 'Unknown',
        lat,
        lng,
        category: Number(s.category ?? 0),
        maxWindKt: Number(s.intensity ?? 0),
        movementDirDeg: Number(s.movementDir ?? 0),
        fetchedAt,
      } satisfies StormCenter,
    ];
  });
}

interface OceanLayersArgs {
  onUpdate: (update: OceanLayersUpdate) => void;
}

export class OceanLayersSource {
  private timer: number | null = null;
  private activeLayers = new Set<OceanLayerType>();

  constructor(private readonly args: OceanLayersArgs) {}

  setLayers(layers: Set<OceanLayerType>): void {
    const hadAny = this.activeLayers.size > 0;
    this.activeLayers = new Set(layers);
    const hasAny = this.activeLayers.size > 0;

    if (!hadAny && hasAny) {
      this.stop();
      void this.poll();
      this.timer = window.setInterval(() => void this.poll(), OCEAN_LAYERS_POLL_MS);
    } else if (hadAny && !hasAny) {
      this.stop();
    }
  }

  stop(): void {
    if (this.timer !== null) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  private async poll(): Promise<void> {
    if (this.activeLayers.size === 0) return;

    try {
      const needsGrid =
        this.activeLayers.has('temperature') ||
        this.activeLayers.has('swell') ||
        this.activeLayers.has('wind') ||
        this.activeLayers.has('currents');
      const needsStorms = this.activeLayers.has('storms');

      const [samples, storms] = await Promise.all([
        needsGrid ? fetchMarineGrid() : Promise.resolve([]),
        needsStorms ? fetchNhcStorms() : Promise.resolve([]),
      ]);

      this.args.onUpdate({ samples, storms, fetchedAt: Date.now() });
    } catch {
      // Non-fatal — leave previous data in place
    }
  }
}
