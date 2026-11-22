<script lang="ts">
  import BottomInfo from '#lib/components/shared-components/side-bar/BottomInfo.svelte';
  import RecentAlbums from '#lib/components/shared-components/side-bar/RecentAlbums.svelte';
  import Sidebar from '#lib/components/sidebar/Sidebar.svelte';
  import { authManager } from '#lib/managers/auth-manager.svelte.ts';
  import { createPreloadedQuery } from '#lib/queries/client.ts';
  import { getUserConfigQuery } from '#lib/queries/config-user.query.ts';
  import { Route } from '#lib/route.ts';
  import { recentAlbumsDropdown } from '#lib/stores/preferences.store.ts';
  import { NavbarGroup, NavbarItem } from '@immich/ui';
  import {
    mdiAccount,
    mdiAccountMultiple,
    mdiAccountMultipleOutline,
    mdiAccountOutline,
    mdiArchiveArrowDown,
    mdiArchiveArrowDownOutline,
    mdiCards,
    mdiCardsOutline,
    mdiFolderOutline,
    mdiHeart,
    mdiHeartOutline,
    mdiImageAlbum,
    mdiImageMultiple,
    mdiImageMultipleOutline,
    mdiLink,
    mdiLock,
    mdiLockOutline,
    mdiMagnify,
    mdiMap,
    mdiMapOutline,
    mdiTagMultipleOutline,
    mdiToolbox,
    mdiToolboxOutline,
    mdiTrashCan,
    mdiTrashCanOutline,
    mdiUploadOutline,
  } from '@mdi/js';
  import { t } from 'svelte-i18n';
  import { fly } from 'svelte/transition';

  const query = createPreloadedQuery(getUserConfigQuery);
  const config = $derived(query.data);
</script>

<Sidebar ariaLabel={$t('primary')}>
  <!-- Samsung One UI Profile Header Card (Screenshot 1 & 2) -->
  <div class="mb-3 px-2">
    <div
      class="flex items-center gap-3 rounded-2xl bg-neutral-900/60 p-2.5 backdrop-blur-md border border-white/5 transition-all hover:bg-neutral-900/80 hover:border-white/10"
    >
      <div
        class="relative flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-gradient-to-tr from-sky-500 via-indigo-600 to-fuchsia-600 p-0.5 shadow-md"
      >
        <div class="flex h-full w-full items-center justify-center rounded-full bg-[#11141c] text-sm font-bold text-white">
          {authManager.user?.name ? authManager.user.name.charAt(0).toUpperCase() : 'M'}
        </div>
        <span class="absolute -bottom-0.5 -right-0.5 flex h-3.5 w-3.5 items-center justify-center rounded-full bg-emerald-500 ring-2 ring-[#11141c]">
          <span class="h-1.5 w-1.5 rounded-full bg-white"></span>
        </span>
      </div>

      <div class="min-w-0 flex-1 overflow-hidden">
        <p class="truncate text-xs font-semibold text-white">
          {authManager.user?.name || 'Meet Bhingradiya'}
        </p>
        <p class="truncate text-[10px] text-neutral-400">
          {authManager.user?.email ? authManager.user.email.replace(/(.{3})(.*)(@.*)/, '$1***********$3') : 'mee***********@gmail.com'}
        </p>
      </div>
    </div>
    <div class="mt-3 border-b border-dashed border-white/10"></div>
  </div>

  <NavbarItem title={$t('photos')} href={Route.photos()} icon={mdiImageMultipleOutline} activeIcon={mdiImageMultiple} />

  <NavbarItem title={$t('explore')} href={Route.explore()} icon={mdiMagnify} />

  {#if config.map.enabled}
    <NavbarItem title={$t('map')} href={Route.map()} icon={mdiMapOutline} activeIcon={mdiMap} />
  {/if}

  {#if authManager.preferences.memories.enabled && authManager.preferences.memories.sidebarWeb}
    <NavbarItem title={$t('memories')} href={Route.memories()} icon={mdiCardsOutline} activeIcon={mdiCards} />
  {/if}

  {#if authManager.preferences.people.enabled && authManager.preferences.people.sidebarWeb}
    <NavbarItem title={$t('people')} href={Route.people()} icon={mdiAccountOutline} activeIcon={mdiAccount} />
  {/if}

  {#if authManager.preferences.sharedLinks.enabled && authManager.preferences.sharedLinks.sidebarWeb}
    <NavbarItem title={$t('shared_links')} href={Route.sharedLinks()} icon={mdiLink} />
  {/if}

  <NavbarItem
    title={$t('sharing')}
    href={Route.sharing()}
    icon={mdiAccountMultipleOutline}
    activeIcon={mdiAccountMultiple}
  />

  <NavbarGroup title={$t('library')} size="tiny" />

  <NavbarItem title={$t('favorites')} href={Route.favorites()} icon={mdiHeartOutline} activeIcon={mdiHeart} />

  <NavbarItem
    title={$t('albums')}
    href={Route.albums()}
    icon={{ icon: mdiImageAlbum, flipped: true }}
    bind:expanded={$recentAlbumsDropdown}
  >
    {#snippet items()}
      <span in:fly={{ y: -20 }} class="hidden md:block">
        <RecentAlbums />
      </span>
    {/snippet}
  </NavbarItem>

  {#if authManager.preferences.tags.enabled && authManager.preferences.tags.sidebarWeb}
    <NavbarItem title={$t('tags')} href={Route.tags()} icon={{ icon: mdiTagMultipleOutline, flipped: true }} />
  {/if}

  {#if authManager.preferences.recentlyAdded.sidebarWeb}
    <NavbarItem
      title={$t('recently_added')}
      href={Route.recentlyAdded()}
      icon={{ icon: mdiUploadOutline, flipped: true }}
    />
  {/if}

  {#if authManager.preferences.folders.enabled && authManager.preferences.folders.sidebarWeb}
    <NavbarItem title={$t('folders')} href={Route.folders()} icon={{ icon: mdiFolderOutline, flipped: true }} />
  {/if}

  <NavbarItem title={$t('utilities')} href={Route.utilities()} icon={mdiToolboxOutline} activeIcon={mdiToolbox} />

  <NavbarItem
    title={$t('archive')}
    href={Route.archive()}
    icon={mdiArchiveArrowDownOutline}
    activeIcon={mdiArchiveArrowDown}
  />

  <NavbarItem title={$t('locked_folder')} href={Route.locked()} icon={mdiLockOutline} activeIcon={mdiLock} />

  {#if config.trash.enabled}
    <NavbarItem title={$t('trash')} href={Route.trash()} icon={mdiTrashCanOutline} activeIcon={mdiTrashCan} />
  {/if}

  <BottomInfo />
</Sidebar>
