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

<section class="dark relative flex h-full flex-col bg-[#141414]/98 backdrop-blur-2xl text-white border-s border-white/10 select-none">
  <!-- Top Bar: Save, Reset, Undo, Redo, Tabs, Cancel (OneDrive Edit Header exact match) -->
  <div class="flex items-center justify-between px-3 py-2.5 border-b border-white/10 bg-black/40">
    <!-- Left Actions -->
    <div class="flex items-center gap-1.5">
      <button
        type="button"
        onclick={applyEdits}
        disabled={editManager.isApplyingEdits}
        class="flex items-center gap-1.5 px-3.5 py-1.5 rounded-full bg-[#0078d4] hover:bg-[#106ebe] text-white font-semibold text-xs transition-all active:scale-95 shadow-sm cursor-pointer disabled:opacity-50"
      >
        <span>{$t('save')}</span>
      </button>

      <button
        type="button"
        onclick={() => {
          editManager.resetAllChanges();
          effectsManager.resetAll();
        }}
        disabled={!editManager.canReset && !effectsManager.hasAnyEffectsChanges}
        class="text-xs text-neutral-300 hover:text-white px-2 py-1.5 rounded-lg transition-colors hover:bg-white/10 cursor-pointer disabled:opacity-40 disabled:pointer-events-none"
        title="Reset all edits"
      >
        {$t('reset')}
      </button>

      <button
        type="button"
        onclick={() => effectsManager.undoStroke()}
        disabled={effectsManager.strokeHistory.length === 0}
        class="text-xs text-neutral-300 hover:text-white px-2 py-1.5 rounded-lg transition-colors hover:bg-white/10 cursor-pointer disabled:opacity-40 disabled:pointer-events-none"
        title="Undo (Ctrl + Z)"
      >
        Undo
      </button>
    </div>

    <!-- Right: Cancel Button -->
    <button
      type="button"
      class="text-xs text-neutral-300 hover:text-white px-3 py-1.5 rounded-full hover:bg-white/10 transition-colors cursor-pointer"
      onclick={closeEditor}
    >
      Cancel
    </button>
  </div>

  <!-- Tool Mode Tabs (OneDrive exact: Crop, Adjustment, Filter, Markup) -->
  <div class="flex items-center justify-around px-2 py-2 border-b border-white/10 bg-white/2 select-none">
    <button
      type="button"
      onclick={() => (effectsManager.activeMode = 'crop')}
      class="flex flex-col items-center gap-1 px-3 py-1.5 rounded-xl text-[11px] font-semibold transition-all cursor-pointer {effectsManager.activeMode === 'crop'
        ? 'text-[#0078d4] bg-white/8 shadow-xs border-b-2 border-[#0078d4]'
        : 'text-neutral-400 hover:text-white hover:bg-white/5 border-b-2 border-transparent'}"
    >
      <Icon icon={mdiCrop} size="17" />
      <span>Crop</span>
    </button>
    <button
      type="button"
      onclick={() => (effectsManager.activeMode = 'adjustment')}
      class="flex flex-col items-center gap-1 px-3 py-1.5 rounded-xl text-[11px] font-semibold transition-all cursor-pointer {effectsManager.activeMode === 'adjustment'
        ? 'text-[#0078d4] bg-white/8 shadow-xs border-b-2 border-[#0078d4]'
        : 'text-neutral-400 hover:text-white hover:bg-white/5 border-b-2 border-transparent'}"
    >
      <Icon icon={mdiTuneVariant} size="17" />
      <span>Adjustment</span>
    </button>
    <button
      type="button"
      onclick={() => (effectsManager.activeMode = 'filter')}
      class="flex flex-col items-center gap-1 px-3 py-1.5 rounded-xl text-[11px] font-semibold transition-all cursor-pointer {effectsManager.activeMode === 'filter'
        ? 'text-[#0078d4] bg-white/8 shadow-xs border-b-2 border-[#0078d4]'
        : 'text-neutral-400 hover:text-white hover:bg-white/5 border-b-2 border-transparent'}"
    >
      <Icon icon={mdiAutoFix} size="17" />
      <span>Filter</span>
    </button>
    <button
      type="button"
      onclick={() => (effectsManager.activeMode = 'markup')}
      class="flex flex-col items-center gap-1 px-3 py-1.5 rounded-xl text-[11px] font-semibold transition-all cursor-pointer {effectsManager.activeMode === 'markup'
        ? 'text-[#0078d4] bg-white/8 shadow-xs border-b-2 border-[#0078d4]'
        : 'text-neutral-400 hover:text-white hover:bg-white/5 border-b-2 border-transparent'}"
    >
      <Icon icon={mdiDraw} size="17" />
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
