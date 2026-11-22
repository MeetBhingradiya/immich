<script lang="ts">
  import { clickOutside } from '#lib/actions/click-outside.ts';
  import { searchManager } from '#lib/managers/search-manager.svelte.ts';
  import { Route } from '#lib/route.ts';
  import { searchStore } from '#lib/stores/search.svelte.ts';
  import { createAlbumAndRedirect } from '#lib/utils/album-utils.ts';
  import { openFileUploadDialog } from '#lib/utils/file-uploader.ts';
  import { handlePromiseError } from '#lib/utils.ts';
  import { Icon } from '@immich/ui';
  import {
    mdiChevronDown,
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

  let isExpanded = $state(false);
  let showUploadDropdown = $state(false);
  let showSearchModal = $state(false);
  let searchInput = $state<HTMLInputElement>();
  let searchQuery = $state('');

  let recentTerms = $derived(searchStore.savedSearchTerms || []);

  const handleUploadFiles = () => {
    showUploadDropdown = false;
    isExpanded = false;
    if (onUploadClick) {
      onUploadClick();
    } else {
      openFileUploadDialog();
    }
  };

  const handleUploadFolder = () => {
    showUploadDropdown = false;
    isExpanded = false;
    openFileUploadDialog({ folder: true });
  };

  const handleCreateAlbum = () => {
    isExpanded = false;
    createAlbumAndRedirect();
  };

  const openSearch = () => {
    showSearchModal = true;
    setTimeout(() => searchInput?.focus(), 50);
  };

  const closeSearch = () => {
    showSearchModal = false;
  };

  const executeSearch = (query: string) => {
    const trimmed = query.trim();
    if (!trimmed) return;
    
    // Save to search store
    const filtered = searchStore.savedSearchTerms.filter(
      (item) => item.toLowerCase() !== trimmed.toLowerCase(),
    );
    searchStore.savedSearchTerms = [trimmed, ...filtered].slice(0, 8);

    closeSearch();
    searchManager.filter.query = trimmed;
    handlePromiseError(searchManager.submit());
  };

  const clearSearchTerm = (term: string) => {
    searchStore.savedSearchTerms = searchStore.savedSearchTerms.filter((item) => item !== term);
  };

  const handleSearchSubmit = (e: Event) => {
    e.preventDefault();
    executeSearch(searchQuery);
  };
</script>

<!-- Search Popover Modal (Smooth Animation matching OneDrive Screenshot 7) -->
{#if showSearchModal}
  <!-- Backdrop -->
  <div
    transition:fade={{ duration: 150 }}
    class="fixed inset-0 z-50 bg-black/50 backdrop-blur-xs"
    onclick={closeSearch}
    role="presentation"
  ></div>

  <!-- Search Popover Card -->
  <div
    transition:fly={{ y: 20, duration: 220, easing: cubicOut }}
    use:clickOutside={{ onOutclick: closeSearch, onEscape: closeSearch }}
    class="fixed bottom-20 left-1/2 -translate-x-1/2 z-50 w-full max-w-lg rounded-3xl border border-white/20 bg-neutral-900/95 p-5 text-white shadow-2xl backdrop-blur-2xl"
    role="dialog"
    aria-label="Search Photos"
  >
    <!-- Recent Searches -->
    {#if recentTerms.length > 0}
      <div class="mb-4">
        <div class="flex items-center justify-between mb-2">
          <span class="text-xs font-semibold text-neutral-400">Recent searches</span>
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
            <div class="inline-flex items-center gap-1.5 rounded-full bg-white/10 hover:bg-white/15 border border-white/10 px-3 py-1 text-xs text-neutral-200 transition-all group">
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

    <!-- Examples Section (Reference Screenshot 7) -->
    <div class="mb-4 pt-3 border-t border-white/10">
      <p class="text-xs font-semibold text-neutral-400 mb-2">Examples</p>
      <div class="space-y-1">
        {#each [
          'Hiking in the mountains',
          'Fireworks by the beach',
          'Field hockey action shot',
          'Sunset at golden hour',
          'Screenshots and documents'
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

    <!-- Search Input Form -->
    <form onsubmit={handleSearchSubmit} class="relative flex items-center">
      <span class="absolute left-3.5 text-neutral-400">
        <Icon icon={mdiMagnify} size="18px" />
      </span>
      <input
        bind:this={searchInput}
        bind:value={searchQuery}
        type="text"
        placeholder="Search your photos"
        class="w-full rounded-full border border-white/15 bg-neutral-950/80 py-2.5 pl-10 pr-10 text-xs text-white placeholder-neutral-400 focus:border-blue-500/80 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
      />
      {#if searchQuery}
        <button
          type="button"
          onclick={() => (searchQuery = '')}
          class="absolute right-3 text-neutral-400 hover:text-white cursor-pointer"
        >
          <Icon icon={mdiClose} size="16px" />
        </button>
      {/if}
    </form>
  </div>
{/if}

<!-- Bottom Floating Action Capsule (Reference Screenshots 1, 2, 8, 9) -->
<div
  class="fixed bottom-6 left-1/2 -translate-x-1/2 z-40 select-none"
  use:clickOutside={{ onOutclick: () => { isExpanded = false; showUploadDropdown = false; } }}
>
  {#if !isExpanded}
    <!-- Collapsed State: [ (+) | 🔍 Search your photos ] (OneDrive exact 44px capsule) -->
    <div
      transition:scale={{ start: 0.9, duration: 180, easing: cubicOut }}
      class="flex items-center gap-2 rounded-full border border-white/15 bg-[#1e1e1e]/95 p-1.5 shadow-[0_8px_32px_rgba(0,0,0,0.65)] backdrop-blur-2xl"
    >
      <button
        type="button"
        onclick={() => (isExpanded = true)}
        class="flex size-10 items-center justify-center rounded-full bg-[#7719aa] hover:bg-[#8e24aa] text-white shadow-md transition-all hover:scale-105 active:scale-95 cursor-pointer"
        title="Create & Upload"
        aria-label="Create & Upload"
      >
        <Icon icon={mdiPlus} size="22px" />
      </button>

      <button
        type="button"
        onclick={openSearch}
        class="flex items-center gap-2.5 h-10 px-4 rounded-full bg-white/5 border border-white/10 text-neutral-300 transition-colors hover:bg-white/10 hover:text-white cursor-pointer"
        title="Search Photos"
        aria-label="Search Photos"
      >
        <Icon icon={mdiMagnify} size="18px" class="text-neutral-400" />
        <span class="text-xs font-medium text-neutral-300">Search your photos</span>
      </button>
    </div>
  {:else}
    <!-- Expanded State: [ ↑ Upload ˇ | 🗂️+ New album | ✕ ] -->
    <div
      transition:scale={{ start: 0.95, duration: 200, easing: cubicOut }}
      class="relative flex items-center gap-2 rounded-full border border-white/20 bg-neutral-900/95 p-1.5 px-2.5 shadow-[0_12px_40px_rgba(0,0,0,0.65)] backdrop-blur-2xl"
    >
      <!-- Upload Button with Dropdown -->
      <div class="relative">
        <button
          type="button"
          onclick={() => (showUploadDropdown = !showUploadDropdown)}
          class="flex items-center gap-2 rounded-full border border-white/30 bg-white/10 px-4 py-2 text-xs font-semibold text-white transition-all hover:bg-white/20 cursor-pointer shadow-xs"
          title="Upload Photos or Folders"
        >
          <Icon icon={mdiTrayArrowUp} size="16px" />
          <span>Upload</span>
          <Icon icon={mdiChevronDown} size="14px" class="opacity-70" />
        </button>

        {#if showUploadDropdown}
          <div
            transition:fly={{ y: -8, duration: 150 }}
            class="absolute bottom-full left-0 mb-2 w-40 rounded-2xl border border-white/15 bg-neutral-900/95 p-1 text-white shadow-2xl backdrop-blur-2xl"
          >
            <button
              type="button"
              onclick={handleUploadFiles}
              class="flex w-full items-center gap-2.5 rounded-xl px-3 py-2 text-start text-xs font-medium text-neutral-200 transition-colors hover:bg-white/10 hover:text-white cursor-pointer"
            >
              <Icon icon={mdiTrayArrowUp} size="16px" class="text-blue-400" />
              <span>Upload files</span>
            </button>
            <button
              type="button"
              onclick={handleUploadFolder}
              class="flex w-full items-center gap-2.5 rounded-xl px-3 py-2 text-start text-xs font-medium text-neutral-200 transition-colors hover:bg-white/10 hover:text-white cursor-pointer"
            >
              <Icon icon={mdiFolderOutline} size="16px" class="text-amber-400" />
              <span>Upload folder</span>
            </button>
          </div>
        {/if}
      </div>

      <!-- New Album Button -->
      <button
        type="button"
        onclick={handleCreateAlbum}
        class="flex items-center gap-2 rounded-full px-3.5 py-2 text-xs font-medium text-neutral-200 transition-colors hover:bg-white/10 hover:text-white cursor-pointer"
        title="Create New Album"
      >
        <Icon icon={mdiFolderPlusOutline} size="17px" class="text-neutral-300" />
        <span>New album</span>
      </button>

      <!-- Close Button -->
      <button
        type="button"
        onclick={() => (isExpanded = false)}
        class="flex size-7 items-center justify-center rounded-full text-neutral-400 transition-colors hover:bg-white/10 hover:text-white cursor-pointer"
        title="Collapse"
        aria-label="Collapse"
      >
        <Icon icon={mdiClose} size="17px" />
      </button>
    </div>
  {/if}
</div>
