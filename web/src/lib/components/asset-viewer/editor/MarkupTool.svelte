<script lang="ts">
  import { effectsManager } from '#lib/managers/edit/effects-manager.svelte.ts';
  import { Icon } from '@immich/ui';
  import {
    mdiBrush,
    mdiDeleteOutline,
    mdiEraser,
    mdiMarker,
    mdiRedo,
    mdiUndo,
  } from '@mdi/js';

  const COLOR_PALETTE = [
    { label: 'White', color: '#ffffff' },
    { label: 'Yellow', color: '#facc15' },
    { label: 'Orange', color: '#fb923c' },
    { label: 'Red', color: '#ef4444' },
    { label: 'Pink', color: '#f472b6' },
    { label: 'Purple', color: '#a855f7' },
    { label: 'Sky Blue', color: '#38bdf8' },
    { label: 'Blue', color: '#3b82f6' },
    { label: 'Green', color: '#22c55e' },
    { label: 'Black', color: '#000000' },
  ];
</script>

<div class="space-y-4 px-3 py-2 text-white">
  <!-- Markup Tool Selector: Pen, Highlighter, Eraser -->
  <div class="grid grid-cols-3 gap-2">
    <button
      type="button"
      onclick={() => (effectsManager.markupTool = 'pen')}
      class="flex flex-col items-center gap-1.5 p-2 rounded-xl border transition-all cursor-pointer {effectsManager.markupTool === 'pen'
        ? 'border-sky-400 bg-sky-500/15 text-sky-300 font-semibold shadow-xs'
        : 'border-white/10 bg-white/5 text-neutral-400 hover:text-white hover:bg-white/10'}"
    >
      <Icon icon={mdiBrush} size="20" />
      <span class="text-xs">Pen</span>
    </button>

    <button
      type="button"
      onclick={() => (effectsManager.markupTool = 'highlighter')}
      class="flex flex-col items-center gap-1.5 p-2 rounded-xl border transition-all cursor-pointer {effectsManager.markupTool === 'highlighter'
        ? 'border-sky-400 bg-sky-500/15 text-sky-300 font-semibold shadow-xs'
        : 'border-white/10 bg-white/5 text-neutral-400 hover:text-white hover:bg-white/10'}"
    >
      <Icon icon={mdiMarker} size="20" />
      <span class="text-xs">Highlighter</span>
    </button>

    <button
      type="button"
      onclick={() => (effectsManager.markupTool = 'eraser')}
      class="flex flex-col items-center gap-1.5 p-2 rounded-xl border transition-all cursor-pointer {effectsManager.markupTool === 'eraser'
        ? 'border-sky-400 bg-sky-500/15 text-sky-300 font-semibold shadow-xs'
        : 'border-white/10 bg-white/5 text-neutral-400 hover:text-white hover:bg-white/10'}"
    >
      <Icon icon={mdiEraser} size="20" />
      <span class="text-xs">Eraser</span>
    </button>
  </div>

  <!-- Color Palette (when not erasing) -->
  {#if effectsManager.markupTool !== 'eraser'}
    <div class="space-y-2 pt-2 border-t border-white/10">
      <span class="text-xs font-semibold text-neutral-300">Color</span>
      <div class="grid grid-cols-5 gap-2.5">
        {#each COLOR_PALETTE as item (item.color)}
          <button
            type="button"
            onclick={() => (effectsManager.markupColor = item.color)}
            class="size-8 rounded-full border-2 transition-transform active:scale-90 cursor-pointer shadow-sm flex items-center justify-center {effectsManager.markupColor === item.color ? 'border-white scale-110 shadow-md ring-2 ring-sky-400/50' : 'border-white/20 hover:scale-105'}"
            style="background-color: {item.color};"
            title={item.label}
          >
            {#if effectsManager.markupColor === item.color}
              <div class="size-2 rounded-full {item.color === '#ffffff' ? 'bg-black' : 'bg-white'}"></div>
            {/if}
          </button>
        {/each}
      </div>
    </div>
  {/if}

  <!-- Stroke Thickness -->
  <div class="space-y-1.5 pt-2 border-t border-white/10">
    <div class="flex items-center justify-between text-xs text-neutral-300">
      <span>Thickness</span>
      <span class="font-mono text-[11px] text-neutral-400">{effectsManager.markupWidth}px</span>
    </div>
    <input
      type="range"
      min="2"
      max="32"
      bind:value={effectsManager.markupWidth}
      class="w-full accent-sky-400 h-1.5 bg-white/15 rounded-full cursor-pointer appearance-none"
    />
  </div>

  <!-- History & Clear -->
  <div class="flex items-center justify-between pt-3 border-t border-white/10">
    <div class="flex items-center gap-1.5">
      <button
        type="button"
        onclick={() => effectsManager.undoStroke()}
        disabled={effectsManager.strokes.length === 0}
        class="flex size-8 items-center justify-center rounded-lg bg-white/5 hover:bg-white/10 text-neutral-300 hover:text-white transition-colors cursor-pointer disabled:opacity-30 disabled:pointer-events-none"
        title="Undo"
      >
        <Icon icon={mdiUndo} size="18" />
      </button>

      <button
        type="button"
        onclick={() => effectsManager.redoStroke()}
        disabled={effectsManager.undoneStrokes.length === 0}
        class="flex size-8 items-center justify-center rounded-lg bg-white/5 hover:bg-white/10 text-neutral-300 hover:text-white transition-colors cursor-pointer disabled:opacity-30 disabled:pointer-events-none"
        title="Redo"
      >
        <Icon icon={mdiRedo} size="18" />
      </button>
    </div>

    <button
      type="button"
      onclick={() => effectsManager.resetMarkup()}
      disabled={effectsManager.strokes.length === 0}
      class="flex items-center gap-1 text-xs text-red-400 hover:text-red-300 transition-colors cursor-pointer disabled:opacity-30 disabled:pointer-events-none"
    >
      <Icon icon={mdiDeleteOutline} size="16" />
      <span>Clear all</span>
    </button>
  </div>
</div>
