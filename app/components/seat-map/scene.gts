import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { modifier } from 'ember-modifier';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import type {
  WebGLRenderer,
  OrthographicCamera,
  Scene,
  InstancedMesh,
  Color,
  Mesh,
  BufferGeometry,
  Raycaster,
  Object3D,
  Line,
} from 'three';

export type SeatLayoutType =
  | 'square'
  | 'rectangle'
  | 'arch'
  | 'stadium-center'
  | 'stadium-side'
  | 'custom-draw';

interface SeatMapSceneSignature {
  Element: HTMLDivElement;
  Args: {
    rows: number;
    seatsPerRow: number;
    layout: SeatLayoutType;
    resetKey: number;
    onSelectionChange: (selected: number[]) => void;
  };
}

// Seat state colors (sRGB 0-1)
const COLOR_BACKGROUND = { r: 0.96, g: 0.97, b: 0.99 }; // slate-50 #f8fafc
const COLOR_OUTLINE = { r: 0.58, g: 0.64, b: 0.69 }; // slate-400 #94a3b8
const COLOR_HOVER = { r: 0.79, g: 0.83, b: 0.86 }; // slate-300 #cbd5e1

// Layout constants
const SEAT_W = 0.82;
const SEAT_H = 0.74;
const SEAT_INSET = 0.1;
const SEAT_RADIUS = 0.12;
const SEAT_GAP = 0.16;
const ROW_GAP = 0.2;
const BASE_RADIUS = 8;
const STAGE_RADIUS = 3;
const DRAW_CLOSE_DISTANCE = 1.4;
const MIN_SEAT_DISTANCE = 0.76;

type RGB = { r: number; g: number; b: number };
type Point = { x: number; y: number };
type SeatTransform = { x: number; y: number; rotation: number };

export default class SeatMapScene extends Component<SeatMapSceneSignature> {
  @tracked selectedSeats = new Set<number>();

  private hoveredSeat: number | null = null;
  private isPanning = false;
  private panStart = { x: 0, y: 0 };
  private cameraX = 0;
  private cameraY = 0;
  private frustumHalf = 20;
  private animFrameId: number | null = null;
  private isDirty = false;
  private primaryColor: RGB = { r: 0.09, g: 0.39, b: 0.24 };
  private hoverFrameId: number | null = null;
  private pendingHover: { canvas: HTMLCanvasElement; clientX: number; clientY: number } | null =
    null;

  private _renderer: WebGLRenderer | null = null;
  private _camera: OrthographicCamera | null = null;
  private _scene: Scene | null = null;
  private _canvas: HTMLCanvasElement | null = null;
  private _gridOverlayEl: HTMLDivElement | null = null;
  private _outlineMesh: InstancedMesh | null = null;
  private _fillMesh: InstancedMesh | null = null;
  private _fillGeometry: BufferGeometry | null = null;
  private _stageMesh: Mesh | null = null;
  private _drawLine: Line | null = null;
  private _drawPoints: Point[] = [];
  private _drawClosed = false;
  private _seatTransforms: SeatTransform[] = [];
  private _raycaster: Raycaster | null = null;
  private _THREE: typeof import('three') | null = null;
  private _scratchColor: Color | null = null;
  private _resizeObserver: ResizeObserver | null = null;

  setupScene = modifier(
    (
      canvas: HTMLCanvasElement,
      [rows, seatsPerRow, layout]: [number, number, SeatLayoutType, number],
    ) => {
      this.selectedSeats = new Set();
      this.args.onSelectionChange([]);
      void this.initThree(canvas, rows, seatsPerRow, layout);

      return () => {
        this.destroyThree();
      };
    },
  );

  setupGridOverlay = modifier((element: HTMLDivElement) => {
    this._gridOverlayEl = element;
    this.updateGridOverlayStyle();

    return () => {
      if (this._gridOverlayEl === element) {
        this._gridOverlayEl = null;
      }
    };
  });

  private async initThree(
    canvas: HTMLCanvasElement,
    rows: number,
    seatsPerRow: number,
    layout: SeatLayoutType,
  ): Promise<void> {
    const THREE = await import('three');
    this._THREE = THREE;
    this._scratchColor = new THREE.Color();

    const width = canvas.clientWidth || 800;
    const height = canvas.clientHeight || 600;

    const renderer = new THREE.WebGLRenderer({ canvas, antialias: true });
    renderer.setSize(width, height, false);
    renderer.setPixelRatio(Math.min(globalThis.devicePixelRatio ?? 1, 2));
    renderer.setClearColor(
      new THREE.Color(COLOR_BACKGROUND.r, COLOR_BACKGROUND.g, COLOR_BACKGROUND.b),
      1,
    );

    const aspect = width / height;
    const camera = new THREE.OrthographicCamera(
      -this.frustumHalf * aspect,
      this.frustumHalf * aspect,
      this.frustumHalf,
      -this.frustumHalf,
      0.1,
      1000,
    );
    camera.position.set(this.cameraX, this.cameraY, 50);
    camera.lookAt(this.cameraX, this.cameraY, 0);

    const scene = new THREE.Scene();
    const raycaster = new THREE.Raycaster();

    this.primaryColor = this.readPrimaryColor();
    this._drawPoints = [];
    this._drawClosed = false;

    this._renderer = renderer;
    this._scene = scene;
    this._camera = camera;
    this._canvas = canvas;
    this._raycaster = raycaster;

    this.buildStage(layout);
    this.rebuildSeats(rows, seatsPerRow, layout);

    this.isDirty = true;

    this.startRenderLoop();

    this._resizeObserver = new ResizeObserver(() => this.onResize(canvas));
    this._resizeObserver.observe(canvas.parentElement ?? canvas);
    this.updateGridOverlayStyle();
  }

  private positiveMod(value: number, divisor: number): number {
    return ((value % divisor) + divisor) % divisor;
  }

  private updateGridOverlayStyle(): void {
    if (!this._gridOverlayEl || !this._canvas) return;

    const canvasHeight = this._canvas.clientHeight || 600;
    const pixelsPerWorld = canvasHeight / (this.frustumHalf * 2);
    const gridWorld = SEAT_W + SEAT_GAP;
    const gridPx = Math.max(10, Math.min(48, gridWorld * pixelsPerWorld));

    const dashLength = Math.max(2, Math.round(gridPx * 0.26));
    const gapLength = Math.max(2, Math.round(gridPx * 0.24));
    const strokeWidth = 1;

    const offsetX = this.positiveMod(-this.cameraX * pixelsPerWorld, gridPx);
    const offsetY = this.positiveMod(this.cameraY * pixelsPerWorld, gridPx);

    const svg = `<svg xmlns='http://www.w3.org/2000/svg' width='${gridPx}' height='${gridPx}' viewBox='0 0 ${gridPx} ${gridPx}' fill='none'><path d='M0 0H${gridPx} M0 0V${gridPx}' stroke='rgba(162, 154, 146, 0.55)' stroke-width='${strokeWidth}' stroke-dasharray='${dashLength} ${gapLength}' stroke-linecap='round'/></svg>`;
    const dataUri = `url("data:image/svg+xml,${encodeURIComponent(svg)}")`;

    this._gridOverlayEl.style.backgroundImage = dataUri;
    this._gridOverlayEl.style.backgroundRepeat = 'repeat';
    this._gridOverlayEl.style.backgroundSize = `${gridPx}px ${gridPx}px`;
    this._gridOverlayEl.style.backgroundPosition = `${offsetX}px ${offsetY}px`;
    this._gridOverlayEl.style.opacity = '0.8';
  }

  private rebuildSeats(rows: number, seatsPerRow: number, layout: SeatLayoutType): void {
    if (!this._THREE || !this._scene) return;

    if (this._outlineMesh) {
      this._scene.remove(this._outlineMesh);
      this._outlineMesh.geometry.dispose();
      const outlineMat = this._outlineMesh.material;
      if (outlineMat && !Array.isArray(outlineMat)) outlineMat.dispose();
      this._outlineMesh = null;
    }

    if (this._fillMesh) {
      this._scene.remove(this._fillMesh);
      const fillMat = this._fillMesh.material;
      if (fillMat && !Array.isArray(fillMat)) fillMat.dispose();
      this._fillMesh = null;
    }
    this._fillGeometry?.dispose();
    this._fillGeometry = null;

    const transforms = this.generateSeatTransforms(rows, seatsPerRow, layout);
    this._seatTransforms = transforms;

    if (transforms.length === 0) {
      this.selectedSeats = new Set();
      this.hoveredSeat = null;
      this.args.onSelectionChange([]);
      this.isDirty = true;
      return;
    }

    const fillWidth = Math.max(0.1, SEAT_W - SEAT_INSET * 2);
    const fillHeight = Math.max(0.1, SEAT_H - SEAT_INSET * 2);
    const outlineGeometry = this.createRoundedRectGeometry(
      this._THREE,
      SEAT_W,
      SEAT_H,
      SEAT_RADIUS,
    );
    const roundedFillGeometry = this.createRoundedRectGeometry(
      this._THREE,
      fillWidth,
      fillHeight,
      Math.max(0.04, SEAT_RADIUS - SEAT_INSET * 0.6),
    );

    const outlineMaterial = new this._THREE.MeshBasicMaterial({
      color: new this._THREE.Color(COLOR_OUTLINE.r, COLOR_OUTLINE.g, COLOR_OUTLINE.b),
    });
    const outlineMesh = new this._THREE.InstancedMesh(
      outlineGeometry,
      outlineMaterial,
      transforms.length,
    );
    const fillMaterial = new this._THREE.MeshBasicMaterial({
      color: new this._THREE.Color(COLOR_BACKGROUND.r, COLOR_BACKGROUND.g, COLOR_BACKGROUND.b),
    });
    const fillMesh = new this._THREE.InstancedMesh(
      roundedFillGeometry,
      fillMaterial,
      transforms.length,
    );
    const outlineDummy: Object3D = new this._THREE.Object3D();
    const fillDummy: Object3D = new this._THREE.Object3D();
    const initialFillColor = new this._THREE.Color(
      COLOR_BACKGROUND.r,
      COLOR_BACKGROUND.g,
      COLOR_BACKGROUND.b,
    );

    for (let i = 0; i < transforms.length; i++) {
      const seat = transforms[i];
      if (!seat) continue;

      outlineDummy.position.set(seat.x, seat.y, 0);
      outlineDummy.rotation.set(0, 0, seat.rotation);
      outlineDummy.updateMatrix();
      outlineMesh.setMatrixAt(i, outlineDummy.matrix);

      fillDummy.position.set(seat.x, seat.y, 0.001);
      fillDummy.rotation.set(0, 0, seat.rotation);
      fillDummy.updateMatrix();
      fillMesh.setMatrixAt(i, fillDummy.matrix);
      fillMesh.setColorAt(i, initialFillColor);
    }

    outlineMesh.instanceMatrix.needsUpdate = true;
    fillMesh.instanceMatrix.needsUpdate = true;
    if (fillMesh.instanceColor) {
      fillMesh.instanceColor.needsUpdate = true;
    }
    this._scene.add(outlineMesh);
    this._scene.add(fillMesh);

    this._outlineMesh = outlineMesh;
    this._fillMesh = fillMesh;
    this._fillGeometry = roundedFillGeometry;
    this.selectedSeats = new Set();
    this.hoveredSeat = null;
    this.args.onSelectionChange([]);
    this.isDirty = true;
  }

  private buildStage(layout: SeatLayoutType): void {
    if (!this._THREE || !this._scene) return;
    if (this._stageMesh) {
      this._scene.remove(this._stageMesh);
      this._stageMesh.geometry.dispose();
      const mat = this._stageMesh.material;
      if (mat && !Array.isArray(mat)) mat.dispose();
      this._stageMesh = null;
    }

    if (layout === 'square' || layout === 'rectangle' || layout === 'arch') return;

    if (layout === 'stadium-side') {
      const geometry = new this._THREE.BoxGeometry(6, 3.5, 0.2);
      const material = new this._THREE.MeshBasicMaterial({ color: 0x64748b });
      const mesh = new this._THREE.Mesh(geometry, material);
      mesh.position.set(-14, 0, 0.03);
      this._stageMesh = mesh;
      this._scene.add(mesh);
      return;
    }

    const geometry = new this._THREE.CircleGeometry(STAGE_RADIUS, 48);
    const material = new this._THREE.MeshBasicMaterial({ color: 0x64748b });
    const mesh = new this._THREE.Mesh(geometry, material);
    mesh.position.set(0, 0, 0.03);
    this._stageMesh = mesh;
    this._scene.add(mesh);
  }

  private generateSeatTransforms(
    rows: number,
    seatsPerRow: number,
    layout: SeatLayoutType,
  ): SeatTransform[] {
    const safeRows = Math.max(1, rows);
    const safeSeats = Math.max(1, seatsPerRow);
    let transforms: SeatTransform[] = [];

    if (layout === 'square') {
      const side = Math.max(1, Math.round((safeRows + safeSeats) / 2));
      transforms = this.buildGridTransforms(side, side);
      return this.enforceSeatSpacing(transforms);
    }

    if (layout === 'rectangle') {
      transforms = this.buildGridTransforms(safeRows, safeSeats);
      return this.enforceSeatSpacing(transforms);
    }

    if (layout === 'arch') {
      transforms = this.buildArchTransforms(safeRows, safeSeats);
      return this.enforceSeatSpacing(transforms);
    }

    if (layout === 'stadium-center') {
      transforms = this.buildStadiumCenterTransforms(safeRows, safeSeats);
      return this.enforceSeatSpacing(transforms);
    }

    if (layout === 'stadium-side') {
      transforms = this.buildStadiumSideTransforms(safeRows, safeSeats);
      return this.enforceSeatSpacing(transforms);
    }

    if (this._drawClosed) {
      transforms = this.buildCustomDrawTransforms(safeRows, safeSeats);
      return this.enforceSeatSpacing(transforms);
    }

    return [];
  }

  private enforceSeatSpacing(transforms: SeatTransform[]): SeatTransform[] {
    if (transforms.length <= 1) return transforms;

    const cellSize = MIN_SEAT_DISTANCE;
    const minDistanceSq = MIN_SEAT_DISTANCE * MIN_SEAT_DISTANCE;
    const grid = new Map<string, SeatTransform[]>();
    const result: SeatTransform[] = [];

    const cellKey = (x: number, y: number): string =>
      `${Math.floor(x / cellSize)}:${Math.floor(y / cellSize)}`;

    for (const seat of transforms) {
      const cellX = Math.floor(seat.x / cellSize);
      const cellY = Math.floor(seat.y / cellSize);
      let overlaps = false;

      for (let dx = -1; dx <= 1 && !overlaps; dx++) {
        for (let dy = -1; dy <= 1 && !overlaps; dy++) {
          const key = `${cellX + dx}:${cellY + dy}`;
          const bucket = grid.get(key);
          if (!bucket) continue;

          for (const other of bucket) {
            const distSq =
              (seat.x - other.x) * (seat.x - other.x) + (seat.y - other.y) * (seat.y - other.y);
            if (distSq < minDistanceSq) {
              overlaps = true;
              break;
            }
          }
        }
      }

      if (overlaps) continue;

      const key = cellKey(seat.x, seat.y);
      const bucket = grid.get(key);
      if (bucket) {
        bucket.push(seat);
      } else {
        grid.set(key, [seat]);
      }
      result.push(seat);
    }

    return result;
  }

  private buildGridTransforms(rows: number, cols: number): SeatTransform[] {
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

  private buildArchTransforms(rows: number, seatsPerRow: number): SeatTransform[] {
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

  private buildStadiumCenterTransforms(rows: number, seatsPerRow: number): SeatTransform[] {
    const transforms: SeatTransform[] = [];

    for (let r = 0; r < rows; r++) {
      const radius = STAGE_RADIUS + 2.2 + r * (SEAT_H + ROW_GAP);
      const count = Math.max(
        8,
        Math.round(((2 * Math.PI * radius) / (SEAT_W + SEAT_GAP)) * (seatsPerRow / 20)),
      );

      for (let i = 0; i < count; i++) {
        const theta = (i / count) * Math.PI * 2;
        const x = radius * Math.cos(theta);
        const y = radius * Math.sin(theta);
        const facing = Math.atan2(-y, -x);
        transforms.push({ x, y, rotation: facing + Math.PI / 2 });
      }
    }

    return transforms;
  }

  private buildStadiumSideTransforms(rows: number, seatsPerRow: number): SeatTransform[] {
    const transforms: SeatTransform[] = [];
    const stageX = -14;
    const stageY = 0;

    for (let r = 0; r < rows; r++) {
      const radius = 5 + r * (SEAT_H + ROW_GAP);

      for (let s = 0; s < seatsPerRow; s++) {
        const t = seatsPerRow === 1 ? 0.5 : s / (seatsPerRow - 1);
        const theta = -Math.PI / 2 + t * Math.PI;
        const x = stageX + radius * Math.cos(theta) + 2.5;
        const y = stageY + radius * Math.sin(theta);
        const facing = Math.atan2(stageY - y, stageX - x);
        transforms.push({ x, y, rotation: facing + Math.PI / 2 });
      }
    }

    return transforms;
  }

  private buildCustomDrawTransforms(rows: number, seatsPerRow: number): SeatTransform[] {
    if (this._drawPoints.length < 3) return [];

    let minX = this._drawPoints[0]!.x;
    let maxX = this._drawPoints[0]!.x;
    let minY = this._drawPoints[0]!.y;
    let maxY = this._drawPoints[0]!.y;

    for (const p of this._drawPoints) {
      minX = Math.min(minX, p.x);
      maxX = Math.max(maxX, p.x);
      minY = Math.min(minY, p.y);
      maxY = Math.max(maxY, p.y);
    }

    const transforms: SeatTransform[] = [];
    const stepX = SEAT_W + SEAT_GAP;
    const stepY = SEAT_H + ROW_GAP;
    const densityRows = Math.max(1, rows);
    const densityCols = Math.max(1, seatsPerRow);
    const xStride = Math.max(stepX, (maxX - minX) / densityCols);
    const yStride = Math.max(stepY, (maxY - minY) / densityRows);
    const stageBuffer = STAGE_RADIUS + 1.6;

    for (let y = maxY; y >= minY; y -= yStride) {
      for (let x = minX; x <= maxX; x += xStride) {
        if (!this.pointInPolygon({ x, y }, this._drawPoints)) continue;
        if (Math.hypot(x, y) < stageBuffer) continue;
        const facing = Math.atan2(-y, -x);
        transforms.push({ x, y, rotation: facing + Math.PI / 2 });
      }
    }

    return transforms;
  }

  private pointInPolygon(point: Point, polygon: Point[]): boolean {
    let inside = false;
    for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      const xi = polygon[i]!.x;
      const yi = polygon[i]!.y;
      const xj = polygon[j]!.x;
      const yj = polygon[j]!.y;
      const intersects =
        yi > point.y !== yj > point.y &&
        point.x < ((xj - xi) * (point.y - yi)) / (yj - yi || 1e-6) + xi;
      if (intersects) inside = !inside;
    }
    return inside;
  }

  private updateDrawOverlay(): void {
    if (!this._THREE || !this._scene) return;

    if (this._drawLine) {
      this._scene.remove(this._drawLine);
      this._drawLine.geometry.dispose();
      const mat = this._drawLine.material;
      if (mat && !Array.isArray(mat)) mat.dispose();
      this._drawLine = null;
    }

    if (this._drawPoints.length === 0) return;

    const points = [...this._drawPoints];
    if (this._drawClosed) {
      points.push(this._drawPoints[0]!);
    }

    const vectors = points.map((p) => new this._THREE!.Vector3(p.x, p.y, 0.02));
    const geometry = new this._THREE.BufferGeometry().setFromPoints(vectors);
    const material = new this._THREE.LineBasicMaterial({ color: 0x64748b });
    this._drawLine = new this._THREE.Line(geometry, material);
    this._scene.add(this._drawLine);
  }

  private worldFromPointer(
    canvas: HTMLCanvasElement,
    clientX: number,
    clientY: number,
  ): Point | null {
    if (!this._camera || !this._THREE) return null;
    const ndc = this.ndcFromPointer(canvas, clientX, clientY);
    const world = new this._THREE.Vector3(ndc.x, ndc.y, 0).unproject(this._camera);
    return { x: world.x, y: world.y };
  }

  private createRoundedRectGeometry(
    THREE: typeof import('three'),
    width: number,
    height: number,
    radius: number,
  ) {
    const halfW = width / 2;
    const halfH = height / 2;
    const r = Math.max(0, Math.min(radius, halfW, halfH));

    const shape = new THREE.Shape();
    shape.moveTo(-halfW + r, -halfH);
    shape.lineTo(halfW - r, -halfH);
    shape.quadraticCurveTo(halfW, -halfH, halfW, -halfH + r);
    shape.lineTo(halfW, halfH - r);
    shape.quadraticCurveTo(halfW, halfH, halfW - r, halfH);
    shape.lineTo(-halfW + r, halfH);
    shape.quadraticCurveTo(-halfW, halfH, -halfW, halfH - r);
    shape.lineTo(-halfW, -halfH + r);
    shape.quadraticCurveTo(-halfW, -halfH, -halfW + r, -halfH);

    return new THREE.ShapeGeometry(shape);
  }

  private readPrimaryColor(): RGB {
    try {
      const raw = getComputedStyle(document.documentElement).getPropertyValue('--primary').trim();
      const parts = raw.split(/[\s,]+/);
      if (parts.length >= 3) {
        const h = parseFloat(parts[0] ?? '0') / 360;
        const s = parseFloat(parts[1] ?? '0') / 100;
        const l = parseFloat(parts[2] ?? '0') / 100;
        return this.hslToRgb(h, s, l);
      }
    } catch {
      /* fallback */
    }
    return { r: 0.09, g: 0.39, b: 0.24 };
  }

  private hslToRgb(h: number, s: number, l: number): RGB {
    if (s === 0) return { r: l, g: l, b: l };
    const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    const p = 2 * l - q;
    const hue2rgb = (t: number): number => {
      let tt = t;
      if (tt < 0) tt += 1;
      if (tt > 1) tt -= 1;
      if (tt < 1 / 6) return p + (q - p) * 6 * tt;
      if (tt < 1 / 2) return q;
      if (tt < 2 / 3) return p + (q - p) * (2 / 3 - tt) * 6;
      return p;
    };
    return { r: hue2rgb(h + 1 / 3), g: hue2rgb(h), b: hue2rgb(h - 1 / 3) };
  }

  private startRenderLoop(): void {
    const tick = (): void => {
      this.animFrameId = requestAnimationFrame(tick);
      if (this.isDirty && this._renderer && this._scene && this._camera) {
        this._renderer.render(this._scene, this._camera);
        this.isDirty = false;
      }
    };
    tick();
  }

  private flushHoverHitTest(): void {
    this.hoverFrameId = null;
    const pending = this.pendingHover;
    if (!pending) return;

    this.pendingHover = null;
    const idx = this.hitTest(pending.canvas, pending.clientX, pending.clientY);
    if (idx === this.hoveredSeat) return;

    const prev = this.hoveredSeat;
    this.hoveredSeat = idx;
    if (prev !== null) this.paintSeat(prev);
    if (idx !== null) this.paintSeat(idx);
    pending.canvas.style.cursor = idx !== null ? 'pointer' : 'grab';
  }

  private destroyThree(): void {
    if (this.animFrameId !== null) {
      cancelAnimationFrame(this.animFrameId);
      this.animFrameId = null;
    }
    if (this.hoverFrameId !== null) {
      cancelAnimationFrame(this.hoverFrameId);
      this.hoverFrameId = null;
    }
    this.pendingHover = null;
    this._resizeObserver?.disconnect();
    this._resizeObserver = null;
    this._outlineMesh?.geometry.dispose();
    const outlineMat = this._outlineMesh?.material;
    if (outlineMat && !Array.isArray(outlineMat)) outlineMat.dispose();
    const fillMat = this._fillMesh?.material;
    if (fillMat && !Array.isArray(fillMat)) fillMat.dispose();
    if (this._stageMesh) {
      this._stageMesh.geometry.dispose();
      const stageMat = this._stageMesh.material;
      if (stageMat && !Array.isArray(stageMat)) stageMat.dispose();
    }
    if (this._drawLine) {
      this._drawLine.geometry.dispose();
      const drawMat = this._drawLine.material;
      if (drawMat && !Array.isArray(drawMat)) drawMat.dispose();
    }
    this._fillGeometry?.dispose();
    this._renderer?.dispose();
    this._renderer = null;
    this._scene = null;
    this._camera = null;
    this._canvas = null;
    this._outlineMesh = null;
    this._fillMesh = null;
    this._fillGeometry = null;
    this._stageMesh = null;
    this._drawLine = null;
    this._drawPoints = [];
    this._drawClosed = false;
    this._seatTransforms = [];
    this._raycaster = null;
    this._THREE = null;
    this._scratchColor = null;
  }

  private onResize(canvas: HTMLCanvasElement): void {
    if (!this._renderer || !this._camera) return;
    const w = canvas.clientWidth || 800;
    const h = canvas.clientHeight || 600;
    const aspect = w / h;
    this._renderer.setSize(w, h, false);
    this._camera.left = -this.frustumHalf * aspect;
    this._camera.right = this.frustumHalf * aspect;
    this._camera.top = this.frustumHalf;
    this._camera.bottom = -this.frustumHalf;
    this._camera.updateProjectionMatrix();
    this.isDirty = true;
    this.updateGridOverlayStyle();
  }

  private ndcFromPointer(
    canvas: HTMLCanvasElement,
    clientX: number,
    clientY: number,
  ): { x: number; y: number } {
    const r = canvas.getBoundingClientRect();
    return {
      x: ((clientX - r.left) / r.width) * 2 - 1,
      y: -((clientY - r.top) / r.height) * 2 + 1,
    };
  }

  private hitTest(canvas: HTMLCanvasElement, clientX: number, clientY: number): number | null {
    if (!this._raycaster || !this._camera || !this._outlineMesh || !this._THREE) return null;
    const ndc = this.ndcFromPointer(canvas, clientX, clientY);
    this._raycaster.setFromCamera(new this._THREE.Vector2(ndc.x, ndc.y), this._camera);
    const hits = this._raycaster.intersectObject(this._outlineMesh);
    const first = hits[0];
    return first !== undefined && first.instanceId !== undefined ? first.instanceId : null;
  }

  private paintSeat(idx: number): void {
    if (!this._fillMesh || !this._scratchColor) return;

    if (this.selectedSeats.has(idx)) {
      this._scratchColor.setRGB(this.primaryColor.r, this.primaryColor.g, this.primaryColor.b);
    } else if (this.hoveredSeat === idx) {
      this._scratchColor.setRGB(COLOR_HOVER.r, COLOR_HOVER.g, COLOR_HOVER.b);
    } else {
      this._scratchColor.setRGB(COLOR_BACKGROUND.r, COLOR_BACKGROUND.g, COLOR_BACKGROUND.b);
    }

    this._fillMesh.setColorAt(idx, this._scratchColor);
    if (this._fillMesh.instanceColor) {
      this._fillMesh.instanceColor.needsUpdate = true;
    }
    this.isDirty = true;
  }

  @action
  onClick(event: MouseEvent): void {
    const canvas = event.currentTarget as HTMLCanvasElement;
    const idx = this.hitTest(canvas, event.clientX, event.clientY);

    if (this.args.layout === 'custom-draw' && idx === null && !this._drawClosed) {
      const point = this.worldFromPointer(canvas, event.clientX, event.clientY);
      if (!point) return;

      if (this._drawPoints.length >= 3) {
        const first = this._drawPoints[0]!;
        if (Math.hypot(point.x - first.x, point.y - first.y) <= DRAW_CLOSE_DISTANCE) {
          this._drawClosed = true;
          this.updateDrawOverlay();
          this.rebuildSeats(this.args.rows, this.args.seatsPerRow, this.args.layout);
          this.isDirty = true;
          return;
        }
      }

      this._drawPoints = [...this._drawPoints, point];
      this.updateDrawOverlay();
      this.isDirty = true;
      return;
    }

    if (idx === null) return;

    const next = new Set(this.selectedSeats);
    if (next.has(idx)) {
      next.delete(idx);
    } else {
      next.add(idx);
    }
    this.selectedSeats = next;
    this.paintSeat(idx);
    this.args.onSelectionChange([...this.selectedSeats]);
  }

  @action
  onMouseMove(event: MouseEvent): void {
    const canvas = event.currentTarget as HTMLCanvasElement;

    if (this.args.layout === 'custom-draw' && !this._drawClosed) {
      canvas.style.cursor = 'crosshair';
      return;
    }

    this.pendingHover = { canvas, clientX: event.clientX, clientY: event.clientY };
    if (this.hoverFrameId === null) {
      this.hoverFrameId = requestAnimationFrame(() => this.flushHoverHitTest());
    }
  }

  @action
  onMouseLeave(event: MouseEvent): void {
    const canvas = event.currentTarget as HTMLCanvasElement;
    if (this.hoverFrameId !== null) {
      cancelAnimationFrame(this.hoverFrameId);
      this.hoverFrameId = null;
    }
    this.pendingHover = null;
    if (this.hoveredSeat !== null) {
      const prev = this.hoveredSeat;
      this.hoveredSeat = null;
      this.paintSeat(prev);
    }
    if (this.isPanning) this.isPanning = false;
    canvas.style.cursor =
      this.args.layout === 'custom-draw' && !this._drawClosed ? 'crosshair' : 'default';
  }

  @action
  onWheel(event: WheelEvent): void {
    event.preventDefault();
    if (!this._camera) return;
    const canvas = event.currentTarget as HTMLCanvasElement;
    const factor = event.deltaY > 0 ? 1.1 : 0.9;
    this.frustumHalf = Math.max(4, Math.min(80, this.frustumHalf * factor));
    const aspect = (canvas.clientWidth || 800) / (canvas.clientHeight || 600);
    this._camera.left = -this.frustumHalf * aspect;
    this._camera.right = this.frustumHalf * aspect;
    this._camera.top = this.frustumHalf;
    this._camera.bottom = -this.frustumHalf;
    this._camera.updateProjectionMatrix();
    this.isDirty = true;
    this.updateGridOverlayStyle();
  }

  @action
  onPointerDown(event: PointerEvent): void {
    const canvas = event.currentTarget as HTMLCanvasElement;
    if (event.button !== 0) return;
    if (this.args.layout === 'custom-draw' && !this._drawClosed) return;
    const idx = this.hitTest(canvas, event.clientX, event.clientY);
    if (idx !== null) return;
    this.isPanning = true;
    this.panStart = { x: event.clientX, y: event.clientY };
    canvas.setPointerCapture(event.pointerId);
    canvas.style.cursor = 'grabbing';
  }

  @action
  onPointerMove(event: PointerEvent): void {
    if (!this.isPanning || !this._camera) return;
    const canvas = event.currentTarget as HTMLCanvasElement;
    const dx = event.clientX - this.panStart.x;
    const dy = event.clientY - this.panStart.y;
    this.panStart = { x: event.clientX, y: event.clientY };
    const scale = (this.frustumHalf * 2) / (canvas.clientHeight || 600);
    this.cameraX -= dx * scale;
    this.cameraY += dy * scale;
    this._camera.position.set(this.cameraX, this.cameraY, 50);
    this._camera.updateProjectionMatrix();
    this.isDirty = true;
    this.updateGridOverlayStyle();
  }

  @action
  onPointerUp(event: PointerEvent): void {
    if (!this.isPanning) return;
    this.isPanning = false;
    const canvas = event.currentTarget as HTMLCanvasElement;
    canvas.style.cursor =
      this.args.layout === 'custom-draw' && !this._drawClosed ? 'crosshair' : 'grab';
  }

  @action
  onDoubleClick(): void {
    if (this.args.layout !== 'custom-draw') return;
    if (this._drawClosed) return;
    if (this._drawPoints.length < 3) return;
    this._drawClosed = true;
    this.updateDrawOverlay();
    this.rebuildSeats(this.args.rows, this.args.seatsPerRow, this.args.layout);
    this.isDirty = true;
  }

  <template>
    <div class='relative w-full h-full' ...attributes>
      <div class='absolute inset-0 pointer-events-none' {{this.setupGridOverlay}}></div>
      <canvas
        class='w-full h-full block'
        style='cursor: grab;'
        {{this.setupScene @rows @seatsPerRow @layout @resetKey}}
        {{on 'click' this.onClick}}
        {{on 'dblclick' this.onDoubleClick}}
        {{on 'mousemove' this.onMouseMove}}
        {{on 'mouseleave' this.onMouseLeave}}
        {{on 'wheel' this.onWheel passive=false}}
        {{on 'pointerdown' this.onPointerDown}}
        {{on 'pointermove' this.onPointerMove}}
        {{on 'pointerup' this.onPointerUp}}
      ></canvas>
    </div>
  </template>
}
