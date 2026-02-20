import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { modifier } from 'ember-modifier';
import Icon from 'fer-resume/components/icon';
import Switch from 'fer-resume/components/ui/switch';
import { ChevronDown, ChevronUp } from 'lucide-static';
import { EarthquakeDataSource } from 'fer-resume/lib/earthquake-visualizer/data';
import { RumbleAudio } from 'fer-resume/lib/earthquake-visualizer/audio';
import { EarthquakeMap } from 'fer-resume/lib/earthquake-visualizer/map';
import type {
  DataStatus,
  DataUpdate,
  EarthquakeEvent,
  FeedWindow,
  StatusTone,
  TooltipState,
} from 'fer-resume/lib/earthquake-visualizer/types';

function relativeTime(timestamp: number, now: number): string {
  const diffMs = Math.max(0, now - timestamp);
  const minutes = Math.floor(diffMs / 60_000);
  if (minutes < 1) return 'just now';
  if (minutes === 1) return '1 minute ago';
  if (minutes < 60) return `${minutes} minutes ago`;
  const hours = Math.floor(minutes / 60);
  if (hours === 1) return '1 hour ago';
  if (hours < 24) return `${hours} hours ago`;
  const days = Math.floor(hours / 24);
  return `${days} day${days > 1 ? 's' : ''} ago`;
}

export default class EarthquakeVisualizer extends Component {
  private dataSource = new EarthquakeDataSource({
    onUpdate: (update) => this.handleDataUpdate(update),
    onStatus: (status) => this.handleStatus(status),
  });

  private audio = new RumbleAudio();
  private map: EarthquakeMap | null = null;
  private ticker: number | null = null;
  private replayTimer: number | null = null;
  private didInitialZoom = false;

  @tracked feedWindow: FeedWindow = 'hour';
  @tracked events: EarthquakeEvent[] = [];
  @tracked tooltip: TooltipState | null = null;
  @tracked selectedQuakeId: string | null = null;
  @tracked statusTone: StatusTone = 'stale';
  @tracked statusMessage = 'Connecting...';
  @tracked lastUpdatedAt: number | null = null;
  @tracked now = Date.now();
  @tracked muted = false;
  @tracked heatmapMode = false;
  @tracked showTectonicPlates = true;
  @tracked replayMode = false;
  @tracked pushAlertsEnabled = false;
  @tracked zoomedIn = false;
  @tracked controlsExpanded = true;
  @tracked feedExpanded = true;

  setup = modifier((element: HTMLDivElement) => {
    this.didInitialZoom = false;

    if ('Notification' in window && Notification.permission === 'granted') {
      this.pushAlertsEnabled = true;
    }

    const svg = element.querySelector('svg');
    if (!(svg instanceof SVGSVGElement)) return;

    this.map = new EarthquakeMap(svg, {
      onHover: (quake, x, y) => {
        this.tooltip = { quake, x, y };
      },
      onHoverOut: () => {
        this.tooltip = null;
      },
      onBackgroundClick: () => {
        this.selectedQuakeId = null;
      },
      onZoomStateChange: (isZoomed) => {
        this.zoomedIn = isZoomed;
      },
      onQuakeClick: (quake) => {
        this.selectedQuakeId = quake.id;
      },
    });

    void this.map.init().then(() => {
      this.map?.setHeatmapEnabled(this.heatmapMode);
      this.map?.setTectonicEnabled(this.showTectonicPlates);
      this.dataSource.start(this.feedWindow);
    });

    this.audio.setMuted(this.muted);
    window.addEventListener('pointerdown', this.audio.unlock, { once: true });

    this.ticker = window.setInterval(() => {
      this.now = Date.now();
      this.refreshStaleStatus();
    }, 1_000);

    return () => {
      this.dataSource.stop();
      this.map?.destroy();
      this.map = null;
      if (this.ticker) {
        clearInterval(this.ticker);
        this.ticker = null;
      }
      if (this.replayTimer) {
        clearInterval(this.replayTimer);
        this.replayTimer = null;
      }
    };
  });

  get sidebarEvents(): EarthquakeEvent[] {
    return this.events.slice(0, 10);
  }

  get statusLabel(): string {
    if (!this.lastUpdatedAt) return this.statusMessage;
    const seconds = Math.floor((this.now - this.lastUpdatedAt) / 1000);
    return `${this.statusMessage} · Updated ${seconds}s ago`;
  }

  get soundEnabled(): boolean {
    return !this.muted;
  }

  get tooltipStyle(): string {
    if (!this.tooltip) return '';
    return `left:${Math.min(this.tooltip.x + 16, window.innerWidth - 280)}px;top:${Math.max(8, this.tooltip.y + 16)}px;`;
  }

  get selectedQuake(): EarthquakeEvent | null {
    return this.events.find((event) => event.id === this.selectedQuakeId) ?? null;
  }

  @action
  setFeedWindow(event: Event): void {
    const target = event.target as HTMLSelectElement;
    const next = target.value as FeedWindow;
    this.feedWindow = next;
    this.selectedQuakeId = null;
    this.dataSource.setFeedWindow(next);
  }

  @action
  toggleMute(): void {
    this.muted = !this.muted;
    this.audio.setMuted(this.muted);
  }

  @action
  setMuted(checked: boolean): void {
    if (checked === !this.muted) return;
    this.toggleMute();
  }

  @action
  toggleHeatmap(): void {
    this.heatmapMode = !this.heatmapMode;
    this.map?.setHeatmapEnabled(this.heatmapMode);
  }

  @action
  setHeatmapMode(checked: boolean): void {
    if (checked === this.heatmapMode) return;
    this.toggleHeatmap();
  }

  @action
  toggleTectonicPlates(): void {
    this.showTectonicPlates = !this.showTectonicPlates;
    this.map?.setTectonicEnabled(this.showTectonicPlates);
  }

  @action
  setTectonicPlates(checked: boolean): void {
    if (checked === this.showTectonicPlates) return;
    this.toggleTectonicPlates();
  }

  @action
  toggleControlsPanel(): void {
    this.controlsExpanded = !this.controlsExpanded;
  }

  @action
  toggleFeedPanel(): void {
    this.feedExpanded = !this.feedExpanded;
  }

  @action
  resetZoom(): void {
    this.map?.resetZoom();
    this.selectedQuakeId = null;
  }

  @action
  zoomToSidebar(event: EarthquakeEvent): void {
    this.selectedQuakeId = event.id;
    this.map?.zoomToQuake(event);
  }

  @action
  togglePushAlerts(): void {
    if (!('Notification' in window)) {
      this.pushAlertsEnabled = false;
      return;
    }

    if (Notification.permission === 'default') {
      // Must call requestPermission synchronously from the user gesture (no await before it)
      // so mobile Safari treats it as a valid gesture and shows the permission prompt.
      void Notification.requestPermission().then((permission) => {
        this.pushAlertsEnabled = permission === 'granted';
      });
      return;
    }

    this.pushAlertsEnabled = Notification.permission === 'granted' && !this.pushAlertsEnabled;
  }

  @action
  setPushAlertsEnabled(checked: boolean): void {
    if (checked === this.pushAlertsEnabled) return;
    this.togglePushAlerts();
  }

  @action
  toggleReplayMode(): void {
    this.replayMode = !this.replayMode;

    if (!this.replayMode) {
      this.dataSource.setPaused(false);
      if (this.replayTimer) {
        clearInterval(this.replayTimer);
        this.replayTimer = null;
      }
      return;
    }

    this.dataSource.setPaused(true);
    const replayEvents = [...this.events].sort((a, b) => a.time - b.time);
    const windowEvents: EarthquakeEvent[] = [];
    let index = 0;

    if (this.replayTimer) clearInterval(this.replayTimer);
    this.replayTimer = window.setInterval(() => {
      if (index >= replayEvents.length) {
        this.toggleReplayMode();
        return;
      }

      const next = replayEvents[index++];
      if (!next) return;
      windowEvents.push(next);
      while (windowEvents.length > 60) windowEvents.shift();
      this.events = [...windowEvents].sort((a, b) => b.time - a.time);
      this.map?.render(this.events, new Set([next.id]));
      this.audio.playFor(next);
      this.notifyIfNeeded(next);
    }, 700);
  }

  @action
  setReplayMode(checked: boolean): void {
    if (checked === this.replayMode) return;
    this.toggleReplayMode();
  }

  formatRelativeTime = (event: EarthquakeEvent): string => {
    return relativeTime(event.time, this.now);
  };

  getMagnitudeClass = (event: EarthquakeEvent): string => {
    if (event.mag < 2) return 'm1';
    if (event.mag < 4) return 'm2';
    if (event.mag < 6) return 'm3';
    if (event.mag < 7) return 'm4';
    return 'm5';
  };

  getDepthClass = (event: EarthquakeEvent): string => {
    if (event.depth < 70) return 'depth-shallow';
    if (event.depth > 300) return 'depth-deep';
    return 'depth-mid';
  };

  depthLabel = (event: EarthquakeEvent): string => {
    return `${Math.round(event.depth)} km deep`;
  };

  isFeedSelected = (option: FeedWindow): boolean => {
    return this.feedWindow === option;
  };

  isSelectedQuake = (event: EarthquakeEvent): boolean => {
    return this.selectedQuakeId === event.id;
  };

  private handleDataUpdate(update: DataUpdate): void {
    if (this.replayMode) return;
    this.events = update.events;

    const newIds = new Set(update.newEvents.map((event) => event.id));
    this.map?.render(update.events, newIds);

    if (!this.didInitialZoom && update.events.length > 0) {
      const latest = update.events[0];
      if (latest) {
        this.selectedQuakeId = latest.id;
        this.map?.zoomToQuake(latest);
        this.didInitialZoom = true;
      }
    }

    for (const event of update.newEvents) {
      this.audio.playFor(event);
      this.notifyIfNeeded(event);
    }
  }

  private handleStatus(status: DataStatus): void {
    this.statusTone = status.tone;
    this.statusMessage = status.message;
    this.lastUpdatedAt = status.lastUpdatedAt;
    this.refreshStaleStatus();
  }

  private refreshStaleStatus(): void {
    if (!this.lastUpdatedAt || this.statusTone === 'error') return;
    const age = this.now - this.lastUpdatedAt;

    if (age > 90_000) {
      this.statusTone = 'stale';
      this.statusMessage = 'Stale';
    } else {
      this.statusTone = 'live';
      this.statusMessage = 'Live';
    }
  }

  private notifyIfNeeded(event: EarthquakeEvent): void {
    if (!('Notification' in window)) return;
    const place = event.place;
    const isCalifornia =
      /\bcalifornia\b/i.test(place) ||
      /,\s*ca(?:\b|,)/i.test(place) ||
      /\bca,\s*usa\b/i.test(place);
    const shouldNotify = event.mag >= 4 || isCalifornia;

    if (!this.pushAlertsEnabled || !shouldNotify) return;
    if (Notification.permission !== 'granted') return;

    const title = `M${event.mag.toFixed(1)} earthquake`;
    const body = `${event.place} · ${Math.round(event.depth)} km deep`;
    if ('serviceWorker' in navigator) {
      void navigator.serviceWorker
        .getRegistration()
        .then((registration) => {
          if (registration) {
            return registration.showNotification(title, { body, tag: `eq-${event.id}` });
          }

          new Notification(title, { body });
        })
        .catch(() => {
          new Notification(title, { body });
        });

      return;
    }

    new Notification(title, { body });
  }

  <template>
    <section class='eqv-app' {{this.setup}}>
      <div class='eqv-content single-row'>
        <div class='eqv-map-wrap full-height'>
          <svg class='eqv-map'></svg>

          <div class='eqv-title'>
            <h1>Earthquake Visualizer</h1>
            <p>Real-time global seismic activity from USGS</p>
          </div>

          <aside class='eqv-panel eqv-panel-left'>
            <div class='eqv-panel-head'>
              <h3>Controls</h3>
              <button
                type='button'
                class='eqv-panel-toggle'
                {{on 'click' this.toggleControlsPanel}}
              >
                <Icon @svg={{if this.controlsExpanded ChevronUp ChevronDown}} @size={{14}} />
              </button>
            </div>

            {{#if this.controlsExpanded}}
              <div class='eqv-panel-body'>
                <div class='eqv-control-grid'>
                  <div class='eqv-switch-row'>
                    <span>Sound</span>
                    <Switch @checked={{this.soundEnabled}} @onCheckedChange={{this.setMuted}} />
                  </div>
                  <div class='eqv-switch-row'>
                    <span>Heatmap</span>
                    <Switch
                      @checked={{this.heatmapMode}}
                      @onCheckedChange={{this.setHeatmapMode}}
                    />
                  </div>
                  <div class='eqv-switch-row'>
                    <span>Tectonic plates</span>
                    <Switch
                      @checked={{this.showTectonicPlates}}
                      @onCheckedChange={{this.setTectonicPlates}}
                    />
                  </div>
                </div>

                <div class='eqv-legend-inline'>
                  <div class='eqv-panel-subhead'>Magnitude Legend</div>
                  <ul>
                    <li><span class='m1'></span> &lt; 2.0</li>
                    <li><span class='m2'></span> 2.0 - 3.9</li>
                    <li><span class='m3'></span> 4.0 - 5.9</li>
                    <li><span class='m4'></span> 6.0 - 6.9</li>
                    <li><span class='m5'></span> 7.0+</li>
                  </ul>
                </div>
              </div>
            {{/if}}
          </aside>

          <aside class='eqv-panel eqv-panel-right'>
            <div class='eqv-panel-head'>
              <h3>Live Feed</h3>
              <button type='button' class='eqv-panel-toggle' {{on 'click' this.toggleFeedPanel}}>
                <Icon @svg={{if this.feedExpanded ChevronUp ChevronDown}} @size={{14}} />
              </button>
            </div>

            {{#if this.feedExpanded}}
              <div class='eqv-panel-body eqv-feed-body'>
                <div class='eqv-control-group'>
                  <label>
                    Feed Window
                    <select {{on 'change' this.setFeedWindow}}>
                      <option value='hour' selected={{this.isFeedSelected 'hour'}}>Past hour</option>
                      <option value='day' selected={{this.isFeedSelected 'day'}}>Past day</option>
                      <option value='week' selected={{this.isFeedSelected 'week'}}>Past week</option>
                    </select>
                  </label>
                  <div class='eqv-feed-controls'>
                    <div class='eqv-switch-row'>
                      <span>Replay mode</span>
                      <Switch
                        @checked={{this.replayMode}}
                        @onCheckedChange={{this.setReplayMode}}
                      />
                    </div>
                    <div class='eqv-switch-row'>
                      <span>Alerts (M4+ or any CA)</span>
                      <Switch
                        @checked={{this.pushAlertsEnabled}}
                        @onCheckedChange={{this.setPushAlertsEnabled}}
                      />
                    </div>
                  </div>
                  <span class='eqv-status {{this.statusTone}}'>{{this.statusLabel}}</span>
                </div>

                <ul>
                  {{#each this.sidebarEvents as |quake|}}
                    <li>
                      <button
                        type='button'
                        class='eqv-feed-item {{if (this.isSelectedQuake quake) "active"}}'
                        {{on 'click' (fn this.zoomToSidebar quake)}}
                      >
                        <span class='badge {{this.getMagnitudeClass quake}}'>
                          M{{quake.mag}}
                        </span>
                        <span class='place'>{{quake.place}}</span>
                        <span class='time'>{{this.formatRelativeTime quake}}</span>
                      </button>
                    </li>
                  {{/each}}
                </ul>
              </div>
            {{/if}}
          </aside>

          {{#if this.zoomedIn}}
            <button class='eqv-reset' type='button' {{on 'click' this.resetZoom}}>Reset zoom</button>
          {{/if}}
        </div>
      </div>

      {{#if this.tooltip}}
        <div class='eqv-tooltip' style={{this.tooltipStyle}}>
          <p class='mag {{this.getMagnitudeClass this.tooltip.quake}}'>
            M{{this.tooltip.quake.mag}}
          </p>
          <p>{{this.tooltip.quake.place}}</p>
          <p class='{{this.getDepthClass this.tooltip.quake}}'>
            {{this.depthLabel this.tooltip.quake}}
          </p>
          <p>{{this.formatRelativeTime this.tooltip.quake}}</p>
        </div>
      {{/if}}
    </section>
  </template>
}
