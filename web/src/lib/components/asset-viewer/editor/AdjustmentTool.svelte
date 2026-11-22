<script lang="ts">
  import { effectsManager } from '#lib/managers/edit/effects-manager.svelte.ts';
  import { Icon } from '@immich/ui';
  import {
    mdiAutoFix,
    mdiBrightness6,
    mdiCircleDouble,
    mdiContrastCircle,
    mdiFormatColorFill,
    mdiRefresh,
    mdiThermometer,
    mdiWhiteBalanceSunny,
  } from '@mdi/js';
</script>

<div class="space-y-4 px-3 py-2 text-white">
  <!-- Top Quick Actions: Auto Enhance & Reset -->
  <div class="flex items-center justify-between gap-2 border-b border-white/10 pb-3">
    <button
      type="button"
      onclick={() => effectsManager.autoEnhance()}
      class="flex flex-1 items-center justify-center gap-1.5 rounded-xl bg-gradient-to-r from-sky-500/20 to-blue-600/20 px-3 py-2 text-xs font-semibold text-sky-400 border border-sky-500/30 hover:bg-sky-500/30 transition-all active:scale-95 cursor-pointer shadow-xs"
    >
      <Icon icon={mdiAutoFix} size="16" />
      <span>Auto Enhance</span>
    </button>

    <button
      type="button"
      onclick={() => effectsManager.resetAdjustments()}
      disabled={!effectsManager.hasAdjustmentChanges}
      class="flex items-center justify-center gap-1.5 rounded-xl bg-white/5 px-3 py-2 text-xs font-medium text-neutral-300 hover:text-white hover:bg-white/10 border border-white/10 transition-colors cursor-pointer disabled:opacity-40 disabled:pointer-events-none"
      title="Reset adjustments"
    >
      <Icon icon={mdiRefresh} size="16" />
      <span>Reset</span>
    </button>
  </div>

  <!-- Sliders Group -->
  <div class="space-y-3.5">
    <!-- Brightness -->
    <div class="space-y-1">
      <div class="flex items-center justify-between text-xs text-neutral-300">
        <span class="flex items-center gap-1.5 font-medium">
          <Icon icon={mdiBrightness6} size="15" class="text-amber-400" />
          <span>Brightness</span>
        </span>
        <span class="font-mono text-[11px] text-neutral-400">{effectsManager.brightness > 0 ? `+${effectsManager.brightness}` : effectsManager.brightness}</span>
      </div>
      <input
        type="range"
        min="-100"
        max="100"
        bind:value={effectsManager.brightness}
        class="w-full accent-sky-400 h-1.5 bg-white/15 rounded-full cursor-pointer appearance-none"
      />
    </div>

    <!-- Contrast -->
    <div class="space-y-1">
      <div class="flex items-center justify-between text-xs text-neutral-300">
        <span class="flex items-center gap-1.5 font-medium">
          <Icon icon={mdiContrastCircle} size="15" class="text-blue-400" />
          <span>Contrast</span>
        </span>
        <span class="font-mono text-[11px] text-neutral-400">{effectsManager.contrast > 0 ? `+${effectsManager.contrast}` : effectsManager.contrast}</span>
      </div>
      <input
        type="range"
        min="-100"
        max="100"
        bind:value={effectsManager.contrast}
        class="w-full accent-sky-400 h-1.5 bg-white/15 rounded-full cursor-pointer appearance-none"
      />
    </div>

    <!-- Saturation -->
    <div class="space-y-1">
      <div class="flex items-center justify-between text-xs text-neutral-300">
        <span class="flex items-center gap-1.5 font-medium">
          <Icon icon={mdiFormatColorFill} size="15" class="text-fuchsia-400" />
          <span>Saturation</span>
        </span>
        <span class="font-mono text-[11px] text-neutral-400">{effectsManager.saturation > 0 ? `+${effectsManager.saturation}` : effectsManager.saturation}</span>
      </div>
      <input
        type="range"
        min="-100"
        max="100"
        bind:value={effectsManager.saturation}
        class="w-full accent-sky-400 h-1.5 bg-white/15 rounded-full cursor-pointer appearance-none"
      />
    </div>

    <!-- Exposure -->
    <div class="space-y-1">
      <div class="flex items-center justify-between text-xs text-neutral-300">
        <span class="flex items-center gap-1.5 font-medium">
          <Icon icon={mdiWhiteBalanceSunny} size="15" class="text-yellow-400" />
          <span>Exposure</span>
        </span>
        <span class="font-mono text-[11px] text-neutral-400">{effectsManager.exposure > 0 ? `+${effectsManager.exposure}` : effectsManager.exposure}</span>
      </div>
      <input
        type="range"
        min="-100"
        max="100"
        bind:value={effectsManager.exposure}
        class="w-full accent-sky-400 h-1.5 bg-white/15 rounded-full cursor-pointer appearance-none"
      />
    </div>

    <!-- Warmth / Temperature -->
    <div class="space-y-1">
      <div class="flex items-center justify-between text-xs text-neutral-300">
        <span class="flex items-center gap-1.5 font-medium">
          <Icon icon={mdiThermometer} size="15" class="text-orange-400" />
          <span>Warmth</span>
        </span>
        <span class="font-mono text-[11px] text-neutral-400">{effectsManager.warmth > 0 ? `+${effectsManager.warmth}` : effectsManager.warmth}</span>
      </div>
      <input
        type="range"
        min="-100"
        max="100"
        bind:value={effectsManager.warmth}
        class="w-full accent-sky-400 h-1.5 bg-white/15 rounded-full cursor-pointer appearance-none"
      />
    </div>

    <!-- Vignette -->
    <div class="space-y-1">
      <div class="flex items-center justify-between text-xs text-neutral-300">
        <span class="flex items-center gap-1.5 font-medium">
          <Icon icon={mdiCircleDouble} size="15" class="text-neutral-400" />
          <span>Vignette</span>
        </span>
        <span class="font-mono text-[11px] text-neutral-400">{effectsManager.vignette}%</span>
      </div>
      <input
        type="range"
        min="0"
        max="100"
        bind:value={effectsManager.vignette}
        class="w-full accent-sky-400 h-1.5 bg-white/15 rounded-full cursor-pointer appearance-none"
      />
    </div>
  </div>
</div>
