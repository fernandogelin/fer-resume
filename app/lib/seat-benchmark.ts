type SeatLayoutType =
  | 'square'
  | 'rectangle'
  | 'arch'
  | 'stadium-center'
  | 'stadium-side'
  | 'custom-draw';

interface BenchmarkArgs {
  rows: number;
  seatsPerRow: number;
  layout: SeatLayoutType;
}

interface SeatTransform {
  x: number;
  y: number;
  rotation: number;
}

interface BenchmarkResult {
  seatCount: number;
  frames: number;
  gpuMsPerFrame: number;
  cpuMsPerFrame: number;
  gpuFps: number;
  cpuFps: number;
  speedup: number;
}

const SEAT_W = 1.0;
const SEAT_H = 0.9;
const SEAT_GAP = 0.2;
const ROW_GAP = 0.25;
const BASE_RADIUS = 8;

export async function runSeatRenderingBenchmark(args: BenchmarkArgs): Promise<BenchmarkResult> {
  const rows = Math.max(1, args.rows);
  const seatsPerRow = Math.max(1, args.seatsPerRow);
  const transforms = generateTransforms(rows, seatsPerRow, args.layout);
  const seatCount = transforms.length;
  const frames = 120;

  const cpuMs = runCpuBenchmark(transforms, frames);
  const gpuMs = await runGpuBenchmark(transforms, frames);

  const gpuMsPerFrame = Number((gpuMs / frames).toFixed(3));
  const cpuMsPerFrame = Number((cpuMs / frames).toFixed(3));
  const gpuFps = Number((1000 / Math.max(gpuMsPerFrame, 0.001)).toFixed(1));
  const cpuFps = Number((1000 / Math.max(cpuMsPerFrame, 0.001)).toFixed(1));
  const speedup = Number((cpuMsPerFrame / Math.max(gpuMsPerFrame, 0.001)).toFixed(2));

  return {
    seatCount,
    frames,
    gpuMsPerFrame,
    cpuMsPerFrame,
    gpuFps,
    cpuFps,
    speedup,
  };
}

function runCpuBenchmark(transforms: SeatTransform[], frames: number): number {
  const canvas = document.createElement('canvas');
  canvas.width = 960;
  canvas.height = 640;
  const ctx = canvas.getContext('2d');
  if (!ctx) throw new Error('2D canvas not available for CPU benchmark');

  const t0 = performance.now();
  for (let frame = 0; frame < frames; frame++) {
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.fillStyle = '#f8fafc';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    ctx.setTransform(20, 0, 0, 20, canvas.width / 2, canvas.height / 2);

    for (let i = 0; i < transforms.length; i++) {
      const seat = transforms[i];
      if (!seat) continue;
      ctx.save();
      ctx.translate(seat.x, seat.y);
      ctx.rotate(seat.rotation);
      ctx.strokeStyle = '#94a3b8';
      ctx.lineWidth = 0.06;
      ctx.strokeRect(-SEAT_W / 2, -SEAT_H / 2, SEAT_W, SEAT_H);
      ctx.fillStyle = i % 30 === frame % 30 ? '#0f766e' : '#f8fafc';
      ctx.fillRect(-SEAT_W / 2 + 0.08, -SEAT_H / 2 + 0.08, SEAT_W - 0.16, SEAT_H - 0.16);
      ctx.restore();
    }
  }

  return performance.now() - t0;
}

async function runGpuBenchmark(transforms: SeatTransform[], frames: number): Promise<number> {
  const THREE = await import('three');

  const canvas = document.createElement('canvas');
  const width = 960;
  const height = 640;
  const renderer = new THREE.WebGLRenderer({ canvas, antialias: false });
  renderer.setSize(width, height, false);
  renderer.setPixelRatio(1);
  renderer.setClearColor(0xf8fafc, 1);

  const camera = new THREE.OrthographicCamera(-30, 30, 20, -20, 0.1, 1000);
  camera.position.set(0, 0, 50);
  camera.lookAt(0, 0, 0);

  const scene = new THREE.Scene();
  const geometry = new THREE.PlaneGeometry(SEAT_W, SEAT_H);
  const material = new THREE.MeshBasicMaterial({ color: 0x94a3b8 });
  const mesh = new THREE.InstancedMesh(geometry, material, transforms.length);
  const dummy = new THREE.Object3D();

  for (let i = 0; i < transforms.length; i++) {
    const seat = transforms[i];
    if (!seat) continue;
    dummy.position.set(seat.x, seat.y, 0);
    dummy.rotation.set(0, 0, seat.rotation);
    dummy.updateMatrix();
    mesh.setMatrixAt(i, dummy.matrix);
  }
  mesh.instanceMatrix.needsUpdate = true;
  scene.add(mesh);

  const t0 = performance.now();
  for (let frame = 0; frame < frames; frame++) {
    renderer.render(scene, camera);
  }
  const elapsed = performance.now() - t0;

  geometry.dispose();
  material.dispose();
  renderer.dispose();

  return elapsed;
}

function generateTransforms(
  rows: number,
  seatsPerRow: number,
  layout: SeatLayoutType,
): SeatTransform[] {
  if (layout === 'square') {
    const side = Math.max(1, Math.round((rows + seatsPerRow) / 2));
    return buildGrid(side, side);
  }

  if (layout === 'rectangle') {
    return buildGrid(rows, seatsPerRow);
  }

  return buildArch(rows, seatsPerRow);
}

function buildGrid(rows: number, cols: number): SeatTransform[] {
  const transforms: SeatTransform[] = [];
  const stepX = SEAT_W + SEAT_GAP;
  const stepY = SEAT_H + ROW_GAP;
  const startX = -((cols - 1) * stepX) / 2;
  const startY = ((rows - 1) * stepY) / 2;

  for (let r = 0; r < rows; r++) {
    for (let c = 0; c < cols; c++) {
      transforms.push({
        x: startX + c * stepX,
        y: startY - r * stepY,
        rotation: 0,
      });
    }
  }

  return transforms;
}

function buildArch(rows: number, seatsPerRow: number): SeatTransform[] {
  const transforms: SeatTransform[] = [];

  for (let r = 0; r < rows; r++) {
    const radius = BASE_RADIUS + r * (SEAT_H + ROW_GAP);
    const stepArc = SEAT_W + SEAT_GAP;
    const halfSpan = ((seatsPerRow - 1) * stepArc) / 2;

    for (let s = 0; s < seatsPerRow; s++) {
      const arcOffset = -halfSpan + s * stepArc;
      const angle = arcOffset / radius;
      transforms.push({
        x: radius * Math.sin(angle),
        y: radius * Math.cos(angle) - BASE_RADIUS,
        rotation: -angle,
      });
    }
  }

  return transforms;
}
