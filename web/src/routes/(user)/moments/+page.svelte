<script lang="ts">
  import UserPageLayout from '#lib/components/layouts/UserPageLayout.svelte';
  import MemoryCard from '#lib/components/memories/MemoryCard.svelte';
  import { assetViewerManager } from '#lib/managers/asset-viewer-manager.svelte.ts';
  import { memoryManager } from '#lib/managers/memory-manager.svelte.ts';
  import { userPreferencesManager } from '#lib/managers/user-preferences-manager.svelte.ts';
  import MemoriesSettingsModal from '#lib/modals/MemoriesSettingsModal.svelte';
  import { Route } from '#lib/route.ts';
  import { getAssetMediaUrl, memoryLaneTitle } from '#lib/utils.ts';
  import { getAltText } from '#lib/utils/thumbnail-util.ts';
  import { toTimelineAsset } from '#lib/utils/timeline-util.ts';
  import { searchRandom, type AssetResponseDto } from '@immich/sdk';
  import { Icon, IconButton, LoadingSpinner, modalManager } from '@immich/ui';
  import { mdiCreation, mdiRefresh, mdiTune } from '@mdi/js';
  import { onMount } from 'svelte';
  import { t } from 'svelte-i18n';
  import type { PageData } from './$types';

  type Props = {
    data: PageData;
  };

  const { data }: Props = $props();

  let featuredPhotos = $state<AssetResponseDto[]>([]);
  let collagePhotos = $state<AssetResponseDto[]>([]);
  let isShufflingFeatured = $state(false);
  let isShufflingCollage = $state(false);

  async function loadFeaturedPhotos() {
    isShufflingFeatured = true;
    try {
      const photos = await searchRandom({ count: 12 });
      if (photos && photos.length > 0) {
        featuredPhotos = photos.slice(0, 5);
        collagePhotos = photos.slice(5, 11);
      }
    } catch {
      const memoryAssets = memoryManager.memories.flatMap((m) => m.assets);
      featuredPhotos = memoryAssets.slice(0, 5);
      collagePhotos = memoryAssets.slice(5, 11);
    } finally {
      isShufflingFeatured = false;
    }
  }

  async function reshuffleCollage() {
    isShufflingCollage = true;
    try {
      const photos = await searchRandom({ count: 10 });
      if (photos && photos.length > 0) {
        collagePhotos = photos.slice(0, 6);
      }
    } catch {
      // Fallback
    } finally {
      isShufflingCollage = false;
    }
  }

  onMount(async () => {
    await loadFeaturedPhotos();
  });

  const handleSettings = async () => {
    const settings = await modalManager.show(MemoriesSettingsModal);
    if (!settings) {
      return;
    }

    userPreferencesManager.memories = settings;
    await memoryManager.applyPreferences();
  };

  // Card transform styles for 5 fanned-out 3D cards (OneDrive exact geometry)
  const ARC_CARD_STYLES = [
    { rotate: '-6deg', translateY: '20px', scale: '0.88', zIndex: '8' },
    { rotate: '-3deg', translateY: '10px', scale: '0.94', zIndex: '9' },
    { rotate: '0deg', translateY: '0px', scale: '1.02', zIndex: '10' },
    { rotate: '3deg', translateY: '10px', scale: '0.94', zIndex: '9' },
    { rotate: '6deg', translateY: '20px', scale: '0.88', zIndex: '8' },
  ];

  // Collage positions for "Moments that found you" (Screenshot 4)
  const COLLAGE_STYLES = [
    { rotate: '-4deg', translateY: '-8px', scale: '0.95', zIndex: '4' },
    { rotate: '3deg', translateY: '-14px', scale: '0.92', zIndex: '3' },
    { rotate: '5deg', translateY: '0px', scale: '0.96', zIndex: '5' },
    { rotate: '-3deg', translateY: '12px', scale: '0.94', zIndex: '4' },
    { rotate: '2deg', translateY: '10px', scale: '0.95', zIndex: '4' },
    { rotate: '-5deg', translateY: '4px', scale: '0.93', zIndex: '3' },
  ];
</script>

<UserPageLayout title="Moments" noBorder>
  {#snippet buttons()}
    <div class="flex items-center gap-2">
      <button
        type="button"
        onclick={loadFeaturedPhotos}
        disabled={isShufflingFeatured}
        class="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-white/8 hover:bg-white/15 text-white/90 text-xs font-semibold border border-white/10 backdrop-blur-md transition-all active:scale-95 cursor-pointer disabled:opacity-50"
        title="Reshuffle featured photos"
      >
        <Icon icon={mdiRefresh} size="15" class={isShufflingFeatured ? 'animate-spin text-[#0078d4]' : 'text-neutral-400'} />
        <span>Reshuffle</span>
      </button>

      <IconButton
        shape="round"
        color="secondary"
        variant="ghost"
        indicator={userPreferencesManager.hasMemoryPreferences() ? 'primary' : undefined}
        icon={mdiTune}
        aria-label={$t('filters')}
        onclick={handleSettings}
      />
    </div>
  {/snippet}

  <div class="flex flex-col items-center w-full max-w-6xl mx-auto px-4 pt-6 pb-28 select-none">
    <!-- SECTION 1: Today's Featured Photos (OneDrive Screenshot 3 3D Fanned Arc) -->
    <div class="relative flex flex-col items-center w-full mb-16">
      <h2 class="text-2xl sm:text-3xl font-bold tracking-tight text-white mb-8 text-center drop-shadow-sm font-['Segoe_UI',sans-serif]">
        Today's featured photos
      </h2>

      <!-- Atmospheric Ambient Radial Glow (OneDrive exact purple/blue radial gradient) -->
      <div class="pointer-events-none absolute top-12 left-1/2 -translate-x-1/2 w-[720px] max-w-full h-80 rounded-full blur-3xl opacity-75" style="background: radial-gradient(ellipse 65% 50% at 50% 50%, rgba(0, 120, 212, 0.32) 0%, rgba(119, 25, 170, 0.22) 50%, transparent 75%);"></div>

      <!-- Fanned 3D Arc Container -->
      <div class="relative flex items-center justify-center gap-2.5 sm:gap-4 py-6 w-full overflow-x-auto no-scrollbar" style="perspective: 1200px;">
        {#if featuredPhotos.length > 0}
          {#each featuredPhotos as photo, i (photo.id)}
            {@const style = ARC_CARD_STYLES[i] ?? ARC_CARD_STYLES[2]}
            <button
              type="button"
              onclick={() => assetViewerManager.showAsset(photo)}
              class="group relative w-48 h-56 sm:w-56 sm:h-64 md:w-64 md:h-72 shrink-0 rounded-3xl overflow-hidden border border-white/20 bg-neutral-900 shadow-[0_20px_45px_rgba(0,0,0,0.65),0_4px_12px_rgba(0,0,0,0.4)] transition-all duration-300 ease-[cubic-bezier(0.16,1,0.3,1)] cursor-pointer hover:!scale-105 hover:!rotate-0 hover:!translate-y-0 hover:!z-30 hover:border-white/40 hover:shadow-[0_24px_56px_rgba(0,120,212,0.45)] focus:outline-none"
              style="transform: rotate({style.rotate}) translateY({style.translateY}) scale({style.scale}); z-index: {style.zIndex};"
            >
              <img
                src={getAssetMediaUrl({ id: photo.id, cacheKey: photo.thumbhash })}
                alt={$getAltText(toTimelineAsset(photo))}
                class="size-full object-cover transition-transform duration-500 group-hover:scale-105"
                loading="lazy"
              />
              <div class="absolute inset-0 bg-gradient-to-t from-black/75 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity flex items-end p-3.5">
                <span class="text-xs font-semibold text-white truncate drop-shadow-md">
                  {photo.originalFileName}
                </span>
              </div>
            </button>
          {/each}
        {:else if isShufflingFeatured}
          <div class="flex items-center justify-center h-64">
            <LoadingSpinner size="giant" />
          </div>
        {:else}
          {#each [1, 2, 3, 4, 5] as idx, i}
            {@const style = ARC_CARD_STYLES[i]}
            <div
              class="relative w-48 h-56 sm:w-56 sm:h-64 md:w-64 md:h-72 shrink-0 rounded-3xl overflow-hidden border border-white/10 bg-gradient-to-br from-neutral-800 to-neutral-900 shadow-xl"
              style="transform: rotate({style.rotate}) translateY({style.translateY}) scale({style.scale}); z-index: {style.zIndex};"
            >
              <div class="flex size-full items-center justify-center text-white/30">
                <Icon icon={mdiCreation} size="36" />
              </div>
            </div>
          {/each}
        {/if}
      </div>
    </div>

    <!-- SECTION 2: Moments That Found You with Reshuffle Button (OneDrive Screenshot 4) -->
    <div class="relative w-full flex flex-col items-center mb-16">
      <h3 class="text-xl sm:text-2xl font-bold tracking-tight text-white mb-8 text-center font-['Segoe_UI',sans-serif]">
        Moments that found you
      </h3>

      <!-- Collage Container with Center Reshuffle Button -->
      {#if collagePhotos.length > 0}
        <div class="relative flex items-center justify-center min-h-[340px] w-full max-w-4xl py-6">
          <!-- Circular Collage of Photos -->
          <div class="grid grid-cols-2 sm:grid-cols-3 gap-4 sm:gap-6 w-full max-w-3xl">
            {#each collagePhotos as photo, i (photo.id)}
              {@const style = COLLAGE_STYLES[i] ?? COLLAGE_STYLES[0]}
              <button
                type="button"
                onclick={() => assetViewerManager.showAsset(photo)}
                class="group relative aspect-[4/3] rounded-2xl overflow-hidden border border-white/20 bg-neutral-900 shadow-xl transition-all duration-300 hover:scale-105 hover:rotate-0 hover:z-20 hover:border-white/40 cursor-pointer"
                style="transform: rotate({style.rotate}) translateY({style.translateY}) scale({style.scale});"
              >
                <img
                  src={getAssetMediaUrl({ id: photo.id, cacheKey: photo.thumbhash })}
                  alt={$getAltText(toTimelineAsset(photo))}
                  class="size-full object-cover transition-transform duration-500 group-hover:scale-105"
                  loading="lazy"
                />
              </button>
            {/each}
          </div>

          <!-- Exact OneDrive Center Reshuffle Button (Screenshot 4) -->
          <div class="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 z-30">
            <button
              type="button"
              onclick={reshuffleCollage}
              disabled={isShufflingCollage}
              class="flex items-center gap-2 rounded-full border border-white/30 bg-black/60 hover:bg-black/80 px-6 py-2.5 text-xs font-semibold text-white shadow-2xl backdrop-blur-xl transition-all duration-200 hover:scale-105 active:scale-95 cursor-pointer disabled:opacity-50"
              title="Reshuffle Moments"
            >
              <Icon icon={mdiRefresh} size="15" class={isShufflingCollage ? 'animate-spin text-[#0078d4]' : 'text-neutral-300'} />
              <span>Reshuffle</span>
            </button>
          </div>
        </div>
      {/if}

      <!-- Memory Collections Grid -->
      {#if memoryManager.memories.length > 0}
        <div class="mt-8 grid w-full grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-5">
          {#each memoryManager.memories as memory (memory.id)}
            <MemoryCard
              class="size-full hover:scale-102 transition-transform duration-200"
              item={{
                id: memory.id,
                title: $memoryLaneTitle(memory),
                href: Route.viewMemory({
                  id: memory.id,
                  assetId: memory.assets[0].id,
                  isSaved: userPreferencesManager.memories.onlyFavorites || undefined,
                }),
                src: getAssetMediaUrl({ id: memory.assets[0].id, cacheKey: memory.assets[0].thumbhash }),
                alt: $getAltText(toTimelineAsset(memory.assets[0])),
                isSaved: memory.isSaved,
                type: memory.type,
              }}
            />
          {/each}
        </div>
      {:else if memoryManager.loading}
        <div class="flex items-center justify-center py-12">
          <LoadingSpinner size="giant" />
        </div>
      {/if}
    </div>
  </div>
</UserPageLayout>
