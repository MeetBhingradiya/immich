export type EditorMode = 'crop' | 'adjustment' | 'filter' | 'markup';

export interface MarkupPoint {
  x: number;
  y: number;
}

export interface MarkupStroke {
  tool: 'pen' | 'highlighter' | 'eraser';
  color: string;
  width: number;
  points: MarkupPoint[];
}

export interface FilterPreset {
  id: string;
  name: string;
  cssFilter: string;
  previewBg: string;
}

export const FILTER_PRESETS: FilterPreset[] = [
  { id: 'original', name: 'Original', cssFilter: 'none', previewBg: 'from-neutral-700 to-neutral-900' },
  { id: 'vivid', name: 'Vivid', cssFilter: 'contrast(1.25) saturate(1.4) brightness(1.05)', previewBg: 'from-blue-500 to-amber-500' },
  { id: 'warm', name: 'Warm Sun', cssFilter: 'sepia(0.25) saturate(1.2) brightness(1.05) hue-rotate(-10deg)', previewBg: 'from-amber-400 to-orange-600' },
  { id: 'cool', name: 'Cool Breeze', cssFilter: 'saturate(1.1) brightness(1.02) hue-rotate(180deg) invert(0.05)', previewBg: 'from-cyan-400 to-blue-600' },
  { id: 'dramatic', name: 'Dramatic B&W', cssFilter: 'grayscale(1) contrast(1.5) brightness(1.05)', previewBg: 'from-neutral-100 to-neutral-950' },
  { id: 'noir', name: 'Noir Film', cssFilter: 'grayscale(0.85) sepia(0.2) contrast(1.3) brightness(0.95)', previewBg: 'from-neutral-300 to-stone-900' },
  { id: 'golden', name: 'Golden Hour', cssFilter: 'sepia(0.35) saturate(1.3) brightness(1.1) contrast(1.1)', previewBg: 'from-yellow-400 to-amber-600' },
  { id: 'pastel', name: 'Pastel Glow', cssFilter: 'saturate(0.8) brightness(1.15) contrast(0.95)', previewBg: 'from-pink-300 to-indigo-300' },
  { id: 'cyberpunk', name: 'Cyberpunk', cssFilter: 'hue-rotate(270deg) contrast(1.3) saturate(1.6)', previewBg: 'from-fuchsia-600 to-cyan-500' },
];

export class EffectsManager {
  activeMode = $state<EditorMode>('crop');

  // Adjustments (-100 to 100, default 0)
  brightness = $state<number>(0);
  contrast = $state<number>(0);
  saturation = $state<number>(0);
  exposure = $state<number>(0);
  warmth = $state<number>(0);
  vignette = $state<number>(0);

  // Filters
  selectedFilterId = $state<string>('original');
  filterIntensity = $state<number>(100);

  // Markup
  markupTool = $state<'pen' | 'highlighter' | 'eraser'>('pen');
  markupColor = $state<string>('#ffffff');
  markupWidth = $state<number>(4);
  strokes = $state<MarkupStroke[]>([]);
  undoneStrokes = $state<MarkupStroke[]>([]);

  hasAdjustmentChanges = $derived(
    this.brightness !== 0 ||
      this.contrast !== 0 ||
      this.saturation !== 0 ||
      this.exposure !== 0 ||
      this.warmth !== 0 ||
      this.vignette !== 0,
  );

  hasFilterChanges = $derived(this.selectedFilterId !== 'original');
  hasMarkupChanges = $derived(this.strokes.length > 0);

  hasAnyEffectsChanges = $derived(
    this.hasAdjustmentChanges || this.hasFilterChanges || this.hasMarkupChanges,
  );

  cssFilter = $derived.by(() => {
    const parts: string[] = [];

    // Base adjustments
    const b = 1 + (this.brightness + this.exposure) / 100;
    const c = 1 + this.contrast / 100;
    const s = 1 + this.saturation / 100;

    if (b !== 1) parts.push(`brightness(${b.toFixed(2)})`);
    if (c !== 1) parts.push(`contrast(${c.toFixed(2)})`);
    if (s !== 1) parts.push(`saturate(${s.toFixed(2)})`);

    if (this.warmth > 0) {
      parts.push(`sepia(${(this.warmth / 200).toFixed(2)})`);
    } else if (this.warmth < 0) {
      parts.push(`hue-rotate(${Math.round(this.warmth * 0.5)}deg)`);
    }

    // Preset filter
    if (this.selectedFilterId !== 'original') {
      const preset = FILTER_PRESETS.find((p) => p.id === this.selectedFilterId);
      if (preset && preset.cssFilter !== 'none') {
        parts.push(preset.cssFilter);
      }
    }

    return parts.length > 0 ? parts.join(' ') : 'none';
  });

  resetAdjustments() {
    this.brightness = 0;
    this.contrast = 0;
    this.saturation = 0;
    this.exposure = 0;
    this.warmth = 0;
    this.vignette = 0;
  }

  autoEnhance() {
    this.brightness = 8;
    this.contrast = 15;
    this.saturation = 20;
    this.exposure = 5;
    this.warmth = 5;
  }

  resetFilters() {
    this.selectedFilterId = 'original';
    this.filterIntensity = 100;
  }

  resetMarkup() {
    this.strokes = [];
    this.undoneStrokes = [];
  }

  resetAll() {
    this.resetAdjustments();
    this.resetFilters();
    this.resetMarkup();
    this.activeMode = 'crop';
  }

  undoStroke() {
    if (this.strokes.length > 0) {
      const popped = this.strokes[this.strokes.length - 1];
      this.strokes = this.strokes.slice(0, -1);
      this.undoneStrokes = [...this.undoneStrokes, popped];
    }
  }

  redoStroke() {
    if (this.undoneStrokes.length > 0) {
      const restored = this.undoneStrokes[this.undoneStrokes.length - 1];
      this.undoneStrokes = this.undoneStrokes.slice(0, -1);
      this.strokes = [...this.strokes, restored];
    }
  }

  addStroke(stroke: MarkupStroke) {
    this.strokes = [...this.strokes, stroke];
    this.undoneStrokes = [];
  }
}

export const effectsManager = new EffectsManager();
