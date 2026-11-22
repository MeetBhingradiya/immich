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
  import { mediaQueryManager } from '#lib/stores/media-query-manager.svelte.ts';
  import { sidebarStore } from '#lib/stores/sidebar.svelte.ts';
  import { ActionButton, Button, IconButton, Logo } from '@immich/ui';
  import { mdiBellBadge, mdiBellOutline, mdiMagnify, mdiMenu, mdiTrayArrowUp } from '@mdi/js';
  import { createQuery } from '@tanstack/svelte-query';
  import { t } from 'svelte-i18n';
  import { page } from '$app/state';
  import ThemeButton from '../ThemeButton.svelte';
  import UserAvatar from '../UserAvatar.svelte';
  import AccountInfoPanel from './AccountInfoPanel.svelte';

  type Props = {
    onUploadClick?: () => void;
    // TODO: remove once this is only used in <AppShellHeader>
    noBorder?: boolean;
  };

  let { onUploadClick, noBorder = false }: Props = $props();

  let shouldShowAccountInfoPanel = $state(false);
  let shouldShowNotificationPanel = $state(false);
  let innerWidth: number = $state(0);
  const query = createQuery(getNotificationsQuery);
  const unreadCount = $derived(query.data?.length ?? 0);
  const hasUnreadNotifications = $derived(unreadCount > 0);

  const { Cast } = $derived(getGlobalActions($t));
</script>

<svelte:window bind:innerWidth />

<nav id="dashboard-navbar" class="h-(--navbar-height) w-dvw text-sm max-md:h-(--navbar-height-md)">
  <SkipLink text={$t('skip_to_content')} />
  <div
    class="flex h-full items-center justify-between py-2 px-3 gap-3 {noBorder ? '' : 'border-b'}"
  >
    <div class="flex flex-row items-center gap-2 shrink-0">
      <IconButton
        id={menuButtonId}
        shape="round"
        color="secondary"
        variant="ghost"
        size="medium"
        aria-label={$t('main_menu')}
        title={mediaQueryManager.isFullSidebar ? (sidebarStore.isCollapsed ? 'Expand sidebar' : 'Collapse sidebar') : $t('main_menu')}
        icon={mdiMenu}
        onclick={() => {
          sidebarStore.toggle();
        }}
        onmousedown={(event: MouseEvent) => {
          if (sidebarStore.isOpen && !mediaQueryManager.isFullSidebar) {
            // stops event from reaching the default handler when clicking outside of the sidebar on mobile
            event.stopPropagation();
          }
        }}
      />
      <a data-sveltekit-preload-data="hover" href={Route.photos()} class="flex items-center">
        <Logo variant={mediaQueryManager.isFullSidebar ? (sidebarStore.isCollapsed ? 'icon' : 'inline') : 'icon'} class="max-md:h-12" />
      </a>
    </div>
    <div class="flex flex-1 items-center justify-between gap-4 pe-2 lg:gap-8 max-w-5xl">
      <div class="hidden w-full max-w-5xl flex-1 sm:block tall:ps-0">
        <SearchBar grayTheme={true} />
      </div>

      <section class="flex w-full place-items-center justify-end gap-1 sm:w-auto md:gap-2">
        <IconButton
          color="secondary"
          shape="round"
          variant="ghost"
          size="medium"
          icon={mdiMagnify}
          href={Route.search()}
          id="search-button"
          class="sm:hidden"
          aria-label={$t('go_to_search')}
        />

        {#if !page.url.pathname.includes('/admin') && onUploadClick}
          <Button
            leadingIcon={mdiTrayArrowUp}
            onclick={onUploadClick}
            class="hidden lg:flex"
            variant="ghost"
            size="medium"
            color="secondary"
            >{$t('upload')}
          </Button>
          <IconButton
            color="secondary"
            shape="round"
            variant="ghost"
            size="medium"
            onclick={onUploadClick}
            title={$t('upload')}
            aria-label={$t('upload')}
            icon={mdiTrayArrowUp}
            class="lg:hidden"
          />
        {/if}

        <ThemeButton />

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

        <div
          {@attach clickOutside({
            onOutclick: () => (shouldShowAccountInfoPanel = false),
            onEscape: () => (shouldShowAccountInfoPanel = false),
          })}
        >
          <button
            type="button"
            class="flex ps-2"
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
      </section>
    </div>
  </div>
</nav>
