<script lang="ts">
  import { clickOutside } from '#lib/actions/click-outside.ts';
  import { Route } from '#lib/route.ts';
  import { Button, Icon, IconButton } from '@immich/ui';
  import {
    mdiCheckDecagram,
    mdiClose,
    mdiDatabaseSyncOutline,
    mdiDiamondStone,
    mdiHarddisk,
    mdiShieldCheckOutline,
  } from '@mdi/js';
  import { fade, scale } from 'svelte/transition';

  type Props = {
    onClose: () => void;
  };

  let { onClose }: Props = $props();
</script>

<!-- Backdrop -->
<div
  transition:fade={{ duration: 150 }}
  class="fixed inset-0 z-50 bg-black/50 backdrop-blur-xs"
  onclick={onClose}
  role="presentation"
></div>

<!-- Modal Container -->
<div
  transition:scale={{ start: 0.95, duration: 200 }}
  use:clickOutside={{ onOutclick: onClose, onEscape: onClose }}
  class="fixed top-1/2 left-1/2 z-50 w-full max-w-md -translate-x-1/2 -translate-y-1/2 rounded-3xl border border-white/15 bg-neutral-900/95 p-6 text-white shadow-2xl backdrop-blur-2xl"
  role="dialog"
  aria-label="Storage & Plan Details"
>
  <div class="mb-5 flex items-start justify-between">
    <div class="flex items-center gap-3">
      <div class="flex size-10 items-center justify-center rounded-2xl bg-gradient-to-tr from-purple-600 via-indigo-600 to-pink-500 text-white shadow-lg">
        <Icon icon={mdiDiamondStone} size="24px" />
      </div>
      <div>
        <h2 class="text-base font-bold tracking-tight">OneDrive Luxury Cloud</h2>
        <div class="flex items-center gap-1.5 mt-0.5">
          <span class="inline-flex items-center gap-1 text-[11px] font-semibold text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded-full border border-emerald-500/20">
            <Icon icon={mdiCheckDecagram} size="13px" />
            Supporter Unlocked
          </span>
          <span class="text-[11px] text-neutral-400">Server & Individual</span>
        </div>
      </div>
    </div>
    <IconButton
      icon={mdiClose}
      size="small"
      shape="round"
      color="secondary"
      variant="ghost"
      onclick={onClose}
      aria-label="Close"
    />
  </div>

  <!-- Storage Meter Section -->
  <div class="mb-5 rounded-2xl border border-white/10 bg-white/5 p-4">
    <div class="flex items-center justify-between text-xs mb-2">
      <span class="flex items-center gap-1.5 text-neutral-300 font-medium">
        <Icon icon={mdiHarddisk} size="16px" class="text-blue-400" />
        High-Speed Storage Pool
      </span>
      <span class="font-bold text-white">Unlimited / Private Host</span>
    </div>
    <div class="h-2 w-full overflow-hidden rounded-full bg-neutral-800">
      <div class="h-full rounded-full bg-gradient-to-r from-blue-500 via-indigo-500 to-purple-500 w-[24%]"></div>
    </div>
    <p class="mt-2 text-[11px] text-neutral-400">
      Hosting 38,000+ photos & videos with zero remote telemetry or vendor lock-in.
    </p>
  </div>

  <!-- Smart Engine Section -->
  <div class="mb-5 space-y-2.5">
    <div class="flex items-center gap-3 rounded-xl border border-white/5 bg-white/5 p-3">
      <div class="flex size-8 shrink-0 items-center justify-center rounded-lg bg-blue-500/20 text-blue-400">
        <Icon icon={mdiDatabaseSyncOutline} size="18px" />
      </div>
      <div>
        <p class="text-xs font-semibold text-neutral-200">OpenAI CLIP ViT-L-14 Embeddings</p>
        <p class="text-[11px] text-neutral-400">768-dim high-accuracy semantic search active.</p>
      </div>
    </div>
    <div class="flex items-center gap-3 rounded-xl border border-white/5 bg-white/5 p-3">
      <div class="flex size-8 shrink-0 items-center justify-center rounded-lg bg-emerald-500/20 text-emerald-400">
        <Icon icon={mdiShieldCheckOutline} size="18px" />
      </div>
      <div>
        <p class="text-xs font-semibold text-neutral-200">Zero Cloud Telemetry</p>
        <p class="text-[11px] text-neutral-400">All analytics, pingbacks, and crash reporting disabled.</p>
      </div>
    </div>
  </div>

  <div class="flex items-center justify-end gap-2 border-t border-white/10 pt-4">
    <Button variant="ghost" size="small" color="secondary" onclick={onClose}>
      Dismiss
    </Button>
    <Button
      variant="solid"
      size="small"
      color="primary"
      href={Route.userSettings()}
      onclick={onClose}
    >
      Storage Settings
    </Button>
  </div>
</div>
