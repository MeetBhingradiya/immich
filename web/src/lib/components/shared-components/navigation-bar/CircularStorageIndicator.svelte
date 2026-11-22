<script lang="ts">
  import { clickOutside } from '#lib/actions/click-outside.ts';
  import { authManager } from '#lib/managers/auth-manager.svelte.ts';
  import { getStorageQuery } from '#lib/queries/server-info.query.ts';
  import { Route } from '#lib/route.ts';
  import { locale } from '#lib/stores/preferences.store.ts';
  import { getByteUnitString } from '#lib/utils/byte-units.ts';
  import { Icon } from '@immich/ui';
  import { mdiCloudCheckOutline, mdiHarddisk, mdiServerNetwork } from '@mdi/js';
  import { createQuery } from '@tanstack/svelte-query';
  import { fade, scale } from 'svelte/transition';

  const query = createQuery(getStorageQuery);
  const serverInfo = $derived(query.data);

  let showPopover = $state(false);

  let hasQuota = $derived(authManager.user.quotaSizeInBytes !== null);
  let availableBytes = $derived(
    (hasQuota && authManager.authenticated ? authManager.user.quotaSizeInBytes : serverInfo?.diskSizeRaw) || 0,
  );
  let usedBytes = $derived(
    (hasQuota && authManager.authenticated ? authManager.user.quotaUsageInBytes : serverInfo?.diskUseRaw) || 0,
  );

  let ratio = $derived(availableBytes > 0 ? Math.min(1, Math.max(0, usedBytes / availableBytes)) : 0);
  let percentage = $derived(Math.round(ratio * 100));

  // Circular gauge math: radius 13 -> circumference ~81.68
  const radius = 13;
  const circumference = 2 * Math.PI * radius;
  let strokeDashoffset = $derived(circumference - ratio * circumference);

  // Dynamic stroke color matching Google Photos (blue -> amber -> red)
  let ringColor = $derived(
    percentage >= 90 ? '#EF4444' : percentage >= 75 ? '#F59E0B' : '#3B82F6',
  );
</script>

<div
  class="relative inline-flex items-center"
  use:clickOutside={{ onOutclick: () => (showPopover = false), onEscape: () => (showPopover = false) }}
>
  <!-- Circular Gauge Button (Google Photos Style) -->
  <button
    type="button"
    onclick={() => (showPopover = !showPopover)}
    class="group relative flex size-9 items-center justify-center rounded-full hover:bg-white/10 transition-all duration-200 cursor-pointer focus:outline-none"
    title="Storage: {getByteUnitString(usedBytes, $locale, 1)} of {getByteUnitString(availableBytes, $locale, 1)} ({percentage}%)"
    aria-label="Storage info"
  >
    <svg class="size-7 -rotate-90 transform" viewBox="0 0 32 32">
      <!-- Background track -->
      <circle
        cx="16"
        cy="16"
        r={radius}
        class="stroke-white/10"
        stroke-width="3"
        fill="transparent"
      />
      <!-- Progress circle -->
      <circle
        cx="16"
        cy="16"
        r={radius}
        stroke={ringColor}
        stroke-width="3"
        stroke-dasharray={circumference}
        stroke-dashoffset={strokeDashoffset}
        stroke-linecap="round"
        fill="transparent"
        class="transition-all duration-500 ease-out"
      />
    </svg>

    <!-- Center Icon -->
    <span class="absolute inset-0 flex items-center justify-center text-[10px] font-bold text-neutral-300 group-hover:text-white transition-colors">
      <Icon icon={mdiCloudCheckOutline} size="14px" class="text-neutral-400 group-hover:text-blue-400 transition-colors" />
    </span>
  </button>

  <!-- Google Photos Style Storage Popover -->
  {#if showPopover}
    <div
      transition:scale={{ start: 0.95, duration: 180 }}
      class="absolute right-0 top-12 z-50 w-72 rounded-3xl border border-white/15 bg-neutral-900/95 p-5 text-white shadow-2xl backdrop-blur-2xl"
      role="dialog"
      aria-label="Storage Info"
    >
      <div class="mb-3 flex items-center justify-between">
        <div class="flex items-center gap-2">
          <Icon icon={mdiHarddisk} size="18px" class="text-blue-400" />
          <h4 class="text-xs font-semibold tracking-tight text-neutral-200">Account Storage</h4>
        </div>
        <span class="rounded-full bg-blue-500/15 px-2 py-0.5 text-[10px] font-semibold text-blue-400 border border-blue-500/20">
          {percentage}%
        </span>
      </div>

      <div class="mb-2">
        <p class="text-base font-bold tracking-tight text-white">
          {getByteUnitString(usedBytes, $locale, 2)}
          <span class="text-xs font-normal text-neutral-400">of {getByteUnitString(availableBytes, $locale, 2)}</span>
        </p>
      </div>

      <!-- Linear progress bar -->
      <div class="mb-4 h-2 w-full overflow-hidden rounded-full bg-neutral-800">
        <div
          class="h-full rounded-full transition-all duration-500"
          style="width: {percentage}%; background-color: {ringColor};"
        ></div>
      </div>

      <div class="space-y-2 border-t border-white/10 pt-3 text-[11px] text-neutral-400">
        <div class="flex items-center justify-between">
          <span class="flex items-center gap-1.5">
            <Icon icon={mdiServerNetwork} size="14px" class="text-emerald-400" />
            Private High-Speed Pool
          </span>
          <span class="font-medium text-emerald-400">Active</span>
        </div>
      </div>

      <div class="mt-4 flex justify-end">
        <a
          href={Route.userSettings()}
          onclick={() => (showPopover = false)}
          class="text-xs font-medium text-blue-400 hover:text-blue-300 transition-colors"
        >
          Manage storage →
        </a>
      </div>
    </div>
  {/if}
</div>
