import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { LinkTo } from '@ember/routing';
import BenchmarkSection from 'fer-resume/components/seat-map/benchmark-section';
import { Card, CardHeader, CardTitle, CardContent } from 'fer-resume/components/ui/card';
import type { SeatLayoutType } from 'fer-resume/components/seat-map/scene';
import { runSeatRenderingBenchmark } from 'fer-resume/lib/seat-benchmark';
import { t } from 'ember-intl';

class SeatMapBenchmarkPage extends Component {
  readonly layout: SeatLayoutType = 'arch';

  @tracked rows = 25;
  @tracked seatsPerRow = 40;

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

  get isBenchmarkRunning(): boolean {
    return this.benchmarkState === 'running';
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
  updateRows(event: Event): void {
    const val = parseInt((event.target as HTMLInputElement).value, 10);
    if (isNaN(val)) return;
    this.rows = val;
  }

  @action
  updateSeatsPerRow(event: Event): void {
    const val = parseInt((event.target as HTMLInputElement).value, 10);
    if (isNaN(val)) return;
    this.seatsPerRow = val;
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
      this.benchmarkError = error instanceof Error ? error.message : 'seatMap.benchmark.failed';
    }
  }

  <template>
    <div class='w-screen flex justify-center py-10 px-4'>
      <Card @class='w-180'>
        <CardHeader @class='border-b border-border pb-4'>
          <div class='flex items-center justify-between gap-3'>
            <CardTitle @class='text-lg'>{{t 'seatMap.benchmark.title'}}</CardTitle>
            <LinkTo
              @route='projects.seat-map'
              class='inline-flex items-center h-8 px-3 rounded-md border border-border text-sm hover:bg-accent hover:text-accent-foreground transition-colors'
            >
              {{t 'seatMap.benchmark.backToSeatMap'}}
            </LinkTo>
          </div>
        </CardHeader>

        <CardContent @class='pt-4 space-y-4'>
          <div class='grid grid-cols-1 sm:grid-cols-3 gap-3'>
            <label class='text-sm space-y-1'>
              <span class='text-muted-foreground'>{{t 'seatMap.rows'}}</span>
              <input
                type='range'
                min='1'
                max='300'
                value={{this.rows}}
                class='w-full accent-primary'
                {{on 'input' this.updateRows}}
              />
              <div class='text-xs tabular-nums'>{{this.rows}}</div>
            </label>

            <label class='text-sm space-y-1'>
              <span class='text-muted-foreground'>{{t 'seatMap.benchmark.seatsPerRowShort'}}</span>
              <input
                type='range'
                min='1'
                max='600'
                value={{this.seatsPerRow}}
                class='w-full accent-primary'
                {{on 'input' this.updateSeatsPerRow}}
              />
              <div class='text-xs tabular-nums'>{{this.seatsPerRow}}</div>
            </label>

            <div class='text-sm space-y-1'>
              <span class='text-muted-foreground'>{{t 'seatMap.layout'}}</span>
              <div
                class='h-8 px-2 rounded-md border border-border text-xs flex items-center bg-muted/40'
              >
                {{t 'seatMap.layoutArch'}}
              </div>
            </div>
          </div>

          <BenchmarkSection
            @rows={{this.rows}}
            @seatsPerRow={{this.seatsPerRow}}
            @layout={{this.layout}}
            @isBenchmarkRunning={{this.isBenchmarkRunning}}
            @benchmarkResult={{this.benchmarkResult}}
            @benchmarkError={{if this.benchmarkError (t this.benchmarkError)}}
            @benchmarkGpuBarStyle={{this.benchmarkGpuBarStyle}}
            @benchmarkCpuBarStyle={{this.benchmarkCpuBarStyle}}
            @onRunBenchmark={{this.runBenchmark}}
          />
        </CardContent>
      </Card>
    </div>
  </template>
}

export default SeatMapBenchmarkPage;
