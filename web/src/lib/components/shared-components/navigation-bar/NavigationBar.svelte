<script lang="ts" module>
  export const menuButtonId = 'top-menu-button';
</script>

<script lang="ts">
  import { clickOutside } from '#lib/actions/click-outside.ts';
  import NotificationPanel from '#lib/components/shared-components/navigation-bar/NotificationPanel.svelte';
  import SearchBar from '#lib/components/shared-components/search-bar/SearchBar.svelte';
  import SkipLink from '#lib/elements/SkipLink.svelte';
  import { authManager } from '#lib/managers/auth-manager.svelte.ts';
  import { getNotificationsQuery } from '#lib/queries/notification.query.ts';
  import { Route } from '#lib/route.ts';
  import { getGlobalActions } from '#lib/services/app.service.ts';
  import { ActionButton, Icon, IconButton } from '@immich/ui';
  import {
    mdiAccountGroup,
    mdiAccountGroupOutline,
    mdiAutoFix,
    mdiBellBadge,
    mdiBellOutline,
    mdiBookMultiple,
    mdiBookMultipleOutline,
    mdiCogOutline,
    mdiCreation,
    mdiCreationOutline,
    mdiDiamondStone,
    mdiDotsGrid,
    mdiHeart,
    mdiHeartOutline,
    mdiMagnify,
    mdiViewGrid,
  } from '@mdi/js';
  import { createQuery } from '@tanstack/svelte-query';
  import { t } from 'svelte-i18n';
  import { page } from '$app/state';
  import ThemeButton from '../ThemeButton.svelte';
  import UserAvatar from '../UserAvatar.svelte';
  import AccountInfoPanel from './AccountInfoPanel.svelte';
  import OneDriveAppLauncher from './OneDriveAppLauncher.svelte';
  import OneDriveStorageModal from './OneDriveStorageModal.svelte';

  type Props = {
    onUploadClick?: () => void;
    noBorder?: boolean;
  };

  let { onUploadClick, noBorder = false }: Props = $props();

  let shouldShowAccountInfoPanel = $state(false);
  let shouldShowNotificationPanel = $state(false);
  let shouldShowAppLauncher = $state(false);
  let shouldShowStorageModal = $state(false);
  let innerWidth: number = $state(0);

  const query = createQuery(getNotificationsQuery);
  const unreadCount = $derived(query.data?.length ?? 0);
  const hasUnreadNotifications = $derived(unreadCount > 0);

  const { Cast } = $derived(getGlobalActions($t));

  // OneDrive route active states
  const pathname = $derived(page.url.pathname);
  const isMoments = $derived(pathname.startsWith('/memories'));
  const isGallery = $derived(pathname === '/photos' || pathname === '/' || pathname.startsWith('/photos/'));
  const isPeople = $derived(pathname.startsWith('/people'));
  const isAlbums = $derived(pathname.startsWith('/albums'));
  const isAutoAlbums = $derived(pathname.startsWith('/auto-albums'));
  const isFavorites = $derived(pathname.startsWith('/favorites'));
  const isFiles = $derived(pathname.startsWith('/folders'));
  const isPhotosTab = $derived(!isFiles);
</script>

<svelte:window bind:innerWidth />

<nav id="dashboard-navbar" class="h-(--navbar-height) w-dvw text-sm max-md:h-(--navbar-height-md) border-b border-white/10 bg-neutral-950/80 backdrop-blur-xl px-3 select-none">
  <SkipLink text={$t('skip_to_content')} />
  <div class="flex h-full items-center justify-between gap-3">
    <!-- Left: 9-dot launcher, OneDrive Cloud Logo, Segmented Pill [ Photos | Files ] -->
    <div class="flex items-center gap-2 sm:gap-3 shrink-0">
      <IconButton
        id={menuButtonId}
        shape="round"
        color="secondary"
        variant="ghost"
        size="medium"
        aria-label="App Launcher"
        title="Microsoft 365 & Immich App Launcher"
        icon={mdiDotsGrid}
        onclick={() => (shouldShowAppLauncher = !shouldShowAppLauncher)}
      />

      <!-- OneDrive Cloud Logo -->
      <a data-sveltekit-preload-data="hover" href={Route.photos()} class="flex items-center gap-2 group" title="OneDrive Photos">
        <svg viewBox="0 0 32 32" class="size-7 transition-transform group-hover:scale-105" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M21.5 13.5C21.5 10.46 19.04 8 16 8C13.48 8 11.36 9.7 10.7 12.02C10.22 11.85 9.7 11.75 9.17 11.75C6.87 11.75 5 13.62 5 15.92C5 16.27 5.05 16.6 5.13 16.92C3.33 17.65 2 19.42 2 21.5C2 24.54 4.46 27 7.5 27H22.5C26.64 27 30 23.64 30 19.5C30 15.62 27.05 12.44 23.27 12.06C22.84 12.87 22.21 13.56 21.5 13.5Z" fill="url(#onedrive-grad)" />
          <defs>
            <linearGradient id="onedrive-grad" x1="2" y1="8" x2="30" y2="27" gradientUnits="userSpaceOnUse">
              <stop stop-color="#2886DE" />
              <stop offset="0.5" stop-color="#0078D4" />
              <stop offset="1" stop-color="#005A9E" />
            </linearGradient>
          </defs>
        </svg>
      </a>

      <!-- Segmented Pill Switch [ Photos | Files ] (Reference Screenshot 10) -->
      <div class="flex items-center rounded-full bg-neutral-900/90 border border-white/10 p-1 shadow-inner">
        <a
          data-sveltekit-preload-data="hover"
          href={Route.photos()}
          class="rounded-full px-3 py-1 text-xs transition-all {isPhotosTab ? 'bg-white/15 text-white font-semibold shadow-xs' : 'text-neutral-400 hover:text-white'}"
        >
          Photos
        </a>
        <a
          data-sveltekit-preload-data="hover"
          href={Route.folders()}
          class="rounded-full px-3 py-1 text-xs transition-all {isFiles ? 'bg-white/15 text-white font-semibold shadow-xs' : 'text-neutral-400 hover:text-white'}"
        >
          Files
        </a>
      </div>
    </div>

    <!-- Center: Primary OneDrive Navigation (Reference Screenshot 10) -->
    <div class="hidden md:flex items-center gap-6 lg:gap-8">
      <!-- Moments -->
      <a
        data-sveltekit-preload-data="hover"
        href={Route.memories()}
        class="group flex flex-col items-center gap-0.5 transition-all {isMoments ? 'text-white' : 'text-neutral-400 hover:text-neutral-200'}"
      >
        <div class="relative flex items-center justify-center">
          <Icon icon={isMoments ? mdiCreation : mdiCreationOutline} size="20px" class="transition-transform group-hover:scale-110 {isMoments ? 'text-purple-400' : ''}" />
          {#if isMoments}
            <span class="absolute -bottom-2 left-1/2 -translate-x-1/2 h-0.5 w-4 rounded-full bg-purple-500"></span>
          {/if}
        </div>
        <span class="text-[11px] {isMoments ? 'font-bold text-white' : 'font-medium'}">Moments</span>
      </a>

      <!-- Gallery -->
      <a
        data-sveltekit-preload-data="hover"
        href={Route.photos()}
        class="group flex flex-col items-center gap-0.5 transition-all {isGallery ? 'text-white' : 'text-neutral-400 hover:text-neutral-200'}"
      >
        <div class="relative flex items-center justify-center">
          <Icon icon={mdiViewGrid} size="20px" class="transition-transform group-hover:scale-110 {isGallery ? 'text-blue-400' : ''}" />
          {#if isGallery}
            <span class="absolute -bottom-2 left-1/2 -translate-x-1/2 h-0.5 w-4 rounded-full bg-blue-500"></span>
          {/if}
        </div>
        <span class="text-[11px] {isGallery ? 'font-bold text-white' : 'font-medium'}">Gallery</span>
      </a>

      <!-- People -->
      <a
        data-sveltekit-preload-data="hover"
        href={Route.people()}
        class="group flex flex-col items-center gap-0.5 transition-all {isPeople ? 'text-white' : 'text-neutral-400 hover:text-neutral-200'}"
      >
        <div class="relative flex items-center justify-center">
          <Icon icon={isPeople ? mdiAccountGroup : mdiAccountGroupOutline} size="20px" class="transition-transform group-hover:scale-110 {isPeople ? 'text-amber-400' : ''}" />
          {#if isPeople}
            <span class="absolute -bottom-2 left-1/2 -translate-x-1/2 h-0.5 w-4 rounded-full bg-amber-500"></span>
          {/if}
        </div>
        <span class="text-[11px] {isPeople ? 'font-bold text-white' : 'font-medium'}">People</span>
      </a>

      <!-- Albums -->
      <a
        data-sveltekit-preload-data="hover"
        href={Route.albums()}
        class="group flex flex-col items-center gap-0.5 transition-all {isAlbums ? 'text-white' : 'text-neutral-400 hover:text-neutral-200'}"
      >
        <div class="relative flex items-center justify-center">
          <Icon icon={isAlbums ? mdiBookMultiple : mdiBookMultipleOutline} size="20px" class="transition-transform group-hover:scale-110 {isAlbums ? 'text-emerald-400' : ''}" />
          {#if isAlbums}
            <span class="absolute -bottom-2 left-1/2 -translate-x-1/2 h-0.5 w-4 rounded-full bg-emerald-500"></span>
          {/if}
        </div>
        <span class="text-[11px] {isAlbums ? 'font-bold text-white' : 'font-medium'}">Albums</span>
      </a>

      <!-- Auto Albums -->
      <a
        data-sveltekit-preload-data="hover"
        href={Route.autoAlbums()}
        class="group flex flex-col items-center gap-0.5 transition-all {isAutoAlbums ? 'text-white' : 'text-neutral-400 hover:text-neutral-200'}"
      >
        <div class="relative flex items-center justify-center">
          <Icon icon={mdiAutoFix} size="20px" class="transition-transform group-hover:scale-110 {isAutoAlbums ? 'text-pink-400' : ''}" />
          {#if isAutoAlbums}
            <span class="absolute -bottom-2 left-1/2 -translate-x-1/2 h-0.5 w-4 rounded-full bg-pink-500"></span>
          {/if}
        </div>
        <span class="text-[11px] {isAutoAlbums ? 'font-bold text-white' : 'font-medium'}">Auto Albums</span>
      </a>

      <!-- Favorites -->
      <a
        data-sveltekit-preload-data="hover"
        href={Route.favorites()}
        class="group flex flex-col items-center gap-0.5 transition-all {isFavorites ? 'text-white' : 'text-neutral-400 hover:text-neutral-200'}"
      >
        <div class="relative flex items-center justify-center">
          <Icon icon={isFavorites ? mdiHeart : mdiHeartOutline} size="20px" class="transition-transform group-hover:scale-110 {isFavorites ? 'text-rose-400' : ''}" />
          {#if isFavorites}
            <span class="absolute -bottom-2 left-1/2 -translate-x-1/2 h-0.5 w-4 rounded-full bg-rose-500"></span>
          {/if}
        </div>
        <span class="text-[11px] {isFavorites ? 'font-bold text-white' : 'font-medium'}">Favorites</span>
      </a>
    </div>

    <!-- Right: Search, Storage, Notifications, Settings, Avatar (Reference Screenshot 10) -->
    <div class="flex items-center gap-2 sm:gap-3 shrink-0">
      <!-- Search Input / Bar -->
      <div class="hidden xl:block w-72">
        <SearchBar grayTheme={true} />
      </div>

      <IconButton
        color="secondary"
        shape="round"
        variant="ghost"
        size="medium"
        icon={mdiMagnify}
        href={Route.search()}
        id="search-button"
        class="xl:hidden"
        aria-label={$t('go_to_search')}
      />

      <!-- Get More Storage Pill (Reference Screenshot 10) -->
      <button
        type="button"
        onclick={() => (shouldShowStorageModal = true)}
        class="hidden sm:flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-gradient-to-r from-purple-500/20 via-indigo-500/20 to-pink-500/10 border border-purple-500/30 hover:border-purple-400/60 text-purple-200 hover:text-white text-xs font-medium transition-all shadow-xs cursor-pointer group"
        title="Storage & Supporter License"
      >
        <Icon icon={mdiDiamondStone} size="16px" class="text-purple-400 group-hover:scale-110 transition-transform" />
        <span class="tracking-tight">Get more storage</span>
      </button>

      <ThemeButton />

      <!-- Notifications -->
      <div
        {@attach clickOutside({
          onOutclick: () => (shouldShowNotificationPanel = false),
          onEscape: () => (shouldShowNotificationPanel = false),
        })}
      >
        <div class="relative">
          <IconButton
            shape="round"
            color={hasUnreadNotifications ? 'primary' : 'secondary'}
            variant="ghost"
            size="medium"
            icon={hasUnreadNotifications ? mdiBellBadge : mdiBellOutline}
            onclick={() => (shouldShowNotificationPanel = !shouldShowNotificationPanel)}
            aria-label={$t('notifications')}
          />

          {#if hasUnreadNotifications}
            <div
              class="pointer-events-none absolute top-0 right-1 flex size-5 items-center justify-center rounded-full border bg-primary text-[10px] font-bold text-light"
            >
              {unreadCount}
            </div>
          {/if}
        </div>

        {#if shouldShowNotificationPanel}
          <NotificationPanel />
        {/if}
      </div>

      <ActionButton action={Cast} />

      <!-- Settings Icon (Reference Screenshot 10) -->
      <IconButton
        href={Route.userSettings()}
        shape="round"
        color="secondary"
        variant="ghost"
        size="medium"
        icon={mdiCogOutline}
        title={$t('settings')}
        aria-label={$t('settings')}
      />

      <!-- User Avatar -->
      <div
        {@attach clickOutside({
          onOutclick: () => (shouldShowAccountInfoPanel = false),
          onEscape: () => (shouldShowAccountInfoPanel = false),
        })}
      >
        <button
          type="button"
          class="flex ps-1 cursor-pointer"
          onclick={() => (shouldShowAccountInfoPanel = !shouldShowAccountInfoPanel)}
          title="{authManager.user.name} ({authManager.user.email})"
        >
          {#key authManager.user}
            <UserAvatar user={authManager.user} size="md" noTitle interactive />
          {/key}
        </button>

        {#if shouldShowAccountInfoPanel}
          <AccountInfoPanel onClose={() => (shouldShowAccountInfoPanel = false)} />
        {/if}
      </div>
    </div>
  </div>
</nav>

{#if shouldShowAppLauncher}
  <OneDriveAppLauncher onClose={() => (shouldShowAppLauncher = false)} />
{/if}

{#if shouldShowStorageModal}
  <OneDriveStorageModal onClose={() => (shouldShowStorageModal = false)} />
{/if}
