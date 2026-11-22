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
    mdiFolder,
    mdiFolderOutline,
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
  import { fade } from 'svelte/transition';
  import { page } from '$app/state';
  import ThemeButton from '../ThemeButton.svelte';
  import UserAvatar from '../UserAvatar.svelte';
  import AccountInfoPanel from './AccountInfoPanel.svelte';
  import CircularStorageIndicator from './CircularStorageIndicator.svelte';

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

  // Dynamic Navigation Items matching feature settings
  const navItems = $derived([
    {
      id: 'moments',
      label: 'Moments',
      href: Route.moments(),
      icon: mdiCreationOutline,
      activeIcon: mdiCreation,
      activeColor: 'text-purple-400',
      indicatorColor: 'bg-purple-500',
      isActive: pathname.startsWith('/moments') || pathname.startsWith('/memories'),
    },
    {
      id: 'gallery',
      label: 'Gallery',
      href: Route.photos(),
      icon: mdiImageMultipleOutline,
      activeIcon: mdiImageMultiple,
      activeColor: 'text-blue-400',
      indicatorColor: 'bg-blue-500',
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
            activeColor: 'text-amber-400',
            indicatorColor: 'bg-amber-500',
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
      activeColor: 'text-emerald-400',
      indicatorColor: 'bg-emerald-500',
      isActive: pathname.startsWith('/albums') || pathname.startsWith('/auto-albums'),
    },
    {
      id: 'favorites',
      label: 'Favorites',
      href: Route.favorites(),
      icon: mdiHeartOutline,
      activeIcon: mdiHeart,
      activeColor: 'text-rose-400',
      indicatorColor: 'bg-rose-500',
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
            activeColor: 'text-teal-400',
            indicatorColor: 'bg-teal-500',
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
      activeColor: 'text-indigo-400',
      indicatorColor: 'bg-indigo-500',
      isActive: pathname.startsWith('/explore') || pathname.startsWith('/search'),
    },
    ...(authManager.preferences.folders?.enabled && authManager.preferences.folders?.sidebarWeb
      ? [
          {
            id: 'folders',
            label: 'Folders',
            href: Route.folders(),
            icon: mdiFolderOutline,
            activeIcon: mdiFolder,
            activeColor: 'text-sky-400',
            indicatorColor: 'bg-sky-500',
            isActive: pathname.startsWith('/folders'),
          },
        ]
      : []),
  ]);
</script>

<svelte:window bind:innerWidth />

<nav id="dashboard-navbar" class="relative z-50 h-(--navbar-height) w-dvw text-sm max-md:h-(--navbar-height-md) border-b border-white/10 bg-neutral-950/80 backdrop-blur-xl px-6 sm:px-8 select-none">
  <SkipLink text={$t('skip_to_content')} />
  <div class="flex h-full items-center justify-between gap-4">
    <!-- Left: Immich Logo + OneDrive-style [ Photos | Folders ] Capsule -->
    <div class="flex items-center gap-3 shrink-0">
      <a data-sveltekit-preload-data="hover" href={Route.photos()} class="flex items-center gap-2 group" title="Immich">
        <Logo variant="inline" class="h-8.5 sm:h-9 max-md:h-7 transition-transform duration-200 group-hover:scale-105" />
      </a>

      <!-- OneDrive-style [ Photos | Folders ] segmented capsule -->
      <div class="hidden sm:flex items-center p-0.5 rounded-full bg-white/8 border border-white/10 text-xs font-semibold backdrop-blur-md select-none">
        <a
          data-sveltekit-preload-data="hover"
          href={Route.photos()}
          class="px-3 py-1 rounded-full transition-all duration-200 {pathname !== '/folders' ? 'bg-white text-black font-semibold shadow-xs' : 'text-neutral-400 hover:text-white'}"
        >
          Photos
        </a>
        <a
          data-sveltekit-preload-data="hover"
          href={Route.folders()}
          class="px-3 py-1 rounded-full transition-all duration-200 {pathname === '/folders' ? 'bg-white text-black font-semibold shadow-xs' : 'text-neutral-400 hover:text-white'}"
        >
          Folders
        </a>
      </div>
    </div>

    <!-- Middle: Dynamic Nav Items with Icons & Labels (Settings-controllable) -->
    <div class="flex items-center justify-center gap-1 sm:gap-2 lg:gap-3 h-full">
      {#each navItems as item (item.id)}
        <a
          data-sveltekit-preload-data="hover"
          href={item.href}
          class="relative flex flex-col items-center justify-center h-12 my-auto px-3.5 sm:px-4 rounded-2xl transition-all duration-200 ease-out select-none group
            {item.isActive 
              ? 'bg-white/12 text-white shadow-xs font-semibold' 
              : 'text-neutral-400 hover:text-white hover:bg-white/6 font-medium'}"
          title={item.label}
        >
          <div class="flex items-center justify-center transition-all duration-200 group-hover:scale-110">
            <Icon
              icon={item.isActive ? item.activeIcon : item.icon}
              size="22px"
              class="transition-colors duration-200 {item.isActive ? item.activeColor : ''}"
            />
          </div>

          {#if !$hideTopNavLabels}
            <span class="text-[11px] mt-0.5 tracking-tight transition-colors duration-200">
              {item.label}
            </span>
          {/if}

          <!-- Active Page Indicator: Smooth glowing bottom accent bar -->
          {#if item.isActive}
            <span
              in:fade={{ duration: 200 }}
              out:fade={{ duration: 150 }}
              class="absolute bottom-1 inset-x-2.5 h-[2.5px] rounded-full {item.indicatorColor} shadow-[0_0_8px_currentColor] transition-all duration-300"
            ></span>
          {/if}
        </a>
      {/each}
    </div>

    <!-- Right: Circular Storage Gauge, Notifications, Cast, Theme, Settings, User Avatar -->
    <div class="flex items-center gap-2 sm:gap-3 shrink-0">
      <!-- Google Photos Style Circular Storage Indicator -->
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
          <NotificationPanel />
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

      <!-- User Avatar -->
      <div
        class="relative"
        {@attach clickOutside({
          onOutclick: () => (shouldShowAccountInfoPanel = false),
          onEscape: () => (shouldShowAccountInfoPanel = false),
        })}
      >
        <button
          type="button"
          class="flex ps-1 cursor-pointer transition-transform duration-200 hover:scale-105 active:scale-95"
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
