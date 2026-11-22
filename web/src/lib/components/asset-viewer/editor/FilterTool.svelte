<script lang="ts">
  import { FILTER_PRESETS, effectsManager } from '#lib/managers/edit/effects-manager.svelte.ts';
  import { Icon } from '@immich/ui';
  import { mdiCheck, mdiRefresh } from '@mdi/js';
</script>

<div class="space-y-4 px-3 py-2 text-white">
  <!-- Top bar with reset -->
  <div class="flex items-center justify-between border-b border-white/10 pb-3">
    <span class="text-xs font-semibold text-neutral-300">Preset Filters</span>
    <button
      type="button"
      onclick={() => effectsManager.resetFilters()}
      disabled={!effectsManager.hasFilterChanges}
      class="flex items-center gap-1 text-xs text-neutral-400 hover:text-white transition-colors cursor-pointer disabled:opacity-40 disabled:pointer-events-none"
    >
      <Icon icon={mdiRefresh} size="14" />
      <span>Reset</span>
    </button>
  </div>

  <!-- Filter Grid -->
  <div class="grid grid-cols-3 gap-2.5">
    {#each FILTER_PRESETS as preset (preset.id)}
      <button
        type="button"
        onclick={() => (effectsManager.selectedFilterId = preset.id)}
        class="group flex flex-col items-center gap-1.5 p-1.5 rounded-xl border transition-all cursor-pointer {effectsManager.selectedFilterId === preset.id
          ? 'border-sky-400 bg-sky-500/15 shadow-sm shadow-sky-500/20'
          : 'border-white/10 bg-white/5 hover:border-white/25 hover:bg-white/10'}"
      >
        <!-- Filter preview swatch -->
        <div class="relative w-full h-14 rounded-lg overflow-hidden bg-gradient-to-br {preset.previewBg} shadow-inner flex items-center justify-center transition-transform group-hover:scale-102">
          {#if effectsManager.selectedFilterId === preset.id}
            <div class="flex size-5 items-center justify-center rounded-full bg-sky-500 text-white shadow-md">
              <Icon icon={mdiCheck} size="14" />
            </div>
          {/if}
        </div>
        <span class="text-[11px] font-medium truncate w-full text-center {effectsManager.selectedFilterId === preset.id ? 'text-sky-300 font-semibold' : 'text-neutral-300'}">
          {preset.name}
        </span>
      </button>
    {/each}
  </div>

  <!-- Intensity slider (when a filter is active) -->
  {#if effectsManager.selectedFilterId !== 'original'}
    <div class="mt-4 pt-3 border-t border-white/10 space-y-1.5">
      <div class="flex items-center justify-between text-xs text-neutral-300">
        <span>Intensity</span>
        <span class="font-mono text-[11px] text-neutral-400">{effectsManager.filterIntensity}%</span>
      </div>
      <input
        type="range"
        min="0"
        max="100"
        bind:value={effectsManager.filterIntensity}
        class="w-full accent-sky-400 h-1.5 bg-white/15 rounded-full cursor-pointer appearance-none"
      />
    </div>
  {/if}
</div>
