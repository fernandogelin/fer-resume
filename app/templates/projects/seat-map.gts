import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import SeatMapScene from 'fer-resume/components/seat-map/scene';
import SeatMapSidebar from 'fer-resume/components/seat-map/sidebar';
import type { SeatLayoutType } from 'fer-resume/components/seat-map/scene';

interface Preset {
  tKey: string;
  rows: number;
  seatsPerRow: number;
}

interface LayoutOption {
  value: SeatLayoutType;
  tKey: string;
}

const PRESETS: Preset[] = [
  { tKey: 'seatMap.fitness', rows: 8, seatsPerRow: 12 },
  { tKey: 'seatMap.theater', rows: 25, seatsPerRow: 30 },
  { tKey: 'seatMap.concert', rows: 80, seatsPerRow: 120 },
  { tKey: 'seatMap.stadium', rows: 200, seatsPerRow: 500 },
];

const LAYOUT_OPTIONS: LayoutOption[] = [
  { value: 'square', tKey: 'seatMap.layoutSquare' },
  { value: 'rectangle', tKey: 'seatMap.layoutRectangle' },
  { value: 'arch', tKey: 'seatMap.layoutArch' },
  { value: 'stadium-center', tKey: 'seatMap.layoutStadiumCenter' },
  { value: 'stadium-side', tKey: 'seatMap.layoutStadiumSide' },
  { value: 'custom-draw', tKey: 'seatMap.layoutCustomDraw' },
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
    this.isPanelExpanded = !this.isPanelExpanded;
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

      <SeatMapSidebar
        @isPanelExpanded={{this.isPanelExpanded}}
        @presets={{this.presets}}
        @layoutOptions={{this.layoutOptions}}
        @rows={{this.rows}}
        @seatsPerRow={{this.seatsPerRow}}
        @layout={{this.layout}}
        @isCustomDraw={{this.isCustomDraw}}
        @totalSeatsLabel={{this.totalSeatsLabel}}
        @selectedCount={{this.selectedCount}}
        @hasSelection={{this.hasSelection}}
        @onTogglePanel={{this.togglePanel}}
        @onApplyPreset={{this.applyPreset}}
        @onSetLayout={{this.setLayout}}
        @onUpdateRows={{this.updateRows}}
        @onUpdateSeatsPerRow={{this.updateSeatsPerRow}}
        @onClearSelection={{this.clearSelection}}
      />

    </div>
  </template>
}

export default SeatMapPage;
