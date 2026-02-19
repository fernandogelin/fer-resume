import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import { LinkTo } from '@ember/routing';
import { t } from 'ember-intl';
import Icon from 'fer-resume/components/icon';
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

interface SeatMapSidebarSignature {
  Args: {
    isPanelExpanded: boolean;
    presets: Preset[];
    layoutOptions: LayoutOption[];
    rows: number;
    seatsPerRow: number;
    layout: SeatLayoutType;
    isCustomDraw: boolean;
    totalSeatsLabel: string;
    selectedCount: number;
    hasSelection: boolean;
    onTogglePanel: () => void;
    onApplyPreset: (preset: Preset) => void;
    onSetLayout: (layout: SeatLayoutType) => void;
    onUpdateRows: (event: Event) => void;
    onUpdateSeatsPerRow: (event: Event) => void;
    onClearSelection: () => void;
  };
}

export default class SeatMapSidebar extends Component<SeatMapSidebarSignature> {
  get isExpanded(): boolean {
    return this.args.isPanelExpanded;
  }

  <template>
    <aside
      class='absolute left-4 top-4 z-20 w-64 rounded-md border border-border bg-card/95 backdrop-blur-sm flex flex-col overflow-hidden max-h-[90vh]'
    >
      <div class='h-11 p-4 border-b border-border flex items-center justify-between'>
        <h3 class='text-xs font-semibold uppercase tracking-wider text-muted-foreground'>
          {{t 'seatMap.presets'}}
        </h3>
        <button
          type='button'
          class='h-7 w-7 rounded-md hover:bg-accent flex items-center justify-center transition-colors'
          {{on 'click' @onTogglePanel}}
          aria-label={{if this.isExpanded 'Collapse panel' 'Expand panel'}}
        >
          <Icon
            @svg={{if this.isExpanded ChevronUp ChevronDown}}
            @size={{14}}
            @class='text-muted-foreground'
          />
        </button>
      </div>

      {{#if this.isExpanded}}
        <div class='p-4 space-y-5 flex-1 overflow-y-auto'>
          <section>
            <div class='space-y-1'>
              {{#each @presets as |preset|}}
                <button
                  type='button'
                  class='w-full text-left px-3 py-2 rounded-md text-sm transition-colors hover:bg-accent hover:text-accent-foreground flex items-center justify-between group'
                  {{on 'click' (fn @onApplyPreset preset)}}
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

          <section class='space-y-4'>
            <div>
              <div class='flex items-center justify-between mb-1'>
                <label class='text-sm font-medium'>Layout</label>
              </div>
              <div class='space-y-1'>
                {{#each @layoutOptions as |option|}}
                  <button
                    type='button'
                    class='w-full text-left px-3 py-2 rounded-md text-sm transition-colors hover:bg-accent hover:text-accent-foreground'
                    {{on 'click' (fn @onSetLayout option.value)}}
                  >
                    {{option.label}}
                  </button>
                {{/each}}
              </div>
            </div>

            <div>
              <div class='flex items-center justify-between mb-1'>
                <label class='text-sm font-medium'>{{t 'seatMap.rows'}}</label>
                <span class='text-sm text-muted-foreground tabular-nums'>{{@rows}}</span>
              </div>
              <input
                type='range'
                min='1'
                max='300'
                value={{@rows}}
                class='w-full accent-primary'
                {{on 'input' @onUpdateRows}}
              />
            </div>
            <div>
              <div class='flex items-center justify-between mb-1'>
                <label class='text-sm font-medium'>{{t 'seatMap.seats'}}</label>
                <span class='text-sm text-muted-foreground tabular-nums'>{{@seatsPerRow}}</span>
              </div>
              <input
                type='range'
                min='1'
                max='600'
                value={{@seatsPerRow}}
                class='w-full accent-primary'
                {{on 'input' @onUpdateSeatsPerRow}}
              />
            </div>

            {{#if @isCustomDraw}}
              <p class='text-xs text-muted-foreground leading-relaxed'>
                Click to add boundary points around the fixed center stage. Double-click or click
                near the first point to close and generate seats.
              </p>
            {{/if}}
          </section>

          <div class='border-t border-border'></div>

          <section class='space-y-2'>
            <div class='flex items-center gap-2 text-sm text-muted-foreground'>
              <Icon @svg={{Armchair}} @size={{14}} />
              <span>{{t 'seatMap.totalSeats' count=@totalSeatsLabel}}</span>
            </div>
            <div class='flex items-center justify-between'>
              <span class='text-sm font-medium text-primary'>
                {{t 'seatMap.selected' count=@selectedCount}}
              </span>
              {{#if @hasSelection}}
                <button
                  type='button'
                  class='inline-flex items-center gap-1 text-xs text-muted-foreground hover:text-destructive transition-colors'
                  {{on 'click' @onClearSelection}}
                >
                  <Icon @svg={{Trash2}} @size={{12}} />
                  {{t 'seatMap.clear'}}
                </button>
              {{/if}}
            </div>
          </section>

          <div class='border-t border-border'></div>

          <section>
            <LinkTo
              @route='projects.seat-map-benchmark'
              class='w-full inline-flex items-center justify-center h-8 rounded-md border border-border text-sm hover:bg-accent hover:text-accent-foreground transition-colors'
            >
              Open Benchmark Lab
            </LinkTo>
          </section>
        </div>

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
            <span>{{t 'seatMap.totalSeats' count=@totalSeatsLabel}}</span>
          </div>
          <div class='text-xs font-medium text-primary'>
            {{t 'seatMap.selected' count=@selectedCount}}
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
  </template>
}
