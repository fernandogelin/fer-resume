import Component from '@glimmer/component';
import { modifier } from 'ember-modifier';
import type { SeatLayoutType } from './scene';

interface CpuDemoSignature {
  Element: HTMLCanvasElement;
  Args: {
    rows: number;
    seatsPerRow: number;
    layout: SeatLayoutType;
  };
}

type SeatTransform = { x: number; y: number; rotation: number };

const SEAT_W = 10;
const SEAT_H = 9;
const SEAT_GAP = 2;
const ROW_GAP = 2.5;
const BASE_RADIUS = 80;

export default class CpuDemo extends Component<CpuDemoSignature> {
  setup = modifier((canvas: HTMLCanvasElement): (() => void) => {
    const ctx = canvas.getContext('2d');
    if (!ctx) return () => {};

    let frameId: number | null = null;
    let tickCount = 0;

    const draw = (): void => {
      const dpr = Math.min(globalThis.devicePixelRatio ?? 1, 2);
      const cssWidth = canvas.clientWidth || 280;
      const cssHeight = canvas.clientHeight || 112;
      const width = Math.floor(cssWidth * dpr);
      const height = Math.floor(cssHeight * dpr);

      if (canvas.width !== width || canvas.height !== height) {
        canvas.width = width;
        canvas.height = height;
      }

      ctx.setTransform(1, 0, 0, 1, 0, 0);
      ctx.clearRect(0, 0, width, height);
      ctx.fillStyle = '#f8fafc';
      ctx.fillRect(0, 0, width, height);

      ctx.setTransform(dpr, 0, 0, dpr, cssWidth / 2, cssHeight / 2);
      const transforms = this.generateTransforms(
        this.args.rows,
        this.args.seatsPerRow,
        this.args.layout,
      );
      const limit = Math.min(transforms.length, 1000);
      const highlight = limit > 0 ? tickCount % limit : -1;

      for (let i = 0; i < limit; i++) {
        const seat = transforms[i];
        if (!seat) continue;

        ctx.save();
        ctx.translate(seat.x * 0.22, seat.y * 0.22);
        ctx.rotate(seat.rotation);

        ctx.strokeStyle = '#94a3b8';
        ctx.lineWidth = 1;
        ctx.strokeRect(-3.5, -3, 7, 6);

        if (i === highlight) {
          ctx.fillStyle = '#0f766e';
        } else {
          ctx.fillStyle = '#f8fafc';
        }
        ctx.fillRect(-3, -2.5, 6, 5);

        ctx.restore();
      }

      tickCount += 1;
      frameId = requestAnimationFrame(draw);
    };

    draw();

    return () => {
      if (frameId !== null) cancelAnimationFrame(frameId);
    };
  });

  private generateTransforms(
    rows: number,
    seatsPerRow: number,
    layout: SeatLayoutType,
  ): SeatTransform[] {
    if (layout === 'square') {
      const side = Math.max(1, Math.round((rows + seatsPerRow) / 2));
      return this.buildGrid(side, side);
    }
    if (layout === 'rectangle') {
      return this.buildGrid(Math.max(1, rows), Math.max(1, seatsPerRow));
    }
    return this.buildArch(Math.max(1, rows), Math.max(1, seatsPerRow));
  }

  private buildGrid(rows: number, cols: number): SeatTransform[] {
    const out: SeatTransform[] = [];
    const stepX = SEAT_W + SEAT_GAP;
    const stepY = SEAT_H + ROW_GAP;
    const startX = -((cols - 1) * stepX) / 2;
    const startY = ((rows - 1) * stepY) / 2;

    for (let r = 0; r < rows; r++) {
      for (let c = 0; c < cols; c++) {
        out.push({ x: startX + c * stepX, y: startY - r * stepY, rotation: 0 });
      }
    }

    return out;
  }

  private buildArch(rows: number, seatsPerRow: number): SeatTransform[] {
    const out: SeatTransform[] = [];

    for (let r = 0; r < rows; r++) {
      const radius = BASE_RADIUS + r * (SEAT_H + ROW_GAP);
      const stepArc = SEAT_W + SEAT_GAP;
      const halfSpan = ((seatsPerRow - 1) * stepArc) / 2;

      for (let s = 0; s < seatsPerRow; s++) {
        const arcOffset = -halfSpan + s * stepArc;
        const angle = arcOffset / radius;
        out.push({
          x: radius * Math.sin(angle),
          y: radius * Math.cos(angle) - BASE_RADIUS,
          rotation: -angle,
        });
      }
    }

    return out;
  }

  <template>
    <canvas class='w-full h-full block' {{this.setup}}></canvas>
  </template>
}
