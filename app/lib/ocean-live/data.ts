import { ATLANTIC_BUOYS, OCEAN_LIVE_POLL_MS } from './config';
import type { BuoyReading, OceanLiveUpdate, Species, TrackedAnimal } from './types';

interface OceanLiveArgs {
  onUpdate: (update: OceanLiveUpdate) => void;
}

const OCEARCH_MAP_ID = 3413;
const OCEARCH_BASE_URL = `/api/mapotic/maps/${OCEARCH_MAP_ID}`;
const NDBC_REALTIME_BASE_URL = '/api/ndbc/data/realtime2';
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
    const [stationResults, animals] = await Promise.all([
      Promise.all(
        ATLANTIC_BUOYS.map(async (station) => ({
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
  }
}
