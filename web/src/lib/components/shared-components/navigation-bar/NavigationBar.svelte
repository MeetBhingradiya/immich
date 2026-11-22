<script lang="ts" module>
  export const menuButtonId = 'top-menu-button';
</script>

<script lang="ts">
  import { clickOutside } from '#lib/actions/click-outside.ts';
  import NotificationPanel from '#lib/components/shared-components/navigation-bar/NotificationPanel.svelte';
  import SkipLink from '#lib/elements/SkipLink.svelte';
  import { authManager } from '#lib/managers/auth-manager.svelte.ts';
  import { createPreloadedQuery } from '#lib/queries/client.ts';
  import { getUserConfigQuery } from '#lib/queries/config-user.query.ts';
  import { getNotificationsQuery } from '#lib/queries/notification.query.ts';
  import { Route } from '#lib/route.ts';
  import { getGlobalActions } from '#lib/services/app.service.ts';
  import { hideTopNavLabels } from '#lib/stores/preferences.store.ts';
  import { ActionButton, Icon, IconButton, Logo } from '@immich/ui';
  import {
    mdiAccount,
    mdiAccountOutline,
    mdiBellBadge,
    mdiBellOutline,
    mdiBookMultiple,
    mdiBookMultipleOutline,
    mdiCogOutline,
    mdiCreation,
    mdiCreationOutline,
    mdiHeart,
    mdiHeartOutline,
    mdiImageMultiple,
    mdiImageMultipleOutline,
    mdiMagnify,
    mdiMap,
    mdiMapOutline,
  } from '@mdi/js';
  import { createQuery } from '@tanstack/svelte-query';
  import { t } from 'svelte-i18n';
  import { crossfade, fade } from 'svelte/transition';
  import { cubicOut } from 'svelte/easing';
  import { page } from '$app/state';
  import ThemeButton from '../ThemeButton.svelte';
  import UserAvatar from '../UserAvatar.svelte';
  import AccountInfoPanel from './AccountInfoPanel.svelte';
  import CircularStorageIndicator from './CircularStorageIndicator.svelte';

  const [send, receive] = crossfade({
    duration: 260,
    easing: cubicOut,
    fallback: (node) => fade(node, { duration: 150 }),
  });

  type Props = {
    onUploadClick?: () => void;
    noBorder?: boolean;
  };

  let { onUploadClick, noBorder = false }: Props = $props();

  let shouldShowAccountInfoPanel = $state(false);
  let shouldShowNotificationPanel = $state(false);
  let innerWidth: number = $state(0);

  const configQuery = createPreloadedQuery(getUserConfigQuery);
  const config = $derived(configQuery.data);

  const query = createQuery(getNotificationsQuery);
  const unreadCount = $derived(query.data?.length ?? 0);
  const hasUnreadNotifications = $derived(unreadCount > 0);

  const { Cast } = $derived(getGlobalActions($t));

  const pathname = $derived(page.url.pathname);

  // Dynamic Navigation Items matching OneDrive layout & user feature preferences
  const navItems = $derived([
    {
      id: 'moments',
      label: 'Moments',
      href: Route.moments(),
      icon: mdiCreationOutline,
      activeIcon: mdiCreation,
      isActive: pathname.startsWith('/moments') || pathname.startsWith('/memories'),
    },
    {
      id: 'gallery',
      label: 'Gallery',
      href: Route.photos(),
      icon: mdiImageMultipleOutline,
      activeIcon: mdiImageMultiple,
      isActive: pathname === '/photos' || pathname === '/' || pathname.startsWith('/photos/'),
    },
    ...(authManager.preferences.people?.enabled && authManager.preferences.people?.sidebarWeb
      ? [
          {
            id: 'people',
            label: 'People',
            href: Route.people(),
            icon: mdiAccountOutline,
            activeIcon: mdiAccount,
            isActive: pathname.startsWith('/people'),
          },
        ]
      : []),
    {
      id: 'albums',
      label: 'Albums',
      href: Route.albums(),
      icon: mdiBookMultipleOutline,
      activeIcon: mdiBookMultiple,
      isActive: pathname.startsWith('/albums') || pathname.startsWith('/auto-albums'),
    },
    {
      id: 'favorites',
      label: 'Favorites',
      href: Route.favorites(),
      icon: mdiHeartOutline,
      activeIcon: mdiHeart,
      isActive: pathname.startsWith('/favorites'),
    },
    ...(config?.map?.enabled
      ? [
          {
            id: 'map',
            label: 'Map',
            href: Route.map(),
            icon: mdiMapOutline,
            activeIcon: mdiMap,
            isActive: pathname.startsWith('/map'),
          },
        ]
      : []),
    {
      id: 'explore',
      label: 'Explore',
      href: Route.explore(),
      icon: mdiMagnify,
      activeIcon: mdiMagnify,
      isActive: pathname.startsWith('/explore') || pathname.startsWith('/search'),
    },
  ]);
</script>

<svelte:window bind:innerWidth />

<!-- Fixed 56px Top Navigation Bar (OneDrive exact Fluent Dark Header) -->
<nav
  id="dashboard-navbar"
  class="relative z-[9900] h-14 w-dvw text-sm border-b border-white/10 bg-[#141414]/95 backdrop-blur-xl px-4 sm:px-6 select-none"
>
  <SkipLink text={$t('skip_to_content')} />
  <div class="flex h-full items-center justify-between gap-4">
    <!-- Left: Immich Logo + [ Photos | Folders ] Capsule -->
    <div class="flex items-center gap-3.5 shrink-0">
      <a data-sveltekit-preload-data="hover" href={Route.photos()} class="flex items-center gap-2 group" title="Immich">
        <Logo variant="inline" class="h-9 sm:h-9.5 max-md:h-7.5 transition-transform duration-200 group-hover:scale-105" />
      </a>

      <!-- OneDrive [ Photos | Folders ] segmented capsule -->
      <div class="hidden sm:flex items-center p-0.5 rounded-full bg-white/8 border border-white/10 text-xs font-semibold backdrop-blur-md select-none">
        <a
          data-sveltekit-preload-data="hover"
          href={Route.photos()}
          class="px-3.5 py-1 rounded-full transition-all duration-150 {pathname !== '/folders' ? 'bg-[#2b2b2b] text-white font-semibold shadow-xs' : 'text-neutral-400 hover:text-white'}"
        >
          Photos
        </a>
        <a
          data-sveltekit-preload-data="hover"
          href={Route.folders()}
          class="px-3.5 py-1 rounded-full transition-all duration-150 {pathname === '/folders' ? 'bg-[#2b2b2b] text-white font-semibold shadow-xs' : 'text-neutral-400 hover:text-white'}"
        >
          Folders
        </a>
      </div>
    </div>

    <!-- Middle: Center Nav Tabs with Stacked Icon & Label + Smooth Sliding Active Underline -->
    <div class="flex items-center justify-center gap-0.5 sm:gap-1 lg:gap-2 h-full">
      {#each navItems as item (item.id)}
        <a
          data-sveltekit-preload-data="hover"
          href={item.href}
          class="relative flex flex-col items-center justify-center h-full px-2.5 sm:px-3.5 transition-all duration-150 ease-out select-none group rounded-xl
            {item.isActive 
              ? 'text-white' 
              : 'text-[#a6a6a6] hover:text-white hover:bg-white/5'}"
          title={item.label}
        >
          <div class="flex items-center justify-center transition-transform duration-150 group-hover:scale-105">
            <Icon
              icon={item.isActive ? item.activeIcon : item.icon}
              size="20px"
              class="transition-colors duration-150 {item.isActive ? 'text-[#0078d4]' : 'text-neutral-400 group-hover:text-white'}"
            />
          </div>

          {#if !$hideTopNavLabels}
            <span class="text-[11px] font-medium mt-0.5 tracking-tight transition-colors duration-150 {item.isActive ? 'text-white' : 'text-[#a6a6a6] group-hover:text-white'}">
              {item.label}
            </span>
          {/if}

          <!-- Active Page Indicator: Smooth crossfade gliding blue underline (#0078d4) -->
          {#if item.isActive}
            <span
              in:receive={{ key: 'top-nav-active-pill' }}
              out:send={{ key: 'top-nav-active-pill' }}
              class="absolute bottom-0 inset-x-2 h-[2.5px] rounded-full bg-[#0078d4] shadow-[0_0_10px_rgba(0,120,212,0.9)]"
            ></span>
          {/if}
        </a>
      {/each}
    </div>

    <!-- Right: Storage Indicator, Theme, Notifications, Settings, User Avatar -->
    <div class="flex items-center gap-1.5 sm:gap-2.5 shrink-0">
      <!-- Storage Gauge -->
      <CircularStorageIndicator />

      <ThemeButton />

      <!-- Notifications -->
      <div
        class="relative"
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
          <NotificationPanel onClose={() => (shouldShowNotificationPanel = false)} />
        {/if}
      </div>

      <ActionButton action={Cast} />

      <!-- Settings Icon -->
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

      <!-- User Avatar (Triggers fixed Account Flyout teleported to body) -->
      <div class="relative">
        <button
          type="button"
          class="flex ps-1 cursor-pointer transition-transform duration-150 hover:scale-105 active:scale-95"
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
