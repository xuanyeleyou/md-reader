import {
  availableMonitors,
  getCurrentWindow,
  PhysicalPosition,
  PhysicalSize,
} from "@tauri-apps/api/window";

interface SavedWindowState {
  x: number;
  y: number;
  width: number;
  height: number;
}

const STORAGE = "md-reader-window-state";
const MIN_WIDTH = 600;
const MIN_HEIGHT = 400;
const VISIBLE_BAR = 80;

function readSavedState(): SavedWindowState | null {
  try {
    const raw = localStorage.getItem(STORAGE);
    if (!raw) return null;
    const parsed = JSON.parse(raw) as Partial<SavedWindowState>;
    const { x, y, width, height } = parsed;
    if (
      typeof x !== "number" ||
      typeof y !== "number" ||
      typeof width !== "number" ||
      typeof height !== "number" ||
      !Number.isFinite(x) ||
      !Number.isFinite(y) ||
      !Number.isFinite(width) ||
      !Number.isFinite(height)
    ) {
      return null;
    }
    return { x, y, width, height };
  } catch {
    return null;
  }
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}

function pickWorkArea(
  saved: SavedWindowState,
  monitors: Awaited<ReturnType<typeof availableMonitors>>
) {
  return (
    monitors.find((monitor) => {
      const area = monitor.workArea;
      return (
        saved.x + VISIBLE_BAR >= area.position.x &&
        saved.x <= area.position.x + area.size.width - VISIBLE_BAR &&
        saved.y + VISIBLE_BAR >= area.position.y &&
        saved.y <= area.position.y + area.size.height - VISIBLE_BAR
      );
    })?.workArea || monitors[0]?.workArea
  );
}

export async function restoreWindowState(): Promise<void> {
  const saved = readSavedState();
  if (!saved) return;
  try {
    const window = getCurrentWindow();
    const monitors = await availableMonitors();
    const workArea = pickWorkArea(saved, monitors);
    if (!workArea) return;
    const width = clamp(saved.width, MIN_WIDTH, workArea.size.width);
    const height = clamp(saved.height, MIN_HEIGHT, workArea.size.height);
    const maxX = workArea.position.x + workArea.size.width - VISIBLE_BAR;
    const maxY = workArea.position.y + workArea.size.height - VISIBLE_BAR;
    const x = clamp(saved.x, workArea.position.x, maxX);
    const y = clamp(saved.y, workArea.position.y, maxY);
    await window.setSize(new PhysicalSize(width, height));
    await window.setPosition(new PhysicalPosition(x, y));
  } catch {
    /* ignore */
  }
}

export async function persistWindowState(): Promise<void> {
  try {
    const window = getCurrentWindow();
    const [minimized, fullscreen, position, size] = await Promise.all([
      window.isMinimized(),
      window.isFullscreen(),
      window.outerPosition(),
      window.outerSize(),
    ]);
    if (minimized || fullscreen) return;
    localStorage.setItem(
      STORAGE,
      JSON.stringify({
        x: position.x,
        y: position.y,
        width: size.width,
        height: size.height,
      })
    );
  } catch {
    /* ignore */
  }
}

export async function watchWindowState(): Promise<() => void> {
  try {
    const window = getCurrentWindow();
    let timer = 0;
    const schedule = () => {
      if (timer) globalThis.clearTimeout(timer);
      timer = globalThis.setTimeout(() => {
        void persistWindowState();
      }, 300);
    };
    const unlistenResize = await window.onResized(schedule);
    const unlistenMove = await window.onMoved(schedule);
    return () => {
      if (timer) globalThis.clearTimeout(timer);
      unlistenResize();
      unlistenMove();
    };
  } catch {
    return () => {};
  }
}
