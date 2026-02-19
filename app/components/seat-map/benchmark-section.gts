import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import CpuDemo from 'fer-resume/components/seat-map/cpu-demo';
import type { SeatLayoutType } from 'fer-resume/components/seat-map/scene';

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
    benchmarkButtonLabel: string;
    benchmarkResult: BenchmarkResult | null;
    benchmarkError: string | null;
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
        Technical Notes
      </h4>
      <p class='text-xs text-muted-foreground leading-relaxed'>
        GPU rendering uses a single instanced draw for outlines and batched seat updates, which
        keeps work on the graphics pipeline and reduces CPU layout/paint overhead. A CPU canvas
        renderer redraws seats in JavaScript each frame, which scales worse as seat counts grow.
      </p>

      <div class='space-y-2'>
        <p class='text-xs font-medium'>Non-GPU demo (2D canvas)</p>
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
          {{@benchmarkButtonLabel}}
        </button>

        {{#if this.hasBenchmarkResult}}
          <div class='rounded-md border border-border p-2 text-xs text-muted-foreground space-y-1'>
            <div class='flex justify-between'>
              <span>Seats</span>
              <span class='tabular-nums'>{{@benchmarkResult.seatCount}}</span>
            </div>
            <div class='flex justify-between'>
              <span>GPU</span>
              <span class='tabular-nums'>
                {{@benchmarkResult.gpuMsPerFrame}}
                ms/frame (~{{@benchmarkResult.gpuFps}}
                fps)
              </span>
            </div>
            <div class='flex justify-between'>
              <span>CPU</span>
              <span class='tabular-nums'>
                {{@benchmarkResult.cpuMsPerFrame}}
                ms/frame (~{{@benchmarkResult.cpuFps}}
                fps)
              </span>
            </div>
            <div class='flex justify-between text-primary font-medium'>
              <span>Speedup</span>
              <span class='tabular-nums'>{{@benchmarkResult.speedup}}×</span>
            </div>

            <div class='pt-1 space-y-1.5'>
              <div class='space-y-0.5'>
                <div class='flex justify-between'>
                  <span>GPU</span>
                  <span class='tabular-nums'>{{@benchmarkResult.gpuMsPerFrame}}
                    ms</span>
                </div>
                <div class='h-2 rounded bg-muted overflow-hidden'>
                  <div class='h-full bg-primary rounded' style={{@benchmarkGpuBarStyle}}></div>
                </div>
              </div>
              <div class='space-y-0.5'>
                <div class='flex justify-between'>
                  <span>CPU</span>
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
