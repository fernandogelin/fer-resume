import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import { t } from 'ember-intl';
import Icon from 'fer-resume/components/icon';
import SeatMapScene from 'fer-resume/components/seat-map/scene';
import type { SeatLayoutType } from 'fer-resume/components/seat-map/scene';
import { ChevronLeft, ChevronRight, Trash2, Armchair } from 'lucide-static';

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
  @tracked isPanelOpen = true;
  @tracked resetKey = 0;

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
    this.isPanelOpen = !this.isPanelOpen;
  }

  <template>
    <div class='flex' style='height: calc(100vh - 49px); overflow: hidden;'>

      {{! Collapsible control panel }}
      {{#if this.isPanelOpen}}
        <aside class='w-70 shrink-0 border-r border-border bg-card overflow-y-auto flex flex-col'>
          <div class='p-4 space-y-5 flex-1'>

            {{! Layout presets }}
            <section>
              <h3 class='text-xs font-semibold uppercase tracking-wider text-muted-foreground mb-2'>
                {{t 'seatMap.presets'}}
              </h3>
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
        </aside>
      {{/if}}

      {{! Panel collapse toggle }}
      <button
        type='button'
        class='shrink-0 w-6 bg-muted/40 hover:bg-muted border-r border-border flex items-center justify-center transition-colors'
        {{on 'click' this.togglePanel}}
        aria-label={{if this.isPanelOpen 'Collapse panel' 'Expand panel'}}
      >
        <Icon
          @svg={{if this.isPanelOpen ChevronLeft ChevronRight}}
          @size={{14}}
          @class='text-muted-foreground'
        />
      </button>

      {{! WebGL canvas }}
      <main class='flex-1 min-w-0 relative'>
        <SeatMapScene
          class='absolute inset-0'
          @rows={{this.rows}}
          @seatsPerRow={{this.seatsPerRow}}
          @layout={{this.layout}}
          @resetKey={{this.resetKey}}
          @onSelectionChange={{this.onSelectionChange}}
        />
      </main>

    </div>
  </template>
}

export default SeatMapPage;
