import { mediaQueryManager } from '#lib/stores/media-query-manager.svelte.ts';

export type SidebarMode = 'expanded' | 'collapsed' | 'hidden';

export const DEFAULT_SIDEBAR_WIDTH = 240;
export const MIN_SIDEBAR_WIDTH = 180;
export const MAX_SIDEBAR_WIDTH = 420;
export const RAIL_SIDEBAR_WIDTH = 68;

const STORAGE_KEY_MODE = 'immich_sidebar_mode';
const STORAGE_KEY_WIDTH = 'immich_sidebar_width';

class SidebarStore {
  private _mode = $state<SidebarMode>('expanded');
  private _width = $state<number>(DEFAULT_SIDEBAR_WIDTH);
  private _mobileOpen = $state<boolean>(false);

  constructor() {
    if (typeof window !== 'undefined') {
      const savedMode = localStorage.getItem(STORAGE_KEY_MODE) as SidebarMode | null;
      if (savedMode === 'expanded' || savedMode === 'collapsed' || savedMode === 'hidden') {
        this._mode = savedMode;
      }
      const savedWidth = localStorage.getItem(STORAGE_KEY_WIDTH);
      if (savedWidth) {
        const parsed = parseInt(savedWidth, 10);
        if (!isNaN(parsed) && parsed >= MIN_SIDEBAR_WIDTH && parsed <= MAX_SIDEBAR_WIDTH) {
          this._width = parsed;
        }
      }
    }
  }

  get mode(): SidebarMode {
    return this._mode;
  }

  get width(): number {
    return this._width;
  }

  get isExpanded(): boolean {
    return mediaQueryManager.isFullSidebar ? this._mode === 'expanded' : this._mobileOpen;
  }

  get isCollapsed(): boolean {
    return mediaQueryManager.isFullSidebar && this._mode === 'collapsed';
  }

  get isHidden(): boolean {
    return mediaQueryManager.isFullSidebar ? this._mode === 'hidden' : !this._mobileOpen;
  }

  get isOpen(): boolean {
    return mediaQueryManager.isFullSidebar ? this._mode !== 'hidden' : this._mobileOpen;
  }

  set isOpen(value: boolean) {
    if (mediaQueryManager.isFullSidebar) {
      this.setMode(value ? 'expanded' : 'hidden');
    } else {
      this._mobileOpen = value;
    }
  }

  get currentWidthPx(): number {
    if (!mediaQueryManager.isFullSidebar) {
      return this._mobileOpen ? 256 : 0;
    }
    if (this._mode === 'hidden') {
      return 0;
    }
    if (this._mode === 'collapsed') {
      return RAIL_SIDEBAR_WIDTH;
    }
    return this._width;
  }

  setMode(mode: SidebarMode) {
    this._mode = mode;
    if (typeof window !== 'undefined') {
      try {
        localStorage.setItem(STORAGE_KEY_MODE, mode);
      } catch {}
    }
  }

  setWidth(width: number) {
    const clamped = Math.min(MAX_SIDEBAR_WIDTH, Math.max(MIN_SIDEBAR_WIDTH, Math.round(width)));
    this._width = clamped;
    if (typeof window !== 'undefined') {
      try {
        localStorage.setItem(STORAGE_KEY_WIDTH, clamped.toString());
      } catch {}
    }
  }

  resetWidth() {
    this.setWidth(DEFAULT_SIDEBAR_WIDTH);
  }

  reset() {
    if (!mediaQueryManager.isFullSidebar) {
      this._mobileOpen = false;
    } else {
      this.setMode('expanded');
    }
  }

  toggle() {
    if (!mediaQueryManager.isFullSidebar) {
      this._mobileOpen = !this._mobileOpen;
      return;
    }
    if (this._mode === 'expanded') {
      this.setMode('collapsed');
    } else if (this._mode === 'collapsed') {
      this.setMode('expanded');
    } else {
      this.setMode('expanded');
    }
  }

  cycleMode() {
    if (!mediaQueryManager.isFullSidebar) {
      this._mobileOpen = !this._mobileOpen;
      return;
    }
    if (this._mode === 'expanded') {
      this.setMode('collapsed');
    } else if (this._mode === 'collapsed') {
      this.setMode('hidden');
    } else {
      this.setMode('expanded');
    }
  }
}

export const sidebarStore = new SidebarStore();
