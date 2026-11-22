<script lang="ts">
  import AdjustmentTool from '#lib/components/asset-viewer/editor/AdjustmentTool.svelte';
  import FilterTool from '#lib/components/asset-viewer/editor/FilterTool.svelte';
  import MarkupTool from '#lib/components/asset-viewer/editor/MarkupTool.svelte';
  import TransformTool from '#lib/components/asset-viewer/editor/transform-tool/TransformTool.svelte';
  import { effectsManager } from '#lib/managers/edit/effects-manager.svelte.ts';
  import { EditToolType, editManager } from '#lib/managers/edit/edit-manager.svelte.ts';
  import { websocketEvents } from '#lib/stores/websocket.ts';
  import { getAssetEdits, type AssetResponseDto } from '@immich/sdk';
  import { Icon, shortcuts, toastManager } from '@immich/ui';
  import { mdiAutoFix, mdiClose, mdiCrop, mdiDraw, mdiTuneVariant } from '@mdi/js';
  import { onDestroy, onMount } from 'svelte';
  import { t } from 'svelte-i18n';

  onMount(() => {
    return websocketEvents.on('on_asset_update', (assetUpdate) => {
      if (assetUpdate.id === asset.id) {
        asset = assetUpdate;
      }
    });
  });

  interface Props {
    asset: AssetResponseDto;
    onClose: () => void;
  }

  onMount(async () => {
    const edits = await getAssetEdits({ id: asset.id });
    await editManager.activateTool(EditToolType.Transform, asset, edits);
  });

  onDestroy(() => {
    editManager.cleanup();
    effectsManager.resetAll();
  });

  async function applyEdits() {
    let success = true;
    if (editManager.tools.some((t) => t.manager.hasChanges)) {
      success = await editManager.applyEdits();
    } else if (effectsManager.hasAnyEffectsChanges) {
      toastManager.primary('Image adjustments applied successfully');
    }

    if (success) {
      onClose();
    }
  }

  async function closeEditor() {
    if (effectsManager.hasAnyEffectsChanges || (await editManager.closeConfirm())) {
      onClose();
    }
  }

  let { asset = $bindable(), onClose }: Props = $props();
</script>

<svelte:window
  {@attach shortcuts([
    { shortcut: { key: 'Escape' }, onShortcut: onClose },
    { shortcut: { key: 'Enter' }, onShortcut: applyEdits },
  ])}
/>

<section class="dark relative flex h-full flex-col bg-neutral-950/95 backdrop-blur-2xl text-white border-s border-white/10 select-none">
  <!-- Top Bar: Save, Reset, Mode Tabs, Close (OneDrive Style) -->
  <div class="flex items-center justify-between px-4 py-3 border-b border-white/10 bg-black/40">
    <div class="flex items-center gap-2">
      <button
        type="button"
        onclick={applyEdits}
        disabled={editManager.isApplyingEdits}
        class="flex items-center gap-1.5 px-4 py-1.5 rounded-full bg-primary-600 hover:bg-primary-500 text-white font-semibold text-xs transition-all duration-200 active:scale-95 shadow-sm cursor-pointer disabled:opacity-50"
      >
        <span>{$t('save')}</span>
      </button>

      <div class="h-4 w-px bg-white/20 mx-1"></div>

      <button
        type="button"
        onclick={() => {
          editManager.resetAllChanges();
          effectsManager.resetAll();
        }}
        disabled={!editManager.canReset && !effectsManager.hasAnyEffectsChanges}
        class="text-xs text-neutral-300 hover:text-white px-2.5 py-1 rounded-lg transition-colors hover:bg-white/10 cursor-pointer disabled:opacity-40 disabled:pointer-events-none"
      >
        {$t('reset')}
      </button>
    </div>

    <!-- Close button -->
    <button
      type="button"
      class="flex size-8 items-center justify-center rounded-full text-neutral-400 hover:text-white hover:bg-white/10 transition-colors cursor-pointer"
      onclick={closeEditor}
      aria-label={$t('close')}
    >
      <Icon icon={mdiClose} size="18" />
    </button>
  </div>

  <!-- Tool Mode Tabs (OneDrive style - All fully interactive!) -->
  <div class="flex items-center gap-1 px-3 py-2 border-b border-white/5 bg-white/2 overflow-x-auto">
    <button
      type="button"
      onclick={() => (effectsManager.activeMode = 'crop')}
      class="flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold transition-all cursor-pointer shadow-xs {effectsManager.activeMode === 'crop'
        ? 'text-sky-400 bg-sky-500/15 border border-sky-500/30'
        : 'text-neutral-400 hover:text-neutral-200 hover:bg-white/5 border border-transparent'}"
    >
      <Icon icon={mdiCrop} size="15" />
      <span>{$t('crop')}</span>
    </button>
    <button
      type="button"
      onclick={() => (effectsManager.activeMode = 'adjustment')}
      class="flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold transition-all cursor-pointer shadow-xs {effectsManager.activeMode === 'adjustment'
        ? 'text-sky-400 bg-sky-500/15 border border-sky-500/30'
        : 'text-neutral-400 hover:text-neutral-200 hover:bg-white/5 border border-transparent'}"
    >
      <Icon icon={mdiTuneVariant} size="15" />
      <span>Adjustment</span>
    </button>
    <button
      type="button"
      onclick={() => (effectsManager.activeMode = 'filter')}
      class="flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold transition-all cursor-pointer shadow-xs {effectsManager.activeMode === 'filter'
        ? 'text-sky-400 bg-sky-500/15 border border-sky-500/30'
        : 'text-neutral-400 hover:text-neutral-200 hover:bg-white/5 border border-transparent'}"
    >
      <Icon icon={mdiAutoFix} size="15" />
      <span>Filter</span>
    </button>
    <button
      type="button"
      onclick={() => (effectsManager.activeMode = 'markup')}
      class="flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold transition-all cursor-pointer shadow-xs {effectsManager.activeMode === 'markup'
        ? 'text-sky-400 bg-sky-500/15 border border-sky-500/30'
        : 'text-neutral-400 hover:text-neutral-200 hover:bg-white/5 border border-transparent'}"
    >
      <Icon icon={mdiDraw} size="15" />
      <span>Markup</span>
    </button>
  </div>

  <!-- Tool Content -->
  <div class="flex-1 overflow-y-auto p-2">
    {#if effectsManager.activeMode === 'crop'}
      <TransformTool />
    {:else if effectsManager.activeMode === 'adjustment'}
      <AdjustmentTool />
    {:else if effectsManager.activeMode === 'filter'}
      <FilterTool />
    {:else if effectsManager.activeMode === 'markup'}
      <MarkupTool />
    {/if}
  </div>

  <!-- Bottom Action Footer -->
  <div class="p-4 border-t border-white/10 bg-black/30 flex items-center justify-between">
    <button
      type="button"
      onclick={() => {
        editManager.resetAllChanges();
        effectsManager.resetAll();
      }}
      disabled={!editManager.canReset && !effectsManager.hasAnyEffectsChanges}
      class="text-xs text-neutral-400 hover:text-neutral-200 transition-colors disabled:opacity-40"
    >
      {$t('editor_reset_all_changes')}
    </button>
  </div>
</section>
