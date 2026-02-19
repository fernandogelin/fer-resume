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
  Raycaster,
  Color,
  Object3D,
} from 'three';

interface SeatMapSceneSignature {
  Element: HTMLDivElement;
  Args: {
    rows: number;
    seatsPerRow: number;
    resetKey: number;
    onSelectionChange: (selected: number[]) => void;
  };
}

// Seat state colors (sRGB 0-1)
const COLOR_AVAILABLE = { r: 0.58, g: 0.64, b: 0.69 }; // slate-400 #94a3b8
const COLOR_HOVER = { r: 0.79, g: 0.83, b: 0.86 }; // slate-300 #cbd5e1

// Layout constants
const SEAT_W = 1.0;
const SEAT_H = 0.9;
const SEAT_GAP = 0.2;
const ROW_GAP = 0.25;
const BASE_RADIUS = 8;

type RGB = { r: number; g: number; b: number };

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

  private _renderer: WebGLRenderer | null = null;
  private _camera: OrthographicCamera | null = null;
  private _scene: Scene | null = null;
  private _mesh: InstancedMesh | null = null;
  private _raycaster: Raycaster | null = null;
  private _THREE: typeof import('three') | null = null;
  private _resizeObserver: ResizeObserver | null = null;

  setupScene = modifier(
    (canvas: HTMLCanvasElement, [rows, seatsPerRow]: [number, number, number]) => {
      this.selectedSeats = new Set();
      this.args.onSelectionChange([]);
      void this.initThree(canvas, rows, seatsPerRow);

      return () => {
        this.destroyThree();
      };
    },
  );

  private async initThree(
    canvas: HTMLCanvasElement,
    rows: number,
    seatsPerRow: number,
  ): Promise<void> {
    const THREE = await import('three');
    this._THREE = THREE;

    const width = canvas.clientWidth || 800;
    const height = canvas.clientHeight || 600;

    const renderer = new THREE.WebGLRenderer({ canvas, antialias: true });
    renderer.setSize(width, height, false);
    renderer.setPixelRatio(Math.min(globalThis.devicePixelRatio ?? 1, 2));
    renderer.setClearColor(0x0f172a, 1);

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

    const totalSeats = rows * seatsPerRow;
    const geometry = new THREE.PlaneGeometry(SEAT_W, SEAT_H);
    const material = new THREE.MeshBasicMaterial({ vertexColors: true });
    const mesh = new THREE.InstancedMesh(geometry, material, totalSeats);

    const dummy: Object3D = new THREE.Object3D();
    const color: Color = new THREE.Color();
    color.setRGB(COLOR_AVAILABLE.r, COLOR_AVAILABLE.g, COLOR_AVAILABLE.b);

    for (let r = 0; r < rows; r++) {
      const radius = BASE_RADIUS + r * (SEAT_H + ROW_GAP);
      const stepArc = SEAT_W + SEAT_GAP;
      const halfSpan = ((seatsPerRow - 1) * stepArc) / 2;

      for (let s = 0; s < seatsPerRow; s++) {
        const idx = r * seatsPerRow + s;
        const arcOffset = -halfSpan + s * stepArc;
        const angle = arcOffset / radius;

        dummy.position.set(radius * Math.sin(angle), radius * Math.cos(angle) - BASE_RADIUS, 0);
        dummy.rotation.set(0, 0, -angle);
        dummy.updateMatrix();
        mesh.setMatrixAt(idx, dummy.matrix);
        mesh.setColorAt(idx, color);
      }
    }

    mesh.instanceMatrix.needsUpdate = true;
    if (mesh.instanceColor) mesh.instanceColor.needsUpdate = true;

    scene.add(mesh);
    this._renderer = renderer;
    this._scene = scene;
    this._camera = camera;
    this._mesh = mesh;
    this._raycaster = raycaster;
    this.isDirty = true;

    this.startRenderLoop();

    this._resizeObserver = new ResizeObserver(() => this.onResize(canvas));
    this._resizeObserver.observe(canvas.parentElement ?? canvas);
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

  private destroyThree(): void {
    if (this.animFrameId !== null) {
      cancelAnimationFrame(this.animFrameId);
      this.animFrameId = null;
    }
    this._resizeObserver?.disconnect();
    this._resizeObserver = null;
    this._mesh?.geometry.dispose();
    const mat = this._mesh?.material;
    if (mat && !Array.isArray(mat)) mat.dispose();
    this._renderer?.dispose();
    this._renderer = null;
    this._scene = null;
    this._camera = null;
    this._mesh = null;
    this._raycaster = null;
    this._THREE = null;
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
    if (!this._raycaster || !this._camera || !this._mesh || !this._THREE) return null;
    const ndc = this.ndcFromPointer(canvas, clientX, clientY);
    this._raycaster.setFromCamera(new this._THREE.Vector2(ndc.x, ndc.y), this._camera);
    const hits = this._raycaster.intersectObject(this._mesh);
    const first = hits[0];
    return first !== undefined && first.instanceId !== undefined ? first.instanceId : null;
  }

  private paintSeat(idx: number): void {
    if (!this._mesh || !this._THREE) return;
    const c = new this._THREE.Color();
    if (this.selectedSeats.has(idx)) {
      c.setRGB(this.primaryColor.r, this.primaryColor.g, this.primaryColor.b);
    } else if (this.hoveredSeat === idx) {
      c.setRGB(COLOR_HOVER.r, COLOR_HOVER.g, COLOR_HOVER.b);
    } else {
      c.setRGB(COLOR_AVAILABLE.r, COLOR_AVAILABLE.g, COLOR_AVAILABLE.b);
    }
    this._mesh.setColorAt(idx, c);
    if (this._mesh.instanceColor) this._mesh.instanceColor.needsUpdate = true;
    this.isDirty = true;
  }

  @action
  onClick(event: MouseEvent): void {
    const canvas = event.currentTarget as HTMLCanvasElement;
    const idx = this.hitTest(canvas, event.clientX, event.clientY);
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
    const idx = this.hitTest(canvas, event.clientX, event.clientY);
    if (idx === this.hoveredSeat) return;

    const prev = this.hoveredSeat;
    this.hoveredSeat = idx;
    if (prev !== null) this.paintSeat(prev);
    if (idx !== null) this.paintSeat(idx);
    canvas.style.cursor = idx !== null ? 'pointer' : 'grab';
  }

  @action
  onMouseLeave(event: MouseEvent): void {
    const canvas = event.currentTarget as HTMLCanvasElement;
    if (this.hoveredSeat !== null) {
      const prev = this.hoveredSeat;
      this.hoveredSeat = null;
      this.paintSeat(prev);
    }
    if (this.isPanning) this.isPanning = false;
    canvas.style.cursor = 'default';
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
  }

  @action
  onPointerDown(event: PointerEvent): void {
    const canvas = event.currentTarget as HTMLCanvasElement;
    if (event.button !== 0) return;
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
  }

  @action
  onPointerUp(event: PointerEvent): void {
    if (!this.isPanning) return;
    this.isPanning = false;
    const canvas = event.currentTarget as HTMLCanvasElement;
    canvas.style.cursor = 'grab';
  }

  <template>
    <div class='relative w-full h-full' ...attributes>
      <canvas
        class='w-full h-full block'
        style='cursor: grab;'
        {{this.setupScene @rows @seatsPerRow @resetKey}}
        {{on 'click' this.onClick}}
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
