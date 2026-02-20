import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import CpuDemo from 'fer-resume/components/seat-map/cpu-demo';
import type { SeatLayoutType } from 'fer-resume/components/seat-map/scene';
import { t } from 'ember-intl';

interface BenchmarkResult {
  seatCount: number;
  frames: number;
  gpuMsPerFrame: number;
  cpuMsPerFrame: number;
  gpuFps: number;
  cpuFps: number;
  speedup: number;
}

interface BenchmarkSectionSignature {
  Args: {
    rows: number;
    seatsPerRow: number;
    layout: SeatLayoutType;
    isBenchmarkRunning: boolean;
    benchmarkResult: BenchmarkResult | null;
    benchmarkError?: string | null;
    benchmarkGpuBarStyle: string;
    benchmarkCpuBarStyle: string;
    onRunBenchmark: () => void;
  };
}

export default class BenchmarkSection extends Component<BenchmarkSectionSignature> {
  get hasBenchmarkResult(): boolean {
    return this.args.benchmarkResult !== null;
  }

  <template>
    <section class='space-y-3'>
      <h4 class='text-xs font-semibold uppercase tracking-wider text-muted-foreground'>
        {{t 'seatMap.benchmark.technicalNotes'}}
      </h4>
      <p class='text-xs text-muted-foreground leading-relaxed'>
        {{t 'seatMap.benchmark.notesBody'}}
      </p>

      <div class='space-y-2'>
        <p class='text-xs font-medium'>{{t 'seatMap.benchmark.nonGpuDemo'}}</p>
        <div class='h-28 rounded-md border border-border overflow-hidden bg-background'>
          <CpuDemo @rows={{@rows}} @seatsPerRow={{@seatsPerRow}} @layout={{@layout}} />
        </div>
      </div>

      <div class='space-y-2'>
        <button
          type='button'
          class='w-full h-8 rounded-md border border-border text-sm hover:bg-accent hover:text-accent-foreground transition-colors disabled:opacity-60'
          {{on 'click' @onRunBenchmark}}
          disabled={{@isBenchmarkRunning}}
        >
          {{if @isBenchmarkRunning (t 'seatMap.benchmark.running') (t 'seatMap.benchmark.run')}}
        </button>

        {{#if this.hasBenchmarkResult}}
          <div class='rounded-md border border-border p-2 text-xs text-muted-foreground space-y-1'>
            <div class='flex justify-between'>
              <span>{{t 'seatMap.benchmark.seats'}}</span>
              <span class='tabular-nums'>{{@benchmarkResult.seatCount}}</span>
            </div>
            <div class='flex justify-between'>
              <span>{{t 'seatMap.benchmark.gpu'}}</span>
              <span class='tabular-nums'>
                {{@benchmarkResult.gpuMsPerFrame}}
                {{t 'seatMap.benchmark.msPerFrame' fps=@benchmarkResult.gpuFps}}
              </span>
            </div>
            <div class='flex justify-between'>
              <span>{{t 'seatMap.benchmark.cpu'}}</span>
              <span class='tabular-nums'>
                {{@benchmarkResult.cpuMsPerFrame}}
                {{t 'seatMap.benchmark.msPerFrame' fps=@benchmarkResult.cpuFps}}
              </span>
            </div>
            <div class='flex justify-between text-primary font-medium'>
              <span>{{t 'seatMap.benchmark.speedup'}}</span>
              <span class='tabular-nums'>{{@benchmarkResult.speedup}}×</span>
            </div>

            <div class='pt-1 space-y-1.5'>
              <div class='space-y-0.5'>
                <div class='flex justify-between'>
                  <span>{{t 'seatMap.benchmark.gpu'}}</span>
                  <span class='tabular-nums'>{{@benchmarkResult.gpuMsPerFrame}}
                    ms</span>
                </div>
                <div class='h-2 rounded bg-muted overflow-hidden'>
                  <div class='h-full bg-primary rounded' style={{@benchmarkGpuBarStyle}}></div>
                </div>
              </div>
              <div class='space-y-0.5'>
                <div class='flex justify-between'>
                  <span>{{t 'seatMap.benchmark.cpu'}}</span>
                  <span class='tabular-nums'>{{@benchmarkResult.cpuMsPerFrame}}
                    ms</span>
                </div>
                <div class='h-2 rounded bg-muted overflow-hidden'>
                  <div class='h-full bg-slate-400 rounded' style={{@benchmarkCpuBarStyle}}></div>
                </div>
              </div>
            </div>
          </div>
        {{/if}}

        {{#if @benchmarkError}}
          <p class='text-xs text-destructive'>{{@benchmarkError}}</p>
        {{/if}}
      </div>
    </section>
  </template>
}
