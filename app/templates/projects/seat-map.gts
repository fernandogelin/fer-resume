import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import { t } from 'ember-intl';
import Icon from 'fer-resume/components/icon';
import SeatMapScene from 'fer-resume/components/seat-map/scene';
import CpuDemo from 'fer-resume/components/seat-map/cpu-demo';
import { runSeatRenderingBenchmark } from 'fer-resume/lib/seat-benchmark';
import type { SeatLayoutType } from 'fer-resume/components/seat-map/scene';
import { ChevronDown, ChevronUp, Trash2, Armchair } from 'lucide-static';

interface Preset {
  tKey: string;
  rows: number;
  seatsPerRow: number;
}

interface LayoutOption {
  value: SeatLayoutType;
  label: string;
}

const PRESETS: Preset[] = [
  { tKey: 'seatMap.fitness', rows: 8, seatsPerRow: 12 },
  { tKey: 'seatMap.theater', rows: 25, seatsPerRow: 30 },
  { tKey: 'seatMap.concert', rows: 80, seatsPerRow: 120 },
  { tKey: 'seatMap.stadium', rows: 200, seatsPerRow: 500 },
];

const LAYOUT_OPTIONS: LayoutOption[] = [
  { value: 'square', label: 'Square' },
  { value: 'rectangle', label: 'Rectangle' },
  { value: 'arch', label: 'Arch' },
  { value: 'stadium-center', label: 'Stadium (Center Stage)' },
  { value: 'stadium-side', label: 'Stadium (Side Stage)' },
  { value: 'custom-draw', label: 'Custom Draw (Fixed Stage)' },
];

class SeatMapPage extends Component {
  readonly presets = PRESETS;
  readonly layoutOptions = LAYOUT_OPTIONS;

  @tracked rows = 8;
  @tracked seatsPerRow = 12;
  @tracked layout: SeatLayoutType = 'arch';
  @tracked selectedCount = 0;
  @tracked isPanelExpanded = true;
  @tracked resetKey = 0;
  @tracked benchmarkState: 'idle' | 'running' | 'done' | 'error' = 'idle';
  @tracked benchmarkResult: {
    seatCount: number;
    frames: number;
    gpuMsPerFrame: number;
    cpuMsPerFrame: number;
    gpuFps: number;
    cpuFps: number;
    speedup: number;
  } | null = null;
  @tracked benchmarkError: string | null = null;

  get totalSeats(): number {
    return this.rows * this.seatsPerRow;
  }

  get hasSelection(): boolean {
    return this.selectedCount > 0;
  }

  get isCustomDraw(): boolean {
    return this.layout === 'custom-draw';
  }

  get totalSeatsLabel(): string {
    return this.totalSeats.toLocaleString();
  }

  get isBenchmarkRunning(): boolean {
    return this.benchmarkState === 'running';
  }

  get benchmarkButtonLabel(): string {
    return this.isBenchmarkRunning ? 'Running benchmark…' : 'Run GPU vs CPU benchmark';
  }

  get benchmarkGpuBarWidth(): string {
    if (!this.benchmarkResult) return '0%';
    const max = Math.max(
      this.benchmarkResult.gpuMsPerFrame,
      this.benchmarkResult.cpuMsPerFrame,
      0.001,
    );
    const width = (this.benchmarkResult.gpuMsPerFrame / max) * 100;
    return `${Math.max(8, Math.min(100, width)).toFixed(1)}%`;
  }

  get benchmarkCpuBarWidth(): string {
    if (!this.benchmarkResult) return '0%';
    const max = Math.max(
      this.benchmarkResult.gpuMsPerFrame,
      this.benchmarkResult.cpuMsPerFrame,
      0.001,
    );
    const width = (this.benchmarkResult.cpuMsPerFrame / max) * 100;
    return `${Math.max(8, Math.min(100, width)).toFixed(1)}%`;
  }

  get benchmarkGpuBarStyle(): string {
    return `width:${this.benchmarkGpuBarWidth};`;
  }

  get benchmarkCpuBarStyle(): string {
    return `width:${this.benchmarkCpuBarWidth};`;
  }

  @action
  applyPreset(preset: Preset): void {
    this.rows = preset.rows;
    this.seatsPerRow = preset.seatsPerRow;
    if (this.layout === 'custom-draw') this.layout = 'arch';
    this.selectedCount = 0;
    this.resetKey++;
  }

  @action
  setLayout(layout: SeatLayoutType): void {
    if (layout === this.layout) return;
    this.layout = layout;
    this.selectedCount = 0;
    this.resetKey++;
  }

  @action
  updateRows(event: Event): void {
    const val = parseInt((event.target as HTMLInputElement).value, 10);
    if (isNaN(val) || val === this.rows) return;
    this.rows = val;
    this.selectedCount = 0;
    this.resetKey++;
  }

  @action
  updateSeatsPerRow(event: Event): void {
    const val = parseInt((event.target as HTMLInputElement).value, 10);
    if (isNaN(val) || val === this.seatsPerRow) return;
    this.seatsPerRow = val;
    this.selectedCount = 0;
    this.resetKey++;
  }

  @action
  onSelectionChange(selected: number[]): void {
    this.selectedCount = selected.length;
  }

  @action
  clearSelection(): void {
    this.selectedCount = 0;
    this.resetKey++;
  }

  @action
  togglePanel(): void {
    this.isPanelExpanded = !this.isPanelExpanded;
  }

  @action
  async runBenchmark(): Promise<void> {
    this.benchmarkState = 'running';
    this.benchmarkError = null;
    this.benchmarkResult = null;
    try {
      this.benchmarkResult = await runSeatRenderingBenchmark({
        rows: this.rows,
        seatsPerRow: this.seatsPerRow,
        layout: this.layout,
      });
      this.benchmarkState = 'done';
    } catch (error) {
      this.benchmarkState = 'error';
      this.benchmarkError = error instanceof Error ? error.message : 'Benchmark failed';
    }
  }

  <template>
    <div class='relative' style='height: calc(100vh - 49px); overflow: hidden;'>

      {{! WebGL canvas }}
      <main class='absolute inset-0 min-w-0'>
        <SeatMapScene
          class='absolute inset-0'
          @rows={{this.rows}}
          @seatsPerRow={{this.seatsPerRow}}
          @layout={{this.layout}}
          @resetKey={{this.resetKey}}
          @onSelectionChange={{this.onSelectionChange}}
        />
      </main>

      {{! Floating control panel }}
      <aside
        class='absolute left-4 top-4 z-20 w-70 rounded-md border border-border bg-card/95 backdrop-blur-sm flex flex-col overflow-hidden'
        style={{if this.isPanelExpanded 'max-height: calc(100vh - 81px);'}}
      >
        <div class='h-11 px-4 border-b border-border flex items-center justify-between'>
          <h3 class='text-xs font-semibold uppercase tracking-wider text-muted-foreground'>
            {{t 'seatMap.presets'}}
          </h3>
          <button
            type='button'
            class='h-7 w-7 rounded-md hover:bg-accent flex items-center justify-center transition-colors'
            {{on 'click' this.togglePanel}}
            aria-label={{if this.isPanelExpanded 'Collapse panel' 'Expand panel'}}
          >
            <Icon
              @svg={{if this.isPanelExpanded ChevronUp ChevronDown}}
              @size={{14}}
              @class='text-muted-foreground'
            />
          </button>
        </div>

        {{#if this.isPanelExpanded}}
          <div class='p-4 space-y-5 flex-1 overflow-y-auto'>
            {{! Layout presets }}
            <section>
              <div class='space-y-1'>
                {{#each this.presets as |preset|}}
                  <button
                    type='button'
                    class='w-full text-left px-3 py-2 rounded-md text-sm transition-colors hover:bg-accent hover:text-accent-foreground flex items-center justify-between group'
                    {{on 'click' (fn this.applyPreset preset)}}
                  >
                    <span>{{t preset.tKey}}</span>
                    <span
                      class='text-xs text-muted-foreground group-hover:text-accent-foreground tabular-nums'
                    >
                      {{preset.rows}}×{{preset.seatsPerRow}}
                    </span>
                  </button>
                {{/each}}
              </div>
            </section>

            <div class='border-t border-border'></div>

            {{! Custom row + seat sliders }}
            <section class='space-y-4'>
              <div>
                <div class='flex items-center justify-between mb-1'>
                  <label class='text-sm font-medium'>Layout</label>
                </div>
                <div class='space-y-1'>
                  {{#each this.layoutOptions as |option|}}
                    <button
                      type='button'
                      class='w-full text-left px-3 py-2 rounded-md text-sm transition-colors hover:bg-accent hover:text-accent-foreground'
                      {{on 'click' (fn this.setLayout option.value)}}
                    >
                      {{option.label}}
                    </button>
                  {{/each}}
                </div>
              </div>

              <div>
                <div class='flex items-center justify-between mb-1'>
                  <label class='text-sm font-medium'>{{t 'seatMap.rows'}}</label>
                  <span class='text-sm text-muted-foreground tabular-nums'>{{this.rows}}</span>
                </div>
                <input
                  type='range'
                  min='1'
                  max='300'
                  value={{this.rows}}
                  class='w-full accent-primary'
                  {{on 'input' this.updateRows}}
                />
              </div>
              <div>
                <div class='flex items-center justify-between mb-1'>
                  <label class='text-sm font-medium'>{{t 'seatMap.seats'}}</label>
                  <span
                    class='text-sm text-muted-foreground tabular-nums'
                  >{{this.seatsPerRow}}</span>
                </div>
                <input
                  type='range'
                  min='1'
                  max='600'
                  value={{this.seatsPerRow}}
                  class='w-full accent-primary'
                  {{on 'input' this.updateSeatsPerRow}}
                />
              </div>

              {{#if this.isCustomDraw}}
                <p class='text-xs text-muted-foreground leading-relaxed'>
                  Click to add boundary points around the fixed center stage. Double-click or click
                  near the first point to close and generate seats.
                </p>
              {{/if}}
            </section>

            <div class='border-t border-border'></div>

            {{! Stats + clear }}
            <section class='space-y-2'>
              <div class='flex items-center gap-2 text-sm text-muted-foreground'>
                <Icon @svg={{Armchair}} @size={{14}} />
                <span>{{t 'seatMap.totalSeats' count=this.totalSeatsLabel}}</span>
              </div>
              <div class='flex items-center justify-between'>
                <span class='text-sm font-medium text-primary'>
                  {{t 'seatMap.selected' count=this.selectedCount}}
                </span>
                {{#if this.hasSelection}}
                  <button
                    type='button'
                    class='inline-flex items-center gap-1 text-xs text-muted-foreground hover:text-destructive transition-colors'
                    {{on 'click' this.clearSelection}}
                  >
                    <Icon @svg={{Trash2}} @size={{12}} />
                    {{t 'seatMap.clear'}}
                  </button>
                {{/if}}
              </div>
            </section>

            <div class='border-t border-border'></div>

            {{! Technical write-up + benchmark }}
            <section class='space-y-3'>
              <h4 class='text-xs font-semibold uppercase tracking-wider text-muted-foreground'>
                Technical Notes
              </h4>
              <p class='text-xs text-muted-foreground leading-relaxed'>
                GPU rendering uses a single instanced draw for outlines and batched seat updates,
                which keeps work on the graphics pipeline and reduces CPU layout/paint overhead. A
                CPU canvas renderer redraws seats in JavaScript each frame, which scales worse as
                seat counts grow.
              </p>

              <div class='space-y-2'>
                <p class='text-xs font-medium'>Non-GPU demo (2D canvas)</p>
                <div class='h-28 rounded-md border border-border overflow-hidden bg-background'>
                  <CpuDemo
                    @rows={{this.rows}}
                    @seatsPerRow={{this.seatsPerRow}}
                    @layout={{this.layout}}
                  />
                </div>
              </div>

              <div class='space-y-2'>
                <button
                  type='button'
                  class='w-full h-8 rounded-md border border-border text-sm hover:bg-accent transition-colors disabled:opacity-60'
                  {{on 'click' this.runBenchmark}}
                  disabled={{this.isBenchmarkRunning}}
                >
                  {{this.benchmarkButtonLabel}}
                </button>

                {{#if this.benchmarkResult}}
                  <div
                    class='rounded-md border border-border p-2 text-xs text-muted-foreground space-y-1'
                  >
                    <div class='flex justify-between'>
                      <span>Seats</span>
                      <span class='tabular-nums'>{{this.benchmarkResult.seatCount}}</span>
                    </div>
                    <div class='flex justify-between'>
                      <span>GPU</span>
                      <span class='tabular-nums'>
                        {{this.benchmarkResult.gpuMsPerFrame}}
                        ms/frame (~{{this.benchmarkResult.gpuFps}}
                        fps)
                      </span>
                    </div>
                    <div class='flex justify-between'>
                      <span>CPU</span>
                      <span class='tabular-nums'>
                        {{this.benchmarkResult.cpuMsPerFrame}}
                        ms/frame (~{{this.benchmarkResult.cpuFps}}
                        fps)
                      </span>
                    </div>
                    <div class='flex justify-between text-primary font-medium'>
                      <span>Speedup</span>
                      <span class='tabular-nums'>{{this.benchmarkResult.speedup}}×</span>
                    </div>

                    <div class='pt-1 space-y-1.5'>
                      <div class='space-y-0.5'>
                        <div class='flex justify-between'>
                          <span>GPU</span>
                          <span class='tabular-nums'>{{this.benchmarkResult.gpuMsPerFrame}}
                            ms</span>
                        </div>
                        <div class='h-2 rounded bg-muted overflow-hidden'>
                          <div
                            class='h-full bg-primary rounded'
                            style={{this.benchmarkGpuBarStyle}}
                          ></div>
                        </div>
                      </div>
                      <div class='space-y-0.5'>
                        <div class='flex justify-between'>
                          <span>CPU</span>
                          <span class='tabular-nums'>{{this.benchmarkResult.cpuMsPerFrame}}
                            ms</span>
                        </div>
                        <div class='h-2 rounded bg-muted overflow-hidden'>
                          <div
                            class='h-full bg-slate-400 rounded'
                            style={{this.benchmarkCpuBarStyle}}
                          ></div>
                        </div>
                      </div>
                    </div>
                  </div>
                {{/if}}

                {{#if this.benchmarkError}}
                  <p class='text-xs text-destructive'>{{this.benchmarkError}}</p>
                {{/if}}
              </div>
            </section>
          </div>

          {{! Color legend }}
          <div class='p-4 border-t border-border space-y-1.5'>
            <div class='flex items-center gap-2 text-xs text-muted-foreground'>
              <span class='w-3 h-3 rounded-sm bg-slate-400 inline-block shrink-0'></span>
              <span>Available</span>
            </div>
            <div class='flex items-center gap-2 text-xs text-muted-foreground'>
              <span class='w-3 h-3 rounded-sm bg-primary inline-block shrink-0'></span>
              <span>Selected</span>
            </div>
          </div>
        {{else}}
          <div class='p-3 space-y-2'>
            <div class='flex items-center gap-2 text-xs text-muted-foreground'>
              <Icon @svg={{Armchair}} @size={{12}} />
              <span>{{t 'seatMap.totalSeats' count=this.totalSeatsLabel}}</span>
            </div>
            <div class='text-xs font-medium text-primary'>
              {{t 'seatMap.selected' count=this.selectedCount}}
            </div>
            <div class='pt-2 border-t border-border space-y-1.5'>
              <div class='flex items-center gap-2 text-xs text-muted-foreground'>
                <span class='w-3 h-3 rounded-sm bg-slate-400 inline-block shrink-0'></span>
                <span>Available</span>
              </div>
              <div class='flex items-center gap-2 text-xs text-muted-foreground'>
                <span class='w-3 h-3 rounded-sm bg-primary inline-block shrink-0'></span>
                <span>Selected</span>
              </div>
            </div>
          </div>
        {{/if}}
      </aside>

    </div>
  </template>
}

export default SeatMapPage;
