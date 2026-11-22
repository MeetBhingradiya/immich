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
  import { mdiCreation, mdiMagnify, mdiPlus, mdiRefresh, mdiTune } from '@mdi/js';
  import { onMount } from 'svelte';
  import { t } from 'svelte-i18n';
  import { goto } from '$app/navigation';
  import type { PageData } from './$types';

  type Props = {
    data: PageData;
  };

  const { data }: Props = $props();

  let featuredPhotos = $state<AssetResponseDto[]>([]);
  let isShuffling = $state(false);

  async function loadFeaturedPhotos() {
    isShuffling = true;
    try {
      const photos = await searchRandom({ count: 10 });
      if (photos && photos.length > 0) {
        featuredPhotos = photos.slice(0, 5);
      }
    } catch {
      // Fallback: pick from memory manager assets if searchRandom is empty
      const memoryAssets = memoryManager.memories.flatMap((m) => m.assets).slice(0, 5);
      featuredPhotos = memoryAssets;
    } finally {
      isShuffling = false;
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

  // Card transform styles for 5 fanned-out 3D cards
  const CARD_STYLES = [
    { rotate: '-9deg', translateY: '22px', scale: '0.90', zIndex: '10' },
    { rotate: '-4.5deg', translateY: '9px', scale: '0.96', zIndex: '20' },
    { rotate: '0deg', translateY: '0px', scale: '1.04', zIndex: '30' },
    { rotate: '4.5deg', translateY: '9px', scale: '0.96', zIndex: '20' },
    { rotate: '9deg', translateY: '22px', scale: '0.90', zIndex: '10' },
  ];
</script>

<UserPageLayout title="Moments" noBorder>
  {#snippet buttons()}
    <div class="flex items-center gap-2">
      <button
        type="button"
        onclick={loadFeaturedPhotos}
        disabled={isShuffling}
        class="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-white/8 hover:bg-white/15 text-white/90 text-xs font-medium border border-white/10 backdrop-blur-md transition-all active:scale-95 cursor-pointer disabled:opacity-50"
        title="Reshuffle featured photos"
      >
        <Icon icon={mdiRefresh} size="15" class={isShuffling ? 'animate-spin text-purple-400' : 'text-neutral-400'} />
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
    <!-- SECTION 1: Today's Featured Photos (OneDrive 3D Fanned Arc Cards) -->
    <div class="relative flex flex-col items-center w-full mb-16">
      <h2 class="text-2xl sm:text-3xl font-bold tracking-tight text-white mb-8 text-center drop-shadow-sm">
        Today's featured photos
      </h2>

      <!-- Subtle Luminous Radial Backdrop Glow -->
      <div class="pointer-events-none absolute top-12 left-1/2 -translate-x-1/2 w-96 h-64 bg-radial from-purple-600/30 via-sky-500/20 to-transparent blur-3xl rounded-full"></div>

      <!-- Fanned 3D Cards Container -->
      <div class="relative flex items-center justify-center gap-2 sm:gap-3 py-4 w-full overflow-x-auto no-scrollbar" style="perspective: 1200px;">
        {#if featuredPhotos.length > 0}
          {#each featuredPhotos as photo, i (photo.id)}
            {@const style = CARD_STYLES[i] ?? CARD_STYLES[2]}
            <button
              type="button"
              onclick={() => assetViewerManager.showAsset(photo)}
              class="group relative size-44 sm:size-52 md:size-60 shrink-0 rounded-3xl overflow-hidden border border-white/20 bg-neutral-900 shadow-2xl transition-all duration-300 ease-out cursor-pointer hover:!scale-110 hover:!rotate-0 hover:!translate-y-0 hover:z-40 hover:shadow-cyan-500/30 hover:border-white/40 focus:outline-none"
              style="transform: rotate({style.rotate}) translateY({style.translateY}) scale({style.scale}); z-index: {style.zIndex};"
            >
              <img
                src={getAssetMediaUrl({ id: photo.id, cacheKey: photo.thumbhash })}
                alt={$getAltText(toTimelineAsset(photo))}
                class="size-full object-cover transition-transform duration-500 group-hover:scale-105"
                loading="lazy"
              />
              <div class="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity flex items-end p-3">
                <span class="text-xs font-semibold text-white truncate drop-shadow-md">
                  {photo.originalFileName}
                </span>
              </div>
            </button>
          {/each}
        {:else if isShuffling}
          <div class="flex items-center justify-center h-52">
            <LoadingSpinner size="giant" />
          </div>
        {:else}
          <!-- Elegant placeholder deck if library is fresh -->
          {#each [1, 2, 3, 4, 5] as idx, i}
            {@const style = CARD_STYLES[i]}
            <div
              class="relative size-44 sm:size-52 md:size-60 shrink-0 rounded-3xl overflow-hidden border border-white/10 bg-gradient-to-br from-neutral-800 to-neutral-900 shadow-xl"
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

    <!-- SECTION 2: Moments That Found You (Memories Collection) -->
    <div class="w-full flex flex-col items-center">
      <div class="flex items-center justify-between w-full mb-6 px-2">
        <h3 class="text-xl sm:text-2xl font-bold tracking-tight text-white">
          Moments that found you
        </h3>

        {#if memoryManager.memories.length > 0}
          <span class="text-xs font-medium text-neutral-400">
            {memoryManager.memories.length} collections
          </span>
        {/if}
      </div>

      {#if memoryManager.memories.length > 0}
        <div class="grid w-full grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-5">
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
        <div class="flex items-center justify-center py-16">
          <LoadingSpinner size="giant" />
        </div>
      {:else}
        <div class="flex flex-col items-center justify-center py-12 text-center text-neutral-400">
          <div class="flex size-14 items-center justify-center rounded-full bg-white/5 border border-white/10 mb-3 text-purple-400">
            <Icon icon={mdiCreation} size="28" />
          </div>
          <p class="text-sm font-medium text-white mb-1">Your memories will appear here</p>
          <p class="text-xs text-neutral-500 max-w-sm">
            As you take and upload photos, Immich automatically surfaces on-this-day highlights and special moments.
          </p>
        </div>
      {/if}
    </div>
  </div>

  <!-- FLOATING BOTTOM PILL: OneDrive-Style [ + ] [ Search your photos ] -->
  <div class="fixed bottom-6 left-1/2 -translate-x-1/2 z-40 flex items-center gap-2 p-1.5 rounded-full bg-neutral-900/90 border border-white/15 backdrop-blur-2xl shadow-2xl shadow-black/80 select-none">
    <button
      type="button"
      onclick={() => goto(Route.explore())}
      class="flex size-9 items-center justify-center rounded-full bg-blue-600 hover:bg-blue-500 text-white transition-all active:scale-95 cursor-pointer shadow-md"
      title="Upload / Add photos"
    >
      <Icon icon={mdiPlus} size="20" />
    </button>

    <button
      type="button"
      onclick={() => goto(Route.explore())}
      class="flex items-center gap-2.5 px-4 py-1.5 rounded-full bg-white/6 hover:bg-white/10 text-neutral-300 hover:text-white transition-all text-xs font-medium cursor-pointer"
    >
      <Icon icon={mdiMagnify} size="16" class="text-neutral-400" />
      <span>Search your photos</span>
    </button>
  </div>
</UserPageLayout>
