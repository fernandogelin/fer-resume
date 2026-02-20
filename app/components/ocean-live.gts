import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { modifier } from 'ember-modifier';
import { feature, mesh } from 'topojson-client';
import { geoGraticule10, geoOrthographic, geoPath } from 'd3-geo';
import { line, select as d3Select, drag as d3Drag, type D3DragEvent } from 'd3';
import Icon from 'fer-resume/components/icon';
import Switch from 'fer-resume/components/ui/switch';
import { ChevronDown, ChevronUp } from 'lucide-static';
import { OceanLayersSource, OceanLiveSource } from 'fer-resume/lib/ocean-live/data';
import { ALL_BUOYS, SPECIES_ICONS, SPECIES_LABELS } from 'fer-resume/lib/ocean-live/config';
import type {
  AnimalPing,
  BuoyReading,
  OceanLayerType,
  OceanLayersUpdate,
  OceanLiveUpdate,
  Species,
  TrackedAnimal,
} from 'fer-resume/lib/ocean-live/types';

function relTime(timestamp: number | null, now: number): string {
  if (!timestamp) return 'n/a';
  const delta = Math.max(0, now - timestamp);
  const minutes = Math.floor(delta / 60_000);
  if (minutes < 1) return 'just now';
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 48) return `${hours}h ago`;
  return `${Math.floor(hours / 24)}d ago`;
}

function interpolatePing(pings: AnimalPing[], timestamp: number): AnimalPing | null {
  if (pings.length === 0) return null;
  if (timestamp <= pings[0]!.timestamp) return pings[0] ?? null;
  if (timestamp >= pings[pings.length - 1]!.timestamp) return pings[pings.length - 1] ?? null;

  for (let index = 0; index < pings.length - 1; index++) {
    const a = pings[index];
    const b = pings[index + 1];
    if (!a || !b) continue;
    if (timestamp >= a.timestamp && timestamp <= b.timestamp) {
      const span = b.timestamp - a.timestamp;
      const t = span <= 0 ? 0 : (timestamp - a.timestamp) / span;
      return {
        timestamp,
        lat: a.lat + (b.lat - a.lat) * t,
        lng: a.lng + (b.lng - a.lng) * t,
        depthM: a.depthM ?? b.depthM,
      };
    }
  }

  return pings[pings.length - 1] ?? null;
}

function speciesIconSvg(species: Species): string {
  return SPECIES_ICONS[species];
}

function speciesIconDataUri(species: Species): string {
  return `data:image/svg+xml;utf8,${encodeURIComponent(speciesIconSvg(species))}`;
}

function speciesLabelClass(species: Species): string {
  return `olv-species-${species}`;
}

function tempColor(celsius: number): string {
  const normalized = Math.max(0, Math.min(1, (celsius - 5) / 24));
  const hue = 208 - normalized * 60;
  const sat = 75;
  const light = 30 + normalized * 22;
  return `hsl(${hue} ${sat}% ${light}%)`;
}

// 128 slots: ~44 buoys + ~20 live animals + 4 layers × 20 grid pts = ~124 max
const MAX_FLUID_BUOYS = 128;

const SPECIES_FLUID_SIZE: Record<Species, number> = {
  shark: 1.2,
  swordfish: 0.9,
  dolphin: 0.85,
  alligator: 0.65,
  turtle: 0.55,
  seal: 0.5,
};

// Only animals with a ping within this window contribute to the fluid simulation
const ANIMAL_FLUID_RECENCY_MIN = 1440; // 24 hours

const FLUID_VERTEX_SHADER = `
attribute vec2 a_position;
void main() {
  gl_Position = vec4(a_position, 0.0, 1.0);
}
`;

const FLUID_FRAGMENT_SHADER = `
precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform int u_buoy_count;
uniform vec4 u_buoys_a[${MAX_FLUID_BUOYS}];
uniform vec4 u_buoys_b[${MAX_FLUID_BUOYS}];

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);

  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));

  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void main() {
  vec2 frag = gl_FragCoord.xy;
  vec2 uv = frag / u_resolution;

  float flowX = 0.0;
  float flowY = 0.0;
  float tempAccum = 0.0;
  float wavePeriodAccum = 0.0;
  float waveHeightAccum = 0.0;
  float weightSum = 0.0;
  float maxSignal = 0.0;
  float localPulse = 0.0;
  float localRidges = 0.0;

  for (int i = 0; i < ${MAX_FLUID_BUOYS}; i++) {
    if (i >= u_buoy_count) break;
    vec4 a = u_buoys_a[i];
    vec4 b = u_buoys_b[i];

    vec2 buoyPos = vec2(a.x, u_resolution.y - a.y);
    vec2 d = frag - buoyPos;
    float dist = max(length(d), 1.0);

    float temp = a.z;
    float windSpeed = a.w;
    float dir = b.x;
    float wavePeriod = b.y;
    float waveHeight = b.z;
    float freshness = b.w;

    float radius = 140.0 + waveHeight * 85.0 + windSpeed * 10.0;
    float influence = exp(-dist / max(80.0, radius)) * freshness;
    float localInfluence = exp(-dist / (28.0 + waveHeight * 28.0)) * freshness;
    float speedFactor = 0.2 + windSpeed / 18.0;

    flowX += cos(dir) * speedFactor * influence;
    flowY += sin(dir) * speedFactor * influence;

    float swirlAngle = atan(d.y, d.x) + u_time * (0.28 + windSpeed * 0.03);
    float swirlStrength = (0.25 + windSpeed * 0.045) * localInfluence;
    flowX += -sin(swirlAngle) * swirlStrength;
    flowY += cos(swirlAngle) * swirlStrength;

    float waveK = 0.09 + waveHeight * 0.025;
    float phase = dist * waveK - u_time * (0.65 + speedFactor * 0.9);
    localPulse += localInfluence * (0.5 + 0.5 * sin(phase + float(i) * 0.7));
    localRidges += localInfluence * (0.5 + 0.5 * cos(phase * 1.4 - float(i) * 0.5));

    tempAccum += temp * influence;
    wavePeriodAccum += wavePeriod * influence;
    waveHeightAccum += waveHeight * influence;
    weightSum += influence;
    maxSignal = max(maxSignal, max(influence * speedFactor, localInfluence));
  }

  float temp = weightSum > 0.001 ? tempAccum / weightSum : 14.0;
  float avgWavePeriod = weightSum > 0.001 ? wavePeriodAccum / weightSum : 7.0;
  float avgWaveHeight = weightSum > 0.001 ? waveHeightAccum / weightSum : 1.2;
  float t = clamp((temp - 5.0) / 24.0, 0.0, 1.0);

  vec2 flow = vec2(flowX, flowY);
  float flowMag = length(flow);
  vec2 dir = flowMag > 0.001 ? normalize(flow) : vec2(0.8, 0.2);

  float periodSpeed = clamp(10.0 / max(2.0, avgWavePeriod), 0.35, 2.0);
  float wave = noise(uv * vec2(13.0, 9.5) + dir * (u_time * 0.12 * periodSpeed));
  wave += 0.5 * noise(uv * vec2(28.0, 22.0) - dir.yx * (u_time * 0.18 * periodSpeed));
  wave = wave / 1.5;

  float advectionSpeed = 0.35 + flowMag * 1.3 + avgWaveHeight * 0.12;
  float current = sin((uv.x * dir.x + uv.y * dir.y) * (24.0 + avgWaveHeight * 4.0) + u_time * advectionSpeed);
  float localTexture = clamp(0.55 * localPulse + 0.45 * localRidges, 0.0, 1.0);
  float shimmer = mix(wave, current * 0.5 + 0.5, 0.35);
  shimmer = mix(shimmer, localTexture, 0.52);

  vec3 cold = vec3(0.04, 0.20, 0.38);
  vec3 warm = vec3(0.08, 0.55, 0.78);
  vec3 tropical = vec3(0.20, 0.77, 0.85);

  vec3 base = mix(cold, warm, t);
  base = mix(base, tropical, smoothstep(0.58, 1.0, t));

  float foam = smoothstep(0.68, 1.0, shimmer) * (0.25 + 0.75 * smoothstep(0.08, 1.0, max(flowMag, maxSignal)));
  vec3 color = base + vec3(0.17, 0.22, 0.24) * shimmer + vec3(0.20, 0.25, 0.28) * foam;
  color += vec3(0.08, 0.11, 0.13) * localTexture;

  gl_FragColor = vec4(color, 0.86);
}
`;

interface WorldTopo {
  objects: { countries: unknown };
}

export default class OceanLive extends Component {
  @tracked buoys: BuoyReading[] = [];
  @tracked animals: TrackedAnimal[] = [];
  @tracked selectedAnimalId: string | null = null;
  @tracked controlsExpanded = true;
  @tracked feedExpanded = true;
  @tracked layerBuoys = true;
  @tracked layerAnimals = true;
  @tracked showTrails = true;
  @tracked speciesFilter: Species | 'all' = 'all';
  @tracked scrubber = 100;
  @tracked now = Date.now();
  @tracked buoyUpdatedAt: number | null = null;
  @tracked animalUpdatedAt: number | null = null;
  @tracked animalsLoading = true;
  @tracked zoomedIn = false;
  @tracked buoyTooltip: { buoy: BuoyReading; x: number; y: number } | null = null;
  @tracked layerTemperature = false;
  @tracked layerSwell = false;
  @tracked layerWind = false;
  @tracked layerCurrents = false;
  @tracked layerStorms = false;
  @tracked oceanLayerData: OceanLayersUpdate | null = null;

  private source = new OceanLiveSource({
    onUpdate: (update) => this.onUpdate(update),
    onAnimalsLoadingChange: (isLoading) => (this.animalsLoading = isLoading),
  });
  private tickTimer: number | null = null;

  private svgEl: SVGSVGElement | null = null;
  private canvasEl: HTMLCanvasElement | null = null;
  private projection: ReturnType<typeof geoOrthographic> | null = null;
  private path: ReturnType<typeof geoPath> | null = null;

  private oceanLayersSource = new OceanLayersSource({
    onUpdate: (data) => this.onLayersUpdate(data),
  });
  private animalsLayer: SVGGElement | null = null;
  private trailsLayer: SVGGElement | null = null;
  private buoyLayer: SVGGElement | null = null;
  private stormsLayer: SVGGElement | null = null;
  private zoomLayer: SVGGElement | null = null;
  private initialGlobeScale = 0;
  private initialGlobeRotation: [number, number, number] = [30, -20, 0];

  private gl: WebGLRenderingContext | null = null;
  private fluidProgram: WebGLProgram | null = null;
  private fluidPositionBuffer: WebGLBuffer | null = null;
  private fluidBuoyDataA = new Float32Array(MAX_FLUID_BUOYS * 4);
  private fluidBuoyDataB = new Float32Array(MAX_FLUID_BUOYS * 4);
  private fluidBuoyCount = 0;
  private fluidRaf: number | null = null;
  private fluidStartTime = 0;

  get speciesOptions(): Array<Species | 'all'> {
    const order: Species[] = ['shark', 'turtle', 'dolphin', 'seal', 'swordfish', 'alligator'];
    const available = new Set(this.animals.map((animal) => animal.species));

    return ['all', ...order.filter((species) => available.has(species))];
  }

  setup = modifier((element: HTMLDivElement) => {
    this.svgEl = element.querySelector('.olv-map-svg');
    this.canvasEl = element.querySelector('.olv-ocean-canvas');

    if (this.svgEl && this.canvasEl) {
      void this.setupMap();
    }

    this.source.start();
    this.tickTimer = window.setInterval(() => {
      this.now = Date.now();
      this.renderDynamicLayers();
    }, 1_000);

    return () => {
      this.source.stop();
      this.oceanLayersSource.stop();
      if (this.svgEl) {
        d3Select(this.svgEl).on('.zoom', null);
      }

      if (this.fluidRaf) {
        cancelAnimationFrame(this.fluidRaf);
        this.fluidRaf = null;
      }

      this.gl = null;
      this.fluidProgram = null;
      this.fluidPositionBuffer = null;

      this.zoomedIn = false;
      if (this.tickTimer) {
        clearInterval(this.tickTimer);
        this.tickTimer = null;
      }
    };
  });

  get selectedAnimal(): TrackedAnimal | null {
    return this.animals.find((animal) => animal.id === this.selectedAnimalId) ?? null;
  }

  get filteredAnimals(): TrackedAnimal[] {
    if (this.speciesFilter === 'all') return this.animals;
    return this.animals.filter((animal) => animal.species === this.speciesFilter);
  }

  get currentTimestamp(): number {
    const allTimes = this.filteredAnimals.flatMap((animal) =>
      animal.pings.map((ping) => ping.timestamp),
    );
    if (allTimes.length === 0) return Date.now();
    const min = Math.min(...allTimes);
    const max = Math.max(...allTimes);
    return min + ((max - min) * this.scrubber) / 100;
  }

  get buoyStatus(): string {
    return `Buoys: ${relTime(this.buoyUpdatedAt, this.now)}`;
  }

  get animalStatus(): string {
    return `Animals: ${relTime(this.animalUpdatedAt, this.now)}`;
  }

  get speciesDisabled(): boolean {
    return !this.layerAnimals;
  }

  get layerDataStatus(): string | null {
    const hasApiLayer =
      this.layerTemperature ||
      this.layerSwell ||
      this.layerWind ||
      this.layerCurrents ||
      this.layerStorms;
    if (!hasApiLayer) return null;
    if (!this.oceanLayerData) return 'Layers: fetching…';
    return `Layers: ${relTime(this.oceanLayerData.fetchedAt, this.now)}`;
  }

  get selectedAnimalLastSeen(): string {
    const selected = this.selectedAnimal;
    if (!selected) return 'n/a';
    const ping = selected.pings[selected.pings.length - 1];
    return relTime(ping?.timestamp ?? null, this.now);
  }

  get showEmptyAnimalsState(): boolean {
    return !this.animalsLoading && this.filteredAnimals.length === 0;
  }

  get buoyTooltipStyle(): string {
    if (!this.buoyTooltip) return '';
    return `left:${Math.min(this.buoyTooltip.x + 16, window.innerWidth - 280)}px;top:${Math.max(8, this.buoyTooltip.y + 16)}px;`;
  }

  get buoyTooltipData(): {
    label: string;
    temp: string;
    wave: string;
    wind: string;
    observed: string;
  } | null {
    const b = this.buoyTooltip?.buoy;
    if (!b) return null;
    return {
      label: ALL_BUOYS.find((s) => s.id === b.stationId)?.label ?? b.stationId,
      temp: `${b.waterTempC.toFixed(1)}°C`,
      wave: `${b.waveHeightM.toFixed(1)} m, ${b.wavePeriodS.toFixed(0)} s period`,
      wind: `${b.windSpeedMs.toFixed(1)} m/s`,
      observed: relTime(b.observedAt, this.now),
    };
  }

  labelForSpecies = (species: Species | 'all'): string => {
    if (species === 'all') return 'All species';
    return SPECIES_LABELS[species];
  };

  badgeClassForSpecies = (species: Species): string => {
    return speciesLabelClass(species);
  };

  iconForSpecies = (species: Species): string => {
    return speciesIconSvg(species);
  };

  isSpeciesSelected = (species: Species | 'all'): boolean => {
    return this.speciesFilter === species;
  };

  isSelectedAnimal = (animal: TrackedAnimal): boolean => {
    return this.selectedAnimalId === animal.id;
  };

  @action toggleControls(): void {
    this.controlsExpanded = !this.controlsExpanded;
  }

  @action toggleFeed(): void {
    this.feedExpanded = !this.feedExpanded;
  }

  @action setShowTrails(value: boolean): void {
    this.showTrails = value;
    this.renderDynamicLayers();
  }

  @action updateSpecies(event: Event): void {
    const value = (event.target as HTMLSelectElement).value as Species | 'all';
    this.speciesFilter = value;
    this.renderDynamicLayers();
  }

  @action updateScrubber(event: Event): void {
    this.scrubber = Number((event.target as HTMLInputElement).value);
    this.renderDynamicLayers();
  }

  @action selectAnimal(animal: TrackedAnimal): void {
    this.selectedAnimalId = animal.id;
    this.renderDynamicLayers();
  }

  @action zoomToAnimal(animal: TrackedAnimal): void {
    this.selectAnimal(animal);

    const point = interpolatePing(animal.pings, this.currentTimestamp);
    if (!point) return;

    this.zoomToCoordinates(point.lng, point.lat);
  }

  @action resetZoom(): void {
    if (!this.projection) return;
    this.animateGlobe(this.initialGlobeRotation, this.initialGlobeScale, () => {
      this.zoomedIn = false;
    });
  }

  // ── Layer toggle actions — one per layer so the Switch @onCheckedChange ──
  // ── binding works correctly without fn helper                          ──
  @action setLayerBuoys(v: boolean): void {
    this.layerBuoys = v;
    this.updateFluidBuoys();
    this.renderDynamicLayers();
  }

  @action setLayerAnimals(v: boolean): void {
    this.layerAnimals = v;
    this.updateFluidBuoys();
    this.renderDynamicLayers();
  }

  @action setLayerTemperature(v: boolean): void {
    this.layerTemperature = v;
    this.syncLayers();
    this.updateFluidBuoys();
    this.renderDynamicLayers();
  }

  @action setLayerSwell(v: boolean): void {
    this.layerSwell = v;
    this.syncLayers();
    this.updateFluidBuoys();
    this.renderDynamicLayers();
  }

  @action setLayerWind(v: boolean): void {
    this.layerWind = v;
    this.syncLayers();
    this.updateFluidBuoys();
    this.renderDynamicLayers();
  }

  @action setLayerCurrents(v: boolean): void {
    this.layerCurrents = v;
    this.syncLayers();
    this.updateFluidBuoys();
    this.renderDynamicLayers();
  }

  @action setLayerStorms(v: boolean): void {
    this.layerStorms = v;
    this.syncLayers();
    this.updateFluidBuoys();
    this.renderDynamicLayers();
  }

  private syncLayers(): void {
    const active = new Set<OceanLayerType>();
    if (this.layerTemperature) active.add('temperature');
    if (this.layerSwell) active.add('swell');
    if (this.layerWind) active.add('wind');
    if (this.layerCurrents) active.add('currents');
    if (this.layerStorms) active.add('storms');
    this.oceanLayersSource.setLayers(active);
  }

  private onLayersUpdate(data: OceanLayersUpdate): void {
    this.oceanLayerData = data;
    this.updateFluidBuoys();
    this.renderDynamicLayers();
  }

  private onUpdate(update: OceanLiveUpdate): void {
    this.buoys = update.buoys;
    this.animals = update.animals;
    this.buoyUpdatedAt = update.buoyUpdatedAt;
    this.animalUpdatedAt = update.animalUpdatedAt;

    let speciesFilterChanged = false;
    if (
      this.speciesFilter !== 'all' &&
      !update.animals.some((animal) => animal.species === this.speciesFilter)
    ) {
      this.speciesFilter = 'all';
      speciesFilterChanged = true;
    }

    if (!this.selectedAnimalId && update.animals.length > 0) {
      this.selectedAnimalId = update.animals[0]?.id ?? null;
    }

    // If speciesFilter changed (e.g., after data load), trigger the same logic as the selector
    if (speciesFilterChanged) {
      this.renderDynamicLayers();
      return;
    }

    this.updateFluidBuoys();

    try {
      this.renderOceanField();
    } catch {
      // Optionally log error
    } finally {
      this.renderDynamicLayers();
    }
  }

  private async setupMap(): Promise<void> {
    const svg = this.svgEl;
    if (!svg) return;

    const width = svg.clientWidth || 1400;
    const height = svg.clientHeight || 800;
    svg.setAttribute('viewBox', `0 0 ${width} ${height}`);

    const root = d3Select(svg);
    root.selectAll('*').remove();

    const globeScale = Math.min(width, height) / 2 - 10;
    this.initialGlobeScale = globeScale;
    this.projection = geoOrthographic()
      .scale(globeScale)
      .translate([width / 2, height / 2])
      .clipAngle(90)
      .rotate(this.initialGlobeRotation);
    this.path = geoPath(this.projection);

    // SVG clip path that always matches the visible globe circle
    const defs = root.append('defs');
    defs
      .append('clipPath')
      .attr('id', 'olv-globe-clip')
      .append('circle')
      .attr('cx', width / 2)
      .attr('cy', height / 2)
      .attr('r', globeScale);

    const zoomRoot = root
      .append('g')
      .attr('class', 'olv-zoom-layer')
      .attr('clip-path', 'url(#olv-globe-clip)');

    zoomRoot
      .append('path')
      .datum({ type: 'Sphere' })
      .attr('class', 'olv-sphere')
      .attr('d', this.path as never)
      .on('click', () => this.resetZoom());

    zoomRoot
      .append('path')
      .datum(geoGraticule10())
      .attr('class', 'olv-graticule')
      .attr('d', this.path as never);

    try {
      const world = (await fetch('/world-110m.json').then((res) => res.json())) as WorldTopo;
      const countries = feature(world as never, world.objects.countries as never) as {
        features?: unknown[];
      };

      const landFeatures = countries.features ?? [countries];

      zoomRoot
        .append('g')
        .selectAll('path')
        .data(landFeatures)
        .join('path')
        .attr('class', 'olv-land')
        .attr('d', this.path as never);

      zoomRoot
        .append('path')
        .datum(mesh(world as never, world.objects.countries as never, (a, b) => a !== b))
        .attr('class', 'olv-borders')
        .attr('d', this.path as never);
    } catch {
      // Optionally log error
    }

    this.zoomLayer = zoomRoot.node();
    this.trailsLayer = zoomRoot.append('g').attr('class', 'olv-trails').node();
    this.animalsLayer = zoomRoot.append('g').attr('class', 'olv-animals').node();
    this.buoyLayer = zoomRoot.append('g').attr('class', 'olv-buoys').node();
    this.stormsLayer = zoomRoot.append('g').attr('class', 'olv-storms').node();

    this.setupGlobe();
    this.setupFluidRenderer();

    this.renderOceanField();
    this.renderDynamicLayers();
  }

  private renderOceanField(frameTime = performance.now()): void {
    if (this.renderOceanFieldWebGl(frameTime)) {
      return;
    }

    this.renderOceanFieldFallback2d(frameTime);
  }

  private renderOceanFieldFallback2d(frameTime = performance.now()): void {
    const canvas = this.canvasEl;
    const projection = this.projection;
    if (!canvas || !projection || !projection.invert) return;

    const width = canvas.clientWidth || 1400;
    const height = canvas.clientHeight || 800;
    canvas.width = width;
    canvas.height = height;

    const context = canvas.getContext('2d');
    if (!context) return;

    context.clearRect(0, 0, width, height);

    const timeSec = frameTime / 1000;

    const step = 8;
    for (let y = 0; y < height; y += step) {
      for (let x = 0; x < width; x += step) {
        const lngLat = projection.invert([x, y]);
        if (!lngLat) continue;
        const [lng, lat] = lngLat;

        let weightedTemp = 0;
        let flowX = 0;
        let flowY = 0;
        let waveEnergy = 0;
        let weightSum = 0;

        for (const buoy of this.buoys) {
          const dLat = lat - buoy.lat;
          const dLng = lng - buoy.lng;
          const dist2 = dLat * dLat + dLng * dLng + 0.7;
          const weight = 1 / dist2;
          const windRad = ((buoy.windDirDeg - 90) * Math.PI) / 180;
          const speedFactor = 0.2 + buoy.windSpeedMs / 16;
          const period = Math.max(2.2, buoy.wavePeriodS);
          const wavePhase = timeSec * ((2 * Math.PI) / period) * speedFactor;

          weightedTemp += buoy.waterTempC * weight;
          flowX += Math.cos(windRad) * speedFactor * weight;
          flowY += Math.sin(windRad) * speedFactor * weight;
          waveEnergy +=
            (0.5 + 0.5 * Math.sin(wavePhase + (x + y) * 0.02)) * buoy.waveHeightM * weight;
          weightSum += weight;
        }

        if (weightSum <= 0) continue;

        const temp = weightedTemp / weightSum;
        const flowMag = Math.sqrt(flowX * flowX + flowY * flowY) / weightSum;
        const wave = waveEnergy / weightSum;

        context.fillStyle = tempColor(temp);
        context.globalAlpha = Math.max(0.48, Math.min(0.88, 0.52 + flowMag * 0.18 + wave * 0.05));
        context.fillRect(x, y, step, step);
      }
    }

    for (const buoy of this.buoys) {
      const projected = projection([buoy.lng, buoy.lat]);
      if (!projected) continue;

      const windRad = ((buoy.windDirDeg - 90) * Math.PI) / 180;
      const speedFactor = 0.7 + buoy.windSpeedMs / 14;
      const pulse = 8 + ((timeSec * speedFactor * 18) % 26);
      const drift = 3 + ((timeSec * speedFactor * 7) % 14);

      context.beginPath();
      context.strokeStyle = '#d7f3ff';
      context.lineWidth = 1.2;
      context.globalAlpha = Math.min(0.55, 0.2 + buoy.waveHeightM * 0.08);
      context.arc(projected[0], projected[1], pulse, windRad - 0.8, windRad + 0.8);
      context.stroke();

      context.beginPath();
      context.fillStyle = '#eaf8ff';
      context.globalAlpha = 0.25;
      context.arc(
        projected[0] + Math.cos(windRad) * drift,
        projected[1] + Math.sin(windRad) * drift,
        1.7,
        0,
        Math.PI * 2,
      );
      context.fill();
    }

    context.globalAlpha = 1;
  }

  private setupFluidRenderer(): void {
    const canvas = this.canvasEl;
    if (!canvas) return;

    this.gl = null;
    this.fluidProgram = null;
    this.fluidPositionBuffer = null;

    const gl = canvas.getContext('webgl', {
      alpha: true,
      antialias: true,
      premultipliedAlpha: true,
      preserveDrawingBuffer: false,
    });

    if (!gl) return;

    const program = this.createFluidProgram(gl);
    if (!program) return;

    const positionBuffer = gl.createBuffer();
    if (!positionBuffer) return;

    gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]), gl.STATIC_DRAW);

    this.gl = gl;
    this.fluidProgram = program;
    this.fluidPositionBuffer = positionBuffer;
    this.fluidStartTime = performance.now();
    this.updateFluidBuoys();

    this.startFluidAnimation();
  }

  private startFluidAnimation(): void {
    if (this.fluidRaf) {
      cancelAnimationFrame(this.fluidRaf);
      this.fluidRaf = null;
    }

    const frame = (time: number) => {
      this.renderOceanField(time);
      this.fluidRaf = requestAnimationFrame(frame);
    };

    this.fluidRaf = requestAnimationFrame(frame);
  }

  private renderOceanFieldWebGl(frameTime = performance.now()): boolean {
    const canvas = this.canvasEl;
    const gl = this.gl;
    const program = this.fluidProgram;
    const buffer = this.fluidPositionBuffer;
    if (!canvas || !gl || !program || !buffer) return false;

    const width = canvas.clientWidth || 1400;
    const height = canvas.clientHeight || 800;
    if (canvas.width !== width || canvas.height !== height) {
      canvas.width = width;
      canvas.height = height;
    }

    gl.viewport(0, 0, width, height);
    gl.useProgram(program);

    const posLoc = gl.getAttribLocation(program, 'a_position');
    if (posLoc < 0) return false;

    gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
    gl.enableVertexAttribArray(posLoc);
    gl.vertexAttribPointer(posLoc, 2, gl.FLOAT, false, 0, 0);

    const resolutionLoc = gl.getUniformLocation(program, 'u_resolution');
    const timeLoc = gl.getUniformLocation(program, 'u_time');
    const buoyCountLoc = gl.getUniformLocation(program, 'u_buoy_count');
    const buoyArrayALoc = gl.getUniformLocation(program, 'u_buoys_a[0]');
    const buoyArrayBLoc = gl.getUniformLocation(program, 'u_buoys_b[0]');
    if (!resolutionLoc || !timeLoc || !buoyCountLoc || !buoyArrayALoc || !buoyArrayBLoc)
      return false;

    gl.uniform2f(resolutionLoc, width, height);
    gl.uniform1f(timeLoc, Math.max(0, frameTime - this.fluidStartTime) / 1000);
    gl.uniform1i(buoyCountLoc, this.fluidBuoyCount);
    gl.uniform4fv(buoyArrayALoc, this.fluidBuoyDataA);
    gl.uniform4fv(buoyArrayBLoc, this.fluidBuoyDataB);

    gl.enable(gl.BLEND);
    gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
    gl.clearColor(0, 0, 0, 0);
    gl.clear(gl.COLOR_BUFFER_BIT);
    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);

    return true;
  }

  private updateFluidBuoys(): void {
    const projection = this.projection;
    if (!projection) {
      this.fluidBuoyCount = 0;
      return;
    }

    this.fluidBuoyDataA.fill(0);
    this.fluidBuoyDataB.fill(0);

    const now = Date.now();

    let count = 0;

    // ── Buoys layer ────────────────────────────────────────────────────────
    if (this.layerBuoys) {
      for (const buoy of this.buoys) {
        if (count >= MAX_FLUID_BUOYS) break;
        const projected = projection([buoy.lng, buoy.lat]);
        if (!projected) continue;

        const base = count * 4;
        this.fluidBuoyDataA[base] = projected[0];
        this.fluidBuoyDataA[base + 1] = projected[1];
        this.fluidBuoyDataA[base + 2] = buoy.waterTempC;
        this.fluidBuoyDataA[base + 3] = buoy.windSpeedMs;

        this.fluidBuoyDataB[base] = ((buoy.windDirDeg - 90) * Math.PI) / 180;
        this.fluidBuoyDataB[base + 1] = Math.max(2, buoy.wavePeriodS);
        this.fluidBuoyDataB[base + 2] = Math.max(0.1, buoy.waveHeightM);
        const ageMin = Math.max(0, (now - buoy.observedAt) / 60_000);
        this.fluidBuoyDataB[base + 3] = Math.max(0.25, Math.min(1, 1 - ageMin / 180));
        count++;
      }
    }

    // ── Animals layer ──────────────────────────────────────────────────────
    const nowTs = this.currentTimestamp;
    if (this.layerAnimals)
      for (const animal of this.filteredAnimals) {
        if (count >= MAX_FLUID_BUOYS) break;

        const currentPoint = interpolatePing(animal.pings, nowTs);
        if (!currentPoint) continue;

        const projected = projection([currentPoint.lng, currentPoint.lat]);
        if (!projected) continue;

        const pingsUpToNow = animal.pings.filter((p) => p.timestamp <= nowTs);
        const prevPing = pingsUpToNow[pingsUpToNow.length - 2];
        const lastPing = pingsUpToNow[pingsUpToNow.length - 1];

        let swimSpeedMs = 0.4;
        let swimDirRad = 0;

        if (prevPing && lastPing) {
          const dtMs = lastPing.timestamp - prevPing.timestamp;
          if (dtMs > 0) {
            const dLatM = (lastPing.lat - prevPing.lat) * 111_000;
            const dLngM =
              (lastPing.lng - prevPing.lng) * 111_000 * Math.cos((prevPing.lat * Math.PI) / 180);
            const distM = Math.sqrt(dLatM * dLatM + dLngM * dLngM);
            swimSpeedMs = Math.min(12, distM / (dtMs / 1000));

            const prevProjected = projection([prevPing.lng, prevPing.lat]);
            if (prevProjected) {
              swimDirRad = Math.atan2(
                projected[1] - prevProjected[1],
                projected[0] - prevProjected[0],
              );
            }
          }
        }

        const lastPingTime = lastPing?.timestamp ?? null;
        // Age relative to the scrubber timestamp so historical playback is consistent
        const animalAgeMin = lastPingTime ? Math.max(0, (nowTs - lastPingTime) / 60_000) : 9999;
        // Skip animals that haven't pinged recently — they aren't "live"
        if (animalAgeMin > ANIMAL_FLUID_RECENCY_MIN) continue;
        const freshness = Math.max(0.15, Math.min(1, 1 - animalAgeMin / ANIMAL_FLUID_RECENCY_MIN));

        const size = SPECIES_FLUID_SIZE[animal.species];

        const base = count * 4;
        // a: (x, y, neutral_temp, swimSpeedMs)
        this.fluidBuoyDataA[base] = projected[0];
        this.fluidBuoyDataA[base + 1] = projected[1];
        this.fluidBuoyDataA[base + 2] = 14.0; // neutral — animals don't skew temperature color
        this.fluidBuoyDataA[base + 3] = swimSpeedMs;
        // b: (swimDirRad, period, size→radius, freshness)
        this.fluidBuoyDataB[base] = swimDirRad;
        this.fluidBuoyDataB[base + 1] = 3.5; // moderate period; short = energetic local texture
        this.fluidBuoyDataB[base + 2] = size;
        this.fluidBuoyDataB[base + 3] = freshness;
        count++;
      }

    // ── API-data layers (each independent) ────────────────────────────────
    const layerData = this.oceanLayerData;
    if (layerData && layerData.samples.length > 0) {
      const ageHours = Math.max(0, (now - layerData.fetchedAt) / 3_600_000);
      const gridFreshness = Math.max(0.1, Math.min(1, 1 - ageHours / 6));

      // Temperature layer — SST heatmap: drives color gradient, minimal flow
      if (this.layerTemperature) {
        for (const sample of layerData.samples) {
          if (count >= MAX_FLUID_BUOYS) break;
          const projected = projection([sample.lng, sample.lat]);
          if (!projected) continue;
          const base = count * 4;
          this.fluidBuoyDataA[base] = projected[0];
          this.fluidBuoyDataA[base + 1] = projected[1];
          this.fluidBuoyDataA[base + 2] = sample.sstC; // full SST → heatmap color
          this.fluidBuoyDataA[base + 3] = 0.3; // near-zero "wind" — barely any swirl
          this.fluidBuoyDataB[base] = 0;
          this.fluidBuoyDataB[base + 1] = 16; // long period → smooth
          this.fluidBuoyDataB[base + 2] = 0.05; // no wave texture
          this.fluidBuoyDataB[base + 3] = gridFreshness;
          count++;
        }
      }

      // Swell layer — wave height/period/direction: drives wave texture & ripple
      if (this.layerSwell) {
        for (const sample of layerData.samples) {
          if (count >= MAX_FLUID_BUOYS) break;
          const projected = projection([sample.lng, sample.lat]);
          if (!projected) continue;
          const base = count * 4;
          const waveDir = ((sample.waveDirDeg - 90) * Math.PI) / 180;
          this.fluidBuoyDataA[base] = projected[0];
          this.fluidBuoyDataA[base + 1] = projected[1];
          this.fluidBuoyDataA[base + 2] = 14; // neutral temp
          this.fluidBuoyDataA[base + 3] = 1.8; // modest speed — drives ridges not swirl
          this.fluidBuoyDataB[base] = waveDir;
          this.fluidBuoyDataB[base + 1] = Math.max(2, sample.wavePeriodS);
          this.fluidBuoyDataB[base + 2] = Math.max(0.2, sample.waveHeightM);
          this.fluidBuoyDataB[base + 3] = gridFreshness;
          count++;
        }
      }

      // Wind layer — surface wind: drives turbulent swirling flow
      if (this.layerWind) {
        for (const sample of layerData.samples) {
          if (count >= MAX_FLUID_BUOYS) break;
          const projected = projection([sample.lng, sample.lat]);
          if (!projected) continue;
          const base = count * 4;
          const windDir = ((sample.windDirDeg - 90) * Math.PI) / 180;
          this.fluidBuoyDataA[base] = projected[0];
          this.fluidBuoyDataA[base + 1] = projected[1];
          this.fluidBuoyDataA[base + 2] = 14; // neutral temp
          this.fluidBuoyDataA[base + 3] = sample.windSpeedMs; // full wind speed → strong swirl
          this.fluidBuoyDataB[base] = windDir;
          this.fluidBuoyDataB[base + 1] = 6; // short period → choppy
          this.fluidBuoyDataB[base + 2] = 0.8;
          this.fluidBuoyDataB[base + 3] = gridFreshness;
          count++;
        }
      }

      // Currents layer — real ocean surface currents: smooth laminar directional flow
      if (this.layerCurrents) {
        for (const sample of layerData.samples) {
          if (count >= MAX_FLUID_BUOYS) break;
          const projected = projection([sample.lng, sample.lat]);
          if (!projected) continue;
          const base = count * 4;
          const currentDir = ((sample.currentDirDeg - 90) * Math.PI) / 180;
          // Amplify 8× — real currents are 0.05–0.5 m/s, fluid sim expects wind-scale values
          const amplified = sample.currentSpeedMs * 8;
          this.fluidBuoyDataA[base] = projected[0];
          this.fluidBuoyDataA[base + 1] = projected[1];
          this.fluidBuoyDataA[base + 2] = 14; // neutral temp — currents don't color
          this.fluidBuoyDataA[base + 3] = amplified;
          this.fluidBuoyDataB[base] = currentDir;
          this.fluidBuoyDataB[base + 1] = 22; // very long period → slow laminar flow
          this.fluidBuoyDataB[base + 2] = 0.15; // minimal wave texture (currents are smooth)
          this.fluidBuoyDataB[base + 3] = 0.95 * gridFreshness; // high freshness → persistent
          count++;
        }
      }
    }

    this.fluidBuoyCount = count;
  }

  private createFluidProgram(gl: WebGLRenderingContext): WebGLProgram | null {
    const vertexShader = this.compileShader(gl, gl.VERTEX_SHADER, FLUID_VERTEX_SHADER);
    const fragmentShader = this.compileShader(gl, gl.FRAGMENT_SHADER, FLUID_FRAGMENT_SHADER);
    if (!vertexShader || !fragmentShader) return null;

    const program = gl.createProgram();
    if (!program) return null;

    gl.attachShader(program, vertexShader);
    gl.attachShader(program, fragmentShader);
    gl.linkProgram(program);

    if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
      gl.deleteProgram(program);
      return null;
    }

    return program;
  }

  private compileShader(
    gl: WebGLRenderingContext,
    type: number,
    source: string,
  ): WebGLShader | null {
    const shader = gl.createShader(type);
    if (!shader) return null;

    gl.shaderSource(shader, source);
    gl.compileShader(shader);

    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
      gl.deleteShader(shader);
      return null;
    }

    return shader;
  }

  private setupGlobe(): void {
    const svg = this.svgEl;
    if (!svg) return;

    let dragOrigin: { rotation: [number, number, number]; x: number; y: number } | null = null;

    const dragBehavior = d3Drag<SVGSVGElement, unknown>()
      .on('start', (event: D3DragEvent<SVGSVGElement, unknown, unknown>) => {
        dragOrigin = {
          rotation: [...this.projection!.rotate()],
          x: event.x,
          y: event.y,
        };
      })
      .on('drag', (event: D3DragEvent<SVGSVGElement, unknown, unknown>) => {
        if (!dragOrigin || !this.projection) return;
        const sensitivity = 80 / this.projection.scale();
        const [λ, φ, γ] = dragOrigin.rotation;
        this.projection.rotate([
          λ + (event.x - dragOrigin.x) * sensitivity,
          Math.max(-90, Math.min(90, φ - (event.y - dragOrigin.y) * sensitivity)),
          γ,
        ]);
        this.rerenderPaths();
        this.renderDynamicLayers();
      })
      .on('end', () => {
        dragOrigin = null;
      });

    d3Select(svg)
      .call(dragBehavior)
      .on(
        'wheel.globe',
        (event: WheelEvent) => {
          event.preventDefault();
          if (!this.projection) return;
          const factor = event.deltaY > 0 ? 0.92 : 1.085;
          const next = Math.max(
            this.initialGlobeScale * 0.85,
            Math.min(this.initialGlobeScale * 14, this.projection.scale() * factor),
          );
          this.projection.scale(next);
          this.zoomedIn = next > this.initialGlobeScale * 1.1;
          this.rerenderPaths();
          this.renderDynamicLayers();
        },
        { passive: false } as AddEventListenerOptions,
      );
  }

  private rerenderPaths(): void {
    const svg = this.svgEl;
    if (!svg || !this.path || !this.projection) return;

    // Keep the SVG clip circle in sync so it always hugs the globe edge
    const [cx, cy] = this.projection.translate();
    d3Select(svg)
      .select('#olv-globe-clip circle')
      .attr('cx', cx)
      .attr('cy', cy)
      .attr('r', this.projection.scale());

    d3Select(svg)
      .select('.olv-sphere')
      .attr('d', this.path as never);
    d3Select(svg)
      .select('.olv-graticule')
      .attr('d', this.path as never);
    d3Select(svg)
      .selectAll('.olv-land')
      .attr('d', this.path as never);
    d3Select(svg)
      .select('.olv-borders')
      .attr('d', this.path as never);
    this.updateFluidBuoys();
    this.renderOceanField();
  }

  private zoomToCoordinates(lng: number, lat: number): void {
    if (!this.projection) return;
    const targetRot: [number, number, number] = [-lng, -lat, 0];
    const targetScale = Math.max(this.initialGlobeScale * 2.5, this.projection.scale());
    this.animateGlobe(targetRot, targetScale, () => {
      this.zoomedIn = true;
    });
  }

  private animateGlobe(
    targetRot: [number, number, number],
    targetScale: number,
    onDone?: () => void,
  ): void {
    if (!this.projection) return;
    const startRot = [...this.projection.rotate()] as [number, number, number];
    const startScale = this.projection.scale();
    const start = performance.now();
    const duration = 750;

    const tick = (now: number) => {
      const raw = Math.min(1, (now - start) / duration);
      // ease-in-out cubic
      const t = raw < 0.5 ? 4 * raw * raw * raw : 1 - (-2 * raw + 2) ** 3 / 2;
      this.projection!.rotate([
        startRot[0] + (targetRot[0] - startRot[0]) * t,
        startRot[1] + (targetRot[1] - startRot[1]) * t,
        startRot[2] + (targetRot[2] - startRot[2]) * t,
      ]);
      this.projection!.scale(startScale + (targetScale - startScale) * t);
      this.rerenderPaths();
      this.renderDynamicLayers();
      if (raw < 1) {
        requestAnimationFrame(tick);
      } else {
        onDone?.();
      }
    };

    requestAnimationFrame(tick);
  }

  private renderDynamicLayers(): void {
    if (!this.animalsLayer || !this.trailsLayer || !this.buoyLayer || !this.projection) return;

    const nowTs = this.currentTimestamp;
    const animals = this.filteredAnimals;
    const selectedId = this.selectedAnimalId;
    const orderedAnimals = [...animals].sort((a, b) => {
      const aSelected = a.id === selectedId ? 1 : 0;
      const bSelected = b.id === selectedId ? 1 : 0;
      return aSelected - bSelected;
    });

    const trailRoot = d3Select(this.trailsLayer);
    const animalRoot = d3Select(this.animalsLayer);
    const buoyRoot = d3Select(this.buoyLayer);

    trailRoot.selectAll('*').remove();
    animalRoot.selectAll('*').remove();
    buoyRoot.selectAll('*').remove();

    const lineBuilder = line<[number, number]>();
    // Icon sizes are fixed in screen pixels — no zoom-group counter-scale needed for globe
    const scale = 1;

    for (const animal of this.layerAnimals ? orderedAnimals : []) {
      const point = interpolatePing(animal.pings, nowTs);
      if (!point) continue;
      const projected = this.projection([point.lng, point.lat]);
      if (!projected) continue;

      // --- Animal tracks (trails) ---
      if (this.showTrails) {
        const trailPoints = animal.pings
          .filter((ping) => ping.timestamp <= nowTs)
          .slice(-16)
          .map((ping) => this.projection?.([ping.lng, ping.lat]))
          .filter((coords): coords is [number, number] => Boolean(coords));

        if (trailPoints.length > 1) {
          // To keep the trail anchored, translate to the first point, scale, then shift path back
          const [x0, y0] = trailPoints[0]!;
          const shiftedPoints = trailPoints.map(([x, y]): [number, number] => [x - x0, y - y0]);
          const trailGroup = trailRoot
            .append('g')
            .attr('transform', `translate(${x0},${y0}) scale(${1 / scale})`);
          trailGroup
            .append('path')
            .attr('d', lineBuilder(shiftedPoints) ?? '')
            .attr('class', 'olv-trail')
            .attr('opacity', this.selectedAnimalId === animal.id ? 0.9 : 0.45);
        }
      }

      // --- Live / stale check ---
      // Find the most recent ping at or before the current scrubber timestamp
      let lastPingTs: number | null = null;
      for (let i = animal.pings.length - 1; i >= 0; i--) {
        if (animal.pings[i]!.timestamp <= nowTs) {
          lastPingTs = animal.pings[i]!.timestamp;
          break;
        }
      }
      const animalAgeMin = lastPingTs ? Math.max(0, (nowTs - lastPingTs) / 60_000) : 9999;
      const isLive = animalAgeMin <= ANIMAL_FLUID_RECENCY_MIN;

      // --- Animal icon ---
      const group = animalRoot
        .append('g')
        .attr('transform', `translate(${projected[0]}, ${projected[1]}) scale(${1 / scale})`)
        .attr('class', `olv-animal ${this.selectedAnimalId === animal.id ? 'active' : ''}`)
        .attr('opacity', isLive ? 1 : 0.25)
        .on('click', () => this.zoomToAnimal(animal));

      // Ripple rings for live animals (rendered before the dot so they appear behind it)
      if (isLive) {
        group.append('circle').attr('class', 'olv-animal-ripple ring-1');
        group.append('circle').attr('class', 'olv-animal-ripple ring-2');
      }

      group
        .append('circle')
        .attr('r', 7)
        .attr('class', 'olv-animal-dot')
        .attr('opacity', point.depthM ? Math.max(0.28, 1 - point.depthM / 850) : 1);

      group
        .append('image')
        .attr('class', 'olv-animal-glyph')
        .attr('href', speciesIconDataUri(animal.species))
        .attr('x', -6)
        .attr('y', -6)
        .attr('width', 12)
        .attr('height', 12);

      if (this.selectedAnimalId === animal.id) {
        group
          .append('text')
          .attr('class', `olv-animal-label ${speciesLabelClass(animal.species)}`)
          .attr('x', 10)
          .attr('y', -10)
          .text(animal.name);
      }
    }

    if (this.layerBuoys) {
      for (const buoy of this.buoys) {
        const projected = this.projection([buoy.lng, buoy.lat]);
        if (projected) {
          const [x, y] = projected;
          const windLen = Math.min(18, 4 + buoy.windSpeedMs * 0.8);
          const rad = ((buoy.windDirDeg - 90) * Math.PI) / 180;
          // Use local coords (origin = buoy center) so scale(1/scale) keeps screen size constant
          const lx2 = Math.cos(rad) * windLen;
          const ly2 = Math.sin(rad) * windLen;

          const buoyGroup = buoyRoot
            .append('g')
            .attr('transform', `translate(${x},${y}) scale(${1 / scale})`);
          buoyGroup
            .append('circle')
            .attr('cx', 0)
            .attr('cy', 0)
            .attr('r', 2.8)
            .attr('class', 'olv-buoy-dot')
            .style('cursor', 'pointer')
            .on('mouseover', (event: MouseEvent) => {
              this.buoyTooltip = { buoy, x: event.clientX, y: event.clientY };
            })
            .on('mousemove', (event: MouseEvent) => {
              this.buoyTooltip = { buoy, x: event.clientX, y: event.clientY };
            })
            .on('mouseleave', () => {
              this.buoyTooltip = null;
            });
          buoyGroup
            .append('line')
            .attr('x1', 0)
            .attr('y1', 0)
            .attr('x2', lx2)
            .attr('y2', ly2)
            .attr('class', 'olv-buoy-wind');
        }
      }
    }

    // Render active storm centers
    if (this.stormsLayer) {
      const stormRoot = d3Select(this.stormsLayer);
      stormRoot.selectAll('*').remove();

      if (this.layerStorms && this.oceanLayerData) {
        for (const storm of this.oceanLayerData.storms) {
          const projected = this.projection([storm.lng, storm.lat]);
          if (!projected) continue;
          const [sx, sy] = projected;
          const catClass =
            storm.category >= 3 ? 'major' : storm.category >= 1 ? 'hurricane' : 'tropical';
          const stormGroup = stormRoot
            .append('g')
            .attr('transform', `translate(${sx},${sy})`)
            .attr('class', `olv-storm ${catClass}`);

          stormGroup.append('circle').attr('r', 10).attr('class', 'olv-storm-ring');
          stormGroup.append('circle').attr('r', 3.5).attr('class', 'olv-storm-eye');

          // Movement arrow
          const movRad = ((storm.movementDirDeg - 90) * Math.PI) / 180;
          const arrowLen = 14;
          stormGroup
            .append('line')
            .attr('x1', 0)
            .attr('y1', 0)
            .attr('x2', Math.cos(movRad) * arrowLen)
            .attr('y2', Math.sin(movRad) * arrowLen)
            .attr('class', 'olv-storm-track');

          stormGroup
            .append('text')
            .attr('class', 'olv-storm-label')
            .attr('x', 13)
            .attr('y', -8)
            .text(storm.category >= 1 ? `Cat ${storm.category} – ${storm.name}` : storm.name);
        }
      }
    }

    this.updateFluidBuoys();
  }

  <template>
    <section class='olv-app' {{this.setup}}>
      <div class='olv-map-wrap'>
        <canvas class='olv-ocean-canvas'></canvas>
        <svg class='olv-map-svg'></svg>

        <div class='eqv-title olv-title'>
          <h1>Ocean Live</h1>
          <p>Buoys, animals &amp; ocean layers</p>
        </div>

        <aside class='eqv-panel eqv-panel-left'>
          <div class='eqv-panel-head'>
            <h3>Ocean Controls</h3>
            <button type='button' class='eqv-panel-toggle' {{on 'click' this.toggleControls}}>
              <Icon @svg={{if this.controlsExpanded ChevronUp ChevronDown}} @size={{14}} />
            </button>
          </div>

          {{#if this.controlsExpanded}}
            <div class='eqv-panel-body'>
              <div class='eqv-control-group'>
                <label>
                  Species
                  <select disabled={{this.speciesDisabled}} {{on 'change' this.updateSpecies}}>
                    {{#each this.speciesOptions as |species|}}
                      <option value={{species}} selected={{this.isSpeciesSelected species}}>
                        {{this.labelForSpecies species}}
                      </option>
                    {{/each}}
                  </select>
                </label>
              </div>

              <div class='eqv-control-group'>
                <label>
                  Time scrubber
                  <input
                    type='range'
                    min='0'
                    max='100'
                    step='1'
                    value={{this.scrubber}}
                    {{on 'input' this.updateScrubber}}
                  />
                </label>
              </div>

              <div class='eqv-control-group'>
                <div class='eqv-panel-subhead'>Layers</div>
                <div class='eqv-control-grid'>
                  <div class='eqv-switch-row'>
                    <span>Buoys</span>
                    <Switch @checked={{this.layerBuoys}} @onCheckedChange={{this.setLayerBuoys}} />
                  </div>
                  <div class='eqv-switch-row'>
                    <span>Animals</span>
                    <Switch
                      @checked={{this.layerAnimals}}
                      @onCheckedChange={{this.setLayerAnimals}}
                    />
                  </div>
                  <div class='eqv-switch-row'>
                    <span>Trails</span>
                    <Switch @checked={{this.showTrails}} @onCheckedChange={{this.setShowTrails}} />
                  </div>
                  <div class='eqv-switch-row'>
                    <span>Temperature</span>
                    <Switch
                      @checked={{this.layerTemperature}}
                      @onCheckedChange={{this.setLayerTemperature}}
                    />
                  </div>
                  <div class='eqv-switch-row'>
                    <span>Swell</span>
                    <Switch @checked={{this.layerSwell}} @onCheckedChange={{this.setLayerSwell}} />
                  </div>
                  <div class='eqv-switch-row'>
                    <span>Wind</span>
                    <Switch @checked={{this.layerWind}} @onCheckedChange={{this.setLayerWind}} />
                  </div>
                  <div class='eqv-switch-row'>
                    <span>Currents</span>
                    <Switch
                      @checked={{this.layerCurrents}}
                      @onCheckedChange={{this.setLayerCurrents}}
                    />
                  </div>
                  <div class='eqv-switch-row'>
                    <span>Storms</span>
                    <Switch
                      @checked={{this.layerStorms}}
                      @onCheckedChange={{this.setLayerStorms}}
                    />
                  </div>
                </div>
              </div>

              <div class='eqv-legend-inline'>
                <div class='eqv-panel-subhead'>Status</div>
                <ul>
                  <li>{{this.buoyStatus}}</li>
                  <li>{{this.animalStatus}}</li>
                  {{#if this.layerDataStatus}}
                    <li>{{this.layerDataStatus}}</li>
                  {{/if}}
                </ul>
              </div>
            </div>
          {{/if}}
        </aside>

        <aside class='eqv-panel eqv-panel-right'>
          <div class='eqv-panel-head'>
            <h3>Animals</h3>
            <button type='button' class='eqv-panel-toggle' {{on 'click' this.toggleFeed}}>
              <Icon @svg={{if this.feedExpanded ChevronUp ChevronDown}} @size={{14}} />
            </button>
          </div>

          {{#if this.feedExpanded}}
            <div class='eqv-panel-body eqv-feed-body'>
              {{#if this.animalsLoading}}
                <div class='olv-loading'>
                  <span class='eqv-status live'>Loading live animals…</span>
                </div>
              {{/if}}

              <ul>
                {{#each this.filteredAnimals as |animal|}}
                  <li>
                    <button
                      type='button'
                      class='eqv-feed-item {{if (this.isSelectedAnimal animal) "active"}}'
                      {{on 'click' (fn this.zoomToAnimal animal)}}
                    >
                      <span class='badge {{this.badgeClassForSpecies animal.species}}'>
                        {{this.labelForSpecies animal.species}}
                      </span>
                      <span class='place'>{{animal.name}}</span>
                    </button>
                  </li>
                {{/each}}

              </ul>

              {{#if this.showEmptyAnimalsState}}
                <p class='olv-empty-state'>No animals available for this filter yet.</p>
              {{/if}}

              {{#if this.selectedAnimal}}
                <div class='olv-animal-profile'>
                  <h4>{{this.selectedAnimal.name}}</h4>
                  <p>{{this.labelForSpecies this.selectedAnimal.species}}</p>
                  <p>{{this.selectedAnimal.profile}}</p>
                  <p>Last seen: {{this.selectedAnimalLastSeen}}</p>
                </div>
              {{/if}}
            </div>
          {{/if}}
        </aside>

        {{#if this.zoomedIn}}
          <button class='eqv-reset' type='button' {{on 'click' this.resetZoom}}>Reset zoom</button>
        {{/if}}

        {{#if this.buoyTooltipData}}
          <div class='eqv-tooltip' style={{this.buoyTooltipStyle}}>
            <p class='olv-buoy-tooltip-station'>{{this.buoyTooltipData.label}}</p>
            <p>Water: {{this.buoyTooltipData.temp}}</p>
            <p>Waves: {{this.buoyTooltipData.wave}}</p>
            <p>Wind: {{this.buoyTooltipData.wind}}</p>
            <p>{{this.buoyTooltipData.observed}}</p>
          </div>
        {{/if}}
      </div>
    </section>
  </template>
}
