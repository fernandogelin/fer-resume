export type Species = 'shark' | 'turtle' | 'dolphin' | 'seal' | 'swordfish' | 'alligator';

export interface BuoyStation {
  id: string;
  lat: number;
  lng: number;
  label: string;
}

export interface BuoyReading {
  stationId: string;
  lat: number;
  lng: number;
  waveHeightM: number;
  wavePeriodS: number;
  windSpeedMs: number;
  windDirDeg: number;
  waterTempC: number;
  observedAt: number;
}

export interface AnimalPing {
  timestamp: number;
  lat: number;
  lng: number;
  depthM?: number;
}

export interface TrackedAnimal {
  id: string;
  name: string;
  species: Species;
  source: 'OCEARCH' | 'Movebank';
  profile: string;
  pings: AnimalPing[];
}

export interface OceanLiveUpdate {
  buoys: BuoyReading[];
  animals: TrackedAnimal[];
  buoyUpdatedAt: number | null;
  animalUpdatedAt: number | null;
}

export type OceanLayerType = 'temperature' | 'swell' | 'wind' | 'currents' | 'storms';

export interface OceanSample {
  lat: number;
  lng: number;
  sstC: number;
  windSpeedMs: number;
  windDirDeg: number;
  waveHeightM: number;
  waveDirDeg: number;
  wavePeriodS: number;
  /** Ocean surface current speed in m/s (from CMEMS via OpenMeteo Marine) */
  currentSpeedMs: number;
  /** Ocean surface current direction in degrees (meteorological) */
  currentDirDeg: number;
  fetchedAt: number;
}

export interface StormCenter {
  id: string;
  name: string;
  lat: number;
  lng: number;
  /** 0 = TD/TS, 1–5 = Hurricane category */
  category: number;
  maxWindKt: number;
  movementDirDeg: number;
  fetchedAt: number;
}

export interface OceanLayersUpdate {
  samples: OceanSample[];
  storms: StormCenter[];
  fetchedAt: number;
}
