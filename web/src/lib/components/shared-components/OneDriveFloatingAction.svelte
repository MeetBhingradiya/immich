<script lang="ts">
  import { clickOutside } from '#lib/actions/click-outside.ts';
  import { searchManager } from '#lib/managers/search-manager.svelte.ts';
  import { searchStore } from '#lib/stores/search.svelte.ts';
  import { createAlbumAndRedirect } from '#lib/utils/album-utils.ts';
  import { openFileUploadDialog } from '#lib/utils/file-uploader.ts';
  import { handlePromiseError } from '#lib/utils.ts';
  import { Icon } from '@immich/ui';
  import {
    mdiClose,
    mdiFolderOutline,
    mdiFolderPlusOutline,
    mdiMagnify,
    mdiPlus,
    mdiTrayArrowUp,
  } from '@mdi/js';
  import { cubicOut } from 'svelte/easing';
  import { fade, fly, scale } from 'svelte/transition';

  type Props = {
    onUploadClick?: () => void;
  };

  let { onUploadClick }: Props = $props();

  let showUploadDropdown = $state(false);
  let showSearchModal = $state(false);
  let searchInput = $state<HTMLInputElement>();
  let searchQuery = $state('');

  let recentTerms = $derived(searchStore.savedSearchTerms || ['windows', 'hi']);

  const handleUploadFiles = () => {
    showUploadDropdown = false;
    if (onUploadClick) {
      onUploadClick();
    } else {
      openFileUploadDialog();
    }
  };

  const handleUploadFolder = () => {
    showUploadDropdown = false;
    openFileUploadDialog({ folder: true });
  };

  const handleCreateAlbum = () => {
    showUploadDropdown = false;
    createAlbumAndRedirect();
  };

  const openSearch = () => {
    showUploadDropdown = false;
    showSearchModal = true;
    setTimeout(() => searchInput?.focus(), 60);
  };

  const closeSearch = () => {
    showSearchModal = false;
  };

  const executeSearch = (query: string) => {
    const trimmed = query.trim();
    if (!trimmed) return;

    // Save to recent searches
    const filtered = (searchStore.savedSearchTerms || []).filter(
      (item) => item.toLowerCase() !== trimmed.toLowerCase(),
    );
    searchStore.savedSearchTerms = [trimmed, ...filtered].slice(0, 8);

    closeSearch();
    searchManager.filter.query = trimmed;
    handlePromiseError(searchManager.submit());
  };

  const clearSearchTerm = (term: string) => {
    searchStore.savedSearchTerms = (searchStore.savedSearchTerms || []).filter((item) => item !== term);
  };

  const handleSearchSubmit = (e: Event) => {
    e.preventDefault();
    executeSearch(searchQuery);
  };
</script>

<!-- Search Popover Modal (OneDrive Screenshot 1 exact match) -->
{#if showSearchModal}
  <!-- Backdrop -->
  <div
    transition:fade={{ duration: 150 }}
    class="fixed inset-0 z-[9990] bg-black/60 backdrop-blur-xs"
    onclick={closeSearch}
    role="presentation"
  ></div>

  <!-- Search Card Flyout -->
  <div
    transition:fly={{ y: 16, duration: 200, easing: cubicOut }}
    use:clickOutside={{ onOutclick: closeSearch, onEscape: closeSearch }}
    class="fixed bottom-20 left-1/2 -translate-x-1/2 z-[9991] w-full max-w-[440px] rounded-3xl border border-white/15 bg-[#1c1c1c]/98 p-5 text-white shadow-[0_24px_64px_rgba(0,0,0,0.9)] backdrop-blur-2xl select-none"
    role="dialog"
    aria-label="Search Photos"
  >
    <!-- Recent searches -->
    {#if recentTerms.length > 0}
      <div class="mb-4">
        <div class="flex items-center justify-between mb-2.5">
          <span class="text-xs font-semibold text-neutral-300">Recent searches</span>
          <button
            type="button"
            class="text-[11px] text-neutral-400 hover:text-white transition-colors cursor-pointer"
            onclick={() => (searchStore.savedSearchTerms = [])}
          >
            Clear all
          </button>
        </div>
        <div class="flex flex-wrap gap-2">
          {#each recentTerms as term}
            <div class="inline-flex items-center gap-1.5 rounded-full bg-white/10 hover:bg-white/15 border border-white/10 px-3 py-1 text-xs text-neutral-200 transition-all">
              <button
                type="button"
                class="hover:text-white cursor-pointer"
                onclick={() => executeSearch(term)}
              >
                {term}
              </button>
              <button
                type="button"
                class="text-neutral-400 hover:text-white p-0.5 rounded-full hover:bg-white/10 cursor-pointer"
                onclick={() => clearSearchTerm(term)}
                aria-label="Remove search term"
              >
                <Icon icon={mdiClose} size="12px" />
              </button>
            </div>
          {/each}
        </div>
      </div>
    {/if}

    <!-- Examples (Screenshot 1 exact items) -->
    <div class="mb-4 pt-3 border-t border-white/10">
      <p class="text-xs font-semibold text-neutral-300 mb-2">Examples</p>
      <div class="space-y-1">
        {#each [
          'Hiking in the mountains',
          'Fireworks by the beach',
          'Field hockey action shot',
          'Sunset at golden hour'
        ] as example}
          <button
            type="button"
            class="flex w-full items-center gap-2.5 rounded-xl px-2.5 py-1.5 text-xs text-neutral-300 hover:bg-white/10 hover:text-white text-start transition-colors cursor-pointer"
            onclick={() => executeSearch(example)}
          >
            <span class="text-amber-400 text-sm">💡</span>
            <span>{example}</span>
          </button>
        {/each}
      </div>
    </div>

    <!-- Integrated Search Input Row with Close Button -->
    <form onsubmit={handleSearchSubmit} class="relative flex items-center">
      <span class="absolute left-3.5 text-neutral-400">
        <Icon icon={mdiMagnify} size="18px" />
      </span>
      <input
        bind:this={searchInput}
        bind:value={searchQuery}
        type="text"
        placeholder="Search your photos"
        class="w-full rounded-full border border-white/15 bg-[#121212] py-2.5 pl-10 pr-10 text-xs text-white placeholder-neutral-400 focus:border-[#0078d4] focus:outline-none focus:ring-1 focus:ring-[#0078d4]"
      />
      <button
        type="button"
        onclick={closeSearch}
        class="absolute right-3 flex size-6 items-center justify-center rounded-full text-neutral-400 hover:text-white hover:bg-white/10 transition-colors cursor-pointer"
        aria-label="Close search"
      >
        <Icon icon={mdiClose} size="16px" />
      </button>
    </form>
  </div>
{/if}

<!-- Bottom Floating Action Capsule (OneDrive Screenshot 2 & 3 match) -->
<div
  class="fixed bottom-6 left-1/2 -translate-x-1/2 z-[9980] select-none"
  use:clickOutside={{ onOutclick: () => { showUploadDropdown = false; } }}
>
  <div class="relative flex items-center gap-1.5 rounded-full border border-white/15 bg-[#1e1e1e]/95 p-1 shadow-[0_8px_32px_rgba(0,0,0,0.7)] backdrop-blur-2xl">
    <!-- Purple Gradient Plus Button (+) -->
    <button
      type="button"
      onclick={() => (showUploadDropdown = !showUploadDropdown)}
      class="flex size-9.5 items-center justify-center rounded-full bg-gradient-to-tr from-[#7719aa] to-[#9c27b0] hover:from-[#8821c2] hover:to-[#ab34c0] text-white shadow-md transition-all hover:scale-105 active:scale-95 cursor-pointer"
      title="Create & Upload"
      aria-label="Create & Upload"
    >
      <Icon icon={mdiPlus} size="22px" />
    </button>

    <!-- Search Button (Icon on compact, expanding to text on sm screens) -->
    <button
      type="button"
      onclick={openSearch}
      class="flex items-center gap-2 h-9 px-3 sm:px-4 rounded-full bg-white/5 hover:bg-white/10 border border-white/5 text-neutral-300 hover:text-white transition-all cursor-pointer"
      title="Search Photos"
      aria-label="Search Photos"
    >
      <Icon icon={mdiMagnify} size="18px" class="text-neutral-400" />
      <span class="hidden sm:inline text-xs font-medium text-neutral-300">Search your photos</span>
    </button>

    <!-- Upload Menu Popover -->
    {#if showUploadDropdown}
      <div
        transition:fly={{ y: -8, duration: 150 }}
        class="absolute bottom-full left-0 mb-2 w-48 rounded-2xl border border-white/15 bg-[#1c1c1c] p-1.5 text-white shadow-2xl backdrop-blur-2xl"
      >
        <button
          type="button"
          onclick={handleUploadFiles}
          class="flex w-full items-center gap-2.5 rounded-xl px-3 py-2 text-xs font-medium text-neutral-200 hover:bg-white/10 hover:text-white transition-colors cursor-pointer"
        >
          <Icon icon={mdiTrayArrowUp} size="16px" class="text-neutral-400" />
          <span>Upload files</span>
        </button>
        <button
          type="button"
          onclick={handleUploadFolder}
          class="flex w-full items-center gap-2.5 rounded-xl px-3 py-2 text-xs font-medium text-neutral-200 hover:bg-white/10 hover:text-white transition-colors cursor-pointer"
        >
          <Icon icon={mdiFolderOutline} size="16px" class="text-neutral-400" />
          <span>Upload folder</span>
        </button>
        <div class="my-1 h-px bg-white/10"></div>
        <button
          type="button"
          onclick={handleCreateAlbum}
          class="flex w-full items-center gap-2.5 rounded-xl px-3 py-2 text-xs font-medium text-neutral-200 hover:bg-white/10 hover:text-white transition-colors cursor-pointer"
        >
          <Icon icon={mdiFolderPlusOutline} size="16px" class="text-neutral-400" />
          <span>New album</span>
        </button>
      </div>
    {/if}
  </div>
</div>
