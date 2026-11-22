<script lang="ts">
  import AlbumCover from '#lib/components/album-page/AlbumCover.svelte';
  import { authManager } from '#lib/managers/auth-manager.svelte.ts';
  import { getShortDateRange } from '#lib/utils/date-time.ts';
  import { type AlbumResponseDto } from '@immich/sdk';
  import { ContextMenuButton, type MenuItems } from '@immich/ui';
  import { t } from 'svelte-i18n';

  type Props = {
    album: AlbumResponseDto;
    showOwner?: boolean;
    showDateRange?: boolean;
    showItemCount?: boolean;
    preload?: boolean;
    contextMenuItems?: MenuItems;
  };

  const {
    album,
    showOwner = false,
    showDateRange = false,
    showItemCount = false,
    preload = false,
    contextMenuItems,
  }: Props = $props();

  const owner = $derived(album.albumUsers[0].user);
</script>

<div
  class="group relative rounded-2xl border border-transparent p-3.5 transition-all duration-200 hover:border-slate-200/80 hover:bg-slate-100/80 dark:hover:border-white/10 dark:hover:bg-white/5 hover:shadow-xl hover:shadow-black/20"
  data-testid="album-card"
>
  {#if contextMenuItems}
    <div
      id="icon-{album.id}"
      class="absolute inset-e-6 top-6 opacity-0 group-hover:opacity-100 focus-within:opacity-100"
      data-testid="context-button-parent"
    >
      <ContextMenuButton
        translations={{ open_menu: $t('show_album_options') }}
        position="top-left"
        variant="filled"
        class="icon-white-drop-shadow"
        items={contextMenuItems}
      />
    </div>
  {/if}

  <AlbumCover {album} {preload} class="transition-all duration-300 hover:shadow-lg rounded-xl overflow-hidden" />

  <div class="mt-3">
    <p
      class="line-clamp-1 w-full text-base font-semibold wrap-break-word text-neutral-900 group-hover:text-primary dark:text-white"
      data-testid="album-name"
      title={album.albumName}
    >
      {album.albumName}
    </p>

    {#if showDateRange && album.startDate && album.endDate}
      <p class="flex text-xs capitalize text-neutral-500 dark:text-neutral-400 mt-0.5">
        {getShortDateRange(album.startDate, album.endDate)}
      </p>
    {/if}

    <span class="flex gap-1.5 text-xs text-neutral-500 dark:text-neutral-400 mt-0.5" data-testid="album-details">
      {#if showItemCount}
        <p>
          {$t('items_count', { values: { count: album.assetCount } })}
        </p>
      {/if}

      {#if (showOwner || album.shared) && showItemCount}
        <p>•</p>
      {/if}

      {#if showOwner}
        {#if owner.id === authManager.user.id}
          <p>{$t('owned')}</p>
        {:else}
          <p>
            {$t('shared_by_user', { values: { user: owner.name } })}
          </p>
        {/if}
      {:else if album.shared}
        <p>{$t('shared')}</p>
      {/if}
    </span>
  </div>
</div>
