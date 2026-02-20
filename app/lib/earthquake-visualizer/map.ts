import {
  geoContains,
  geoGraticule10,
  geoNaturalEarth1,
  geoPath,
  type GeoPath,
  type GeoProjection,
} from 'd3-geo';
import {
  type D3ZoomEvent,
  pointer,
  scaleSqrt,
  select,
  zoom,
  zoomIdentity,
  type Selection,
  type ZoomBehavior,
  type ZoomTransform,
} from 'd3';
import { feature, mesh } from 'topojson-client';
import { MAG_COLORS, TECTONIC_PLATES_URL } from './config';
import type { EarthquakeEvent } from './types';

type SvgSelection = Selection<SVGSVGElement, unknown, null, undefined>;

interface MapCallbacks {
  onHover: (quake: EarthquakeEvent, x: number, y: number) => void;
  onHoverOut: () => void;
  onBackgroundClick: () => void;
  onZoomStateChange: (isZoomed: boolean) => void;
  onQuakeClick: (quake: EarthquakeEvent) => void;
}

export class EarthquakeMap {
  private svg!: SvgSelection;
  private projection!: GeoProjection;
  private path!: GeoPath;
  private zoomBehavior!: ZoomBehavior<SVGSVGElement, unknown>;
  private zoomLayer!: Selection<SVGGElement, unknown, null, undefined>;
  private markerLayer!: Selection<SVGGElement, unknown, null, undefined>;
  private heatmapLayer!: Selection<SVGGElement, unknown, null, undefined>;
  private tectonicLayer!: Selection<SVGGElement, unknown, null, undefined>;
  private landFeatures: GeoJSON.Feature[] = [];
  private width = 1200;
  private height = 720;
  private currentTransform = zoomIdentity;
  private heatmapEnabled = false;
  private tectonicEnabled = false;
  private activeQuakeId: string | null = null;

  constructor(
    private readonly element: SVGSVGElement,
    private readonly callbacks: MapCallbacks,
  ) {}

  async init(): Promise<void> {
    this.width = this.element.clientWidth || 1200;
    this.height = this.element.clientHeight || 720;

    this.svg = select(this.element).attr('viewBox', `0 0 ${this.width} ${this.height}`);
    this.svg.selectAll('*').remove();

    this.projection = geoNaturalEarth1();
    this.path = geoPath(this.projection);

    this.zoomLayer = this.svg.append('g').attr('class', 'eq-zoom-layer');

    const backgroundLayer = this.zoomLayer.append('g');
    const graticuleLayer = this.zoomLayer.append('g');
    const landLayer = this.zoomLayer.append('g');
    const borderLayer = this.zoomLayer.append('g');
    this.tectonicLayer = this.zoomLayer
      .append('g')
      .attr('class', 'eq-tectonic-layer')
      .style('display', 'none');
    this.heatmapLayer = this.zoomLayer.append('g').attr('class', 'eq-heatmap-layer');
    this.markerLayer = this.zoomLayer.append('g').attr('class', 'eq-marker-layer');

    const world = (await this.loadWorld()) as { objects: { countries: unknown } };
    const sphere = { type: 'Sphere' } as const;

    this.projection.fitExtent(
      [
        [24, 24],
        [this.width - 24, this.height - 24],
      ],
      sphere,
    );

    this.path = geoPath(this.projection);

    backgroundLayer
      .append('path')
      .datum(sphere)
      .attr('class', 'eq-sphere')
      .attr('d', this.path)
      .on('click', () => {
        this.resetZoom();
        this.callbacks.onBackgroundClick();
      });

    graticuleLayer
      .append('path')
      .datum(geoGraticule10())
      .attr('class', 'eq-graticule')
      .attr('d', this.path);

    landLayer
      .selectAll('path')
      .data(this.landFeatures)
      .join('path')
      .attr('class', 'eq-land')
      .attr('d', this.path);

    const countryMesh = mesh(world as never, world.objects.countries as never, (a, b) => a !== b);
    borderLayer.append('path').datum(countryMesh).attr('class', 'eq-borders').attr('d', this.path);

    this.setupZoom();
    void this.loadTectonicOverlay();
  }

  destroy(): void {
    if (this.svg) {
      this.svg.on('.zoom', null);
    }
  }

  setHeatmapEnabled(enabled: boolean): void {
    this.heatmapEnabled = enabled;
    this.heatmapLayer.style('display', enabled ? 'inline' : 'none');
    this.markerLayer.style('display', enabled ? 'none' : 'inline');
  }

  setTectonicEnabled(enabled: boolean): void {
    this.tectonicEnabled = enabled;
    this.tectonicLayer.style('display', enabled ? 'inline' : 'none');
  }

  render(events: EarthquakeEvent[], newIds: Set<string>): void {
    if (!this.path) return;

    const dataWithLand = events.map((event) => ({
      ...event,
      isOnLand:
        event.isOnLand ??
        this.landFeatures.some((feature) => geoContains(feature as never, [event.lng, event.lat])),
    }));

    this.renderMarkers(dataWithLand, newIds);
    this.renderHeatmap(dataWithLand);
  }

  zoomToQuake(quake: EarthquakeEvent): void {
    const projected = this.projection([quake.lng, quake.lat]);
    if (!projected) return;

    this.activeQuakeId = quake.id;
    const [x, y] = projected;
    const scale = quake.mag >= 6 ? 6 : 4;
    const transform = zoomIdentity
      .translate(this.width / 2, this.height / 2)
      .scale(scale)
      .translate(-x, -y);
    const applyTransform = this.zoomBehavior.transform.bind(this.zoomBehavior);

    this.svg.transition().duration(750).call(applyTransform, transform);
  }

  resetZoom(): void {
    this.activeQuakeId = null;
    const applyTransform = this.zoomBehavior.transform.bind(this.zoomBehavior);
    this.svg.transition().duration(750).call(applyTransform, zoomIdentity);
  }

  private async loadWorld(): Promise<unknown> {
    const response = await fetch('/world-110m.json');
    const topo = (await response.json()) as {
      objects: { countries: unknown };
    };
    const countries = feature(topo as never, topo.objects.countries as never) as
      | GeoJSON.FeatureCollection
      | GeoJSON.Feature;
    this.landFeatures = 'features' in countries ? countries.features : [countries];
    return topo;
  }

  private async loadTectonicOverlay(): Promise<void> {
    try {
      const response = await fetch(TECTONIC_PLATES_URL, { cache: 'force-cache' });
      if (!response.ok) return;
      const geojson = (await response.json()) as GeoJSON.FeatureCollection;

      this.tectonicLayer
        .selectAll('path')
        .data(geojson.features)
        .join('path')
        .attr('class', 'eq-tectonic')
        .attr('d', this.path as never);

      this.setTectonicEnabled(this.tectonicEnabled);
    } catch (error) {
      console.warn('Unable to load tectonic plate overlay', error);
    }
  }

  private setupZoom(): void {
    this.zoomBehavior = zoom<SVGSVGElement, unknown>()
      .scaleExtent([0.8, 12])
      .on('zoom', (event: D3ZoomEvent<SVGSVGElement, unknown>) => {
        this.currentTransform = event.transform;
        this.zoomLayer.attr('transform', event.transform.toString());

        this.markerLayer
          .selectAll<SVGGElement, EarthquakeEvent>('.eq-marker')
          .attr('transform', (d) => this.markerTransform(d, event.transform));

        this.callbacks.onZoomStateChange(event.transform.k > 1.05);
      });

    this.svg.call(this.zoomBehavior);
  }

  private renderMarkers(events: EarthquakeEvent[], newIds: Set<string>): void {
    const join = this.markerLayer
      .selectAll<SVGGElement, EarthquakeEvent>('.eq-marker')
      .data(events, (d) => d.id)
      .join(
        (enter) => {
          const marker = enter
            .append('g')
            .attr('class', 'eq-marker')
            .style('opacity', 0)
            .on('mousemove', (event, quake) => {
              const [x, y] = pointer(event, this.element);
              this.callbacks.onHover(quake, x, y);
            })
            .on('mouseleave', () => this.callbacks.onHoverOut())
            .on('click', (_, quake) => {
              this.zoomToQuake(quake);
              this.callbacks.onQuakeClick(quake);
            });

          marker.append('circle').attr('class', 'eq-core');
          marker.append('circle').attr('class', 'eq-active-ring');
          marker.append('circle').attr('class', 'eq-ripple ring-1');
          marker.append('circle').attr('class', 'eq-ripple ring-2');
          marker.append('circle').attr('class', 'eq-ripple ring-3');

          marker
            .transition()
            .duration(300)
            .style('opacity', 1)
            .attr('transform', (d) => `${this.markerTransform(d, this.currentTransform)} scale(1)`);

          return marker;
        },
        (update) => update,
        (exit) => exit.transition().duration(2_000).style('opacity', 0).remove(),
      );

    join.each((quake, index, groups) => {
      const markerElement = groups[index];
      if (!markerElement) return;
      const marker = select(markerElement);
      const color = magnitudeColor(quake.mag);
      const rippleColor = quake.isOnLand ? color : '#4fc3f7';
      const radius = markerRadius(quake.mag);
      const opacity = depthOpacity(quake.depth);
      const duration = 2 + quake.mag * 0.6;

      marker
        .style('--base-r', String(radius))
        .style('--ripple-duration', `${duration}s`)
        .style('--ripple-color', rippleColor)
        .style('--core-color', color)
        .classed('eq-marker-new', newIds.has(quake.id))
        .classed('eq-marker-active', this.activeQuakeId === quake.id)
        .attr('transform', this.markerTransform(quake, this.currentTransform));

      marker.select<SVGCircleElement>('.eq-core').attr('r', radius).style('opacity', opacity);

      marker
        .select<SVGCircleElement>('.eq-active-ring')
        .attr('r', radius + 3)
        .style('opacity', this.activeQuakeId === quake.id ? 0.9 : 0);

      marker
        .selectAll<SVGCircleElement, EarthquakeEvent>('.eq-ripple')
        .attr('r', radius)
        .style('opacity', 0.65);
    });
  }

  private renderHeatmap(events: EarthquakeEvent[]): void {
    const heatScale = scaleSqrt<number, number>().domain([0, 8]).range([8, 90]);

    this.heatmapLayer
      .selectAll<SVGCircleElement, EarthquakeEvent>('.eq-heat')
      .data(events, (d) => d.id)
      .join(
        (enter) =>
          enter
            .append('circle')
            .attr('class', 'eq-heat')
            .attr('r', 0)
            .transition()
            .duration(400)
            .attr('r', (d) => heatScale(d.mag)),
        (update) => update,
        (exit) => exit.transition().duration(700).attr('r', 0).remove(),
      )
      .attr('cx', (d) => this.projection([d.lng, d.lat])?.[0] ?? -99_999)
      .attr('cy', (d) => this.projection([d.lng, d.lat])?.[1] ?? -99_999)
      .attr('fill', (d) => magnitudeColor(d.mag))
      .attr('opacity', (d) => Math.max(0.08, depthOpacity(d.depth) * 0.25));
  }

  private markerTransform(d: EarthquakeEvent, transform: ZoomTransform): string {
    const projected = this.projection([d.lng, d.lat]);
    if (!projected) return 'translate(-9999 -9999)';
    const [x, y] = projected;
    return `translate(${x} ${y}) scale(${1 / transform.k})`;
  }
}

export function markerRadius(mag: number): number {
  return Math.max(3, 2 + mag * 2.5);
}

export function depthOpacity(depth: number): number {
  return Math.max(0.2, 1 - depth / 900);
}

export function magnitudeColor(mag: number): string {
  const bucket = MAG_COLORS.find((row) => mag >= row.min);
  return bucket?.color ?? '#4caf50';
}
