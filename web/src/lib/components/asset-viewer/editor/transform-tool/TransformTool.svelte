<script lang="ts">
  import { transformManager } from '#lib/managers/edit/transform-manager.svelte.ts';
  import { Icon, shortcuts } from '@immich/ui';
  import { mdiFlipHorizontal, mdiFlipVertical, mdiRotateLeft, mdiRotateRight } from '@mdi/js';
  import { t } from 'svelte-i18n';

  interface AspectRatioOption {
    label: string;
    value: string;
    width?: number;
    height?: number;
    isFree?: boolean;
  }

  const aspectRatios: AspectRatioOption[] = [
    { label: $t('crop_aspect_ratio_free'), value: 'free', isFree: true },
    { label: $t('crop_aspect_ratio_original'), value: 'original', width: 24, height: 18 },
    { label: '5:4', value: '5:4', width: 22, height: 18 },
    { label: '4:5', value: '4:5', width: 18, height: 22 },
    { label: '4:3', value: '4:3', width: 24, height: 18 },
    { label: '3:4', value: '3:4', width: 18, height: 24 },
    { label: '3:2', value: '3:2', width: 24, height: 16 },
    { label: '2:3', value: '2:3', width: 16, height: 24 },
    { label: '16:9', value: '16:9', width: 24, height: 14 },
    { label: '9:16', value: '9:16', width: 14, height: 24 },
    { label: $t('crop_aspect_ratio_square'), value: '1:1', width: 20, height: 20 },
  ];

  let isRotated = $derived(transformManager.normalizedRotation % 180 !== 0);

  function rotatedRatio(ratio: AspectRatioOption): string {
    if (ratio.value === 'free') {
      return ratio.value;
    }

    if (isRotated) {
      let [width, height] = ratio.value.split(':', 2);
      return `${height}:${width}`;
    }
    return ratio.value;
  }

  function ratioSelected(ratio: AspectRatioOption): boolean {
    const currentRatioRotated = rotatedRatio(ratio);

    return transformManager.cropAspectRatio === currentRatioRotated;
  }

  function selectAspectRatio(ratio: AspectRatioOption) {
    let appliedRatio;
    if (ratio.value === 'original') {
      const { width, height } = transformManager.cropImageSize;
      appliedRatio = `${width}:${height}`;
    } else {
      appliedRatio = rotatedRatio(ratio);
    }

    transformManager.setAspectRatio(appliedRatio);
  }

  async function rotateImage(degrees: number) {
    await transformManager.rotate(degrees);
  }

  function mirrorImage(axis: 'horizontal' | 'vertical') {
    transformManager.mirror(axis);
  }
</script>

<svelte:window
  {@attach shortcuts([
    { shortcut: { key: ']' }, onShortcut: () => rotateImage(90) },
    { shortcut: { key: '[' }, onShortcut: () => rotateImage(-90) },
  ])}
/>

<div class="mt-3 px-4">
  <div class="flex h-9 w-full items-center justify-between text-xs font-semibold uppercase tracking-wider text-neutral-400">
    <h2>{$t('editor_orientation')}</h2>
  </div>

  <div class="grid grid-cols-4 gap-2 mt-1">
    <button
      type="button"
      class="flex size-10 w-full items-center justify-center rounded-xl bg-white/5 hover:bg-white/10 border border-white/10 hover:border-white/20 text-neutral-300 hover:text-white transition-all active:scale-95 cursor-pointer"
      title={$t('editor_rotate_left')}
      onclick={() => rotateImage(-90)}
    >
      <Icon icon={mdiRotateLeft} size="20" />
    </button>
    <button
      type="button"
      class="flex size-10 w-full items-center justify-center rounded-xl bg-white/5 hover:bg-white/10 border border-white/10 hover:border-white/20 text-neutral-300 hover:text-white transition-all active:scale-95 cursor-pointer"
      title={$t('editor_rotate_right')}
      onclick={() => rotateImage(90)}
    >
      <Icon icon={mdiRotateRight} size="20" />
    </button>
    <button
      type="button"
      class="flex size-10 w-full items-center justify-center rounded-xl bg-white/5 hover:bg-white/10 border border-white/10 hover:border-white/20 text-neutral-300 hover:text-white transition-all active:scale-95 cursor-pointer"
      title={$t('editor_flip_horizontal')}
      onclick={() => mirrorImage('horizontal')}
    >
      <Icon icon={mdiFlipHorizontal} size="20" />
    </button>
    <button
      type="button"
      class="flex size-10 w-full items-center justify-center rounded-xl bg-white/5 hover:bg-white/10 border border-white/10 hover:border-white/20 text-neutral-300 hover:text-white transition-all active:scale-95 cursor-pointer"
      title={$t('editor_flip_vertical')}
      onclick={() => mirrorImage('vertical')}
    >
      <Icon icon={mdiFlipVertical} size="20" />
    </button>
  </div>

  <!-- Straighten Angle Scrubber Preview (OneDrive style) -->
  <div class="mt-4 p-3 rounded-2xl bg-white/5 border border-white/10 flex flex-col items-center justify-center">
    <div class="flex items-center justify-between w-full text-xs text-neutral-400 mb-2">
      <span>Straighten</span>
      <span class="font-mono font-semibold text-white">{transformManager.normalizedRotation}°</span>
    </div>
    <div class="w-full flex items-center justify-between gap-1 text-[10px] text-neutral-500 font-mono px-1">
      <span>-90°</span>
      <div class="flex-1 mx-2 h-1 bg-white/10 rounded-full overflow-hidden relative">
        <div class="absolute inset-y-0 left-1/2 w-0.5 bg-sky-400 -translate-x-1/2"></div>
      </div>
      <span>+90°</span>
    </div>
  </div>

  <div class="mt-6 flex h-9 w-full items-center justify-between text-xs font-semibold uppercase tracking-wider text-neutral-400">
    <h2>{$t('crop')} ({aspectRatios.length})</h2>
  </div>

  <!-- Aspect Ratio Grid (OneDrive style sleek tiles) -->
  <div class="mb-4 grid grid-cols-2 gap-2 mt-1">
    {#each aspectRatios as ratio (ratio.value)}
      <button
        type="button"
        onclick={() => selectAspectRatio(ratio)}
        class="flex items-center gap-2.5 p-2.5 rounded-xl border transition-all text-left cursor-pointer {ratioSelected(ratio)
          ? 'bg-sky-500/15 border-sky-400/50 text-white shadow-xs'
          : 'bg-white/5 border-white/10 hover:bg-white/10 hover:border-white/20 text-neutral-300 hover:text-white'}"
      >
        <div class="flex size-7 shrink-0 items-center justify-center rounded-lg bg-black/40 border border-white/10">
          {#if ratio.isFree}
            <div class="size-4 rounded-xs border border-dashed border-white"></div>
          {:else}
            <div
              class="rounded-xs border border-white"
              style="width: {Math.min(18, (ratio.width || 18) * 0.75)}px; height: {Math.min(18, (ratio.height || 18) * 0.75)}px;"
            ></div>
          {/if}
        </div>
        <span class="text-xs font-medium truncate">{ratio.label}</span>
      </button>
    {/each}
  </div>
</div>
