<script lang="ts">
  import { clickOutside } from '#lib/actions/click-outside.ts';
  import { Route } from '#lib/route.ts';
  import { createAlbumAndRedirect } from '#lib/utils/album-utils.ts';
  import { openFileUploadDialog } from '#lib/utils/file-uploader.ts';
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
  import { goto } from '$app/navigation';
  import { fly, scale } from 'svelte/transition';

  type Props = {
    onUploadClick?: () => void;
    onSearchClick?: () => void;
  };

  let { onUploadClick, onSearchClick }: Props = $props();

  let isExpanded = $state(false);
  let showUploadDropdown = $state(false);

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
    isExpanded = false;
    createAlbumAndRedirect();
  };

  const handleSearch = () => {
    if (onSearchClick) {
      onSearchClick();
    } else {
      void goto(Route.search());
    }
  };
</script>

<div
  class="fixed bottom-6 left-1/2 -translate-x-1/2 z-40 select-none"
  use:clickOutside={{ onOutclick: () => { isExpanded = false; showUploadDropdown = false; } }}
>
  {#if !isExpanded}
    <!-- Collapsed Capsule State (OneDrive Reference Screenshot 8) -->
    <div
      transition:scale={{ start: 0.9, duration: 180 }}
      class="flex items-center gap-1 rounded-full border border-white/15 bg-neutral-900/90 p-1.5 shadow-[0_8px_32px_rgba(0,0,0,0.55)] backdrop-blur-2xl"
    >
      <button
        type="button"
        onclick={() => (isExpanded = true)}
        class="flex size-9 items-center justify-center rounded-full bg-gradient-to-tr from-blue-600 via-indigo-600 to-purple-600 text-white shadow-md transition-all hover:scale-105 active:scale-95 cursor-pointer"
        title="Create & Upload"
        aria-label="Create & Upload"
      >
        <Icon icon={mdiPlus} size="22px" />
      </button>

      <button
        type="button"
        onclick={handleSearch}
        class="flex size-9 items-center justify-center rounded-full text-neutral-300 transition-colors hover:bg-white/10 hover:text-white cursor-pointer"
        title="Search Photos"
        aria-label="Search Photos"
      >
        <Icon icon={mdiMagnify} size="20px" />
      </button>
    </div>
  {:else}
    <!-- Expanded Capsule State (OneDrive Reference Screenshot 9) -->
    <div
      transition:scale={{ start: 0.95, duration: 200 }}
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
