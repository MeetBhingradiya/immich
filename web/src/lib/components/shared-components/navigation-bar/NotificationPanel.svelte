<script lang="ts">
  import { focusTrap } from '#lib/actions/focus-trap.ts';
  import { portal } from '#lib/elements/Portal.svelte';
  import NotificationItem from '#lib/components/shared-components/navigation-bar/NotificationItem.svelte';
  import { OpenQueryParam } from '#lib/constants.ts';
  import { executeMutation } from '#lib/queries/client.ts';
  import {
    getNotificationsQuery,
    updateNotificationMutation,
    updateNotificationsMutation,
  } from '#lib/queries/notification.query.ts';
  import { Route } from '#lib/route.ts';
  import { NotificationType, type NotificationDto } from '@immich/sdk';
  import { Icon, Scrollable } from '@immich/ui';
  import { mdiBellOutline, mdiCheckAll } from '@mdi/js';
  import { createQuery } from '@tanstack/svelte-query';
  import { t } from 'svelte-i18n';
  import { flip } from 'svelte/animate';
  import { fade, scale } from 'svelte/transition';
  import { goto } from '$app/navigation';

  interface Props {
    onClose?: () => void;
  }

  let { onClose }: Props = $props();

  const query = createQuery(getNotificationsQuery);
  const notifications = $derived(query.data ?? []);
  const noUnreadNotifications = $derived(notifications.length === 0);

  const markAllAsRead = () =>
    executeMutation(updateNotificationsMutation, [
      { notificationUpdateAllDto: { ids: notifications.map(({ id }) => id), readAt: new Date().toISOString() } },
    ]);

  const handleNotificationAction = async (notification: NotificationDto) => {
    switch (notification.type) {
      case NotificationType.AlbumInvite:
      case NotificationType.AlbumUpdate: {
        if (!notification.data) {
          return;
        }

        if (typeof notification.data !== 'string') {
          return;
        }

        const data = JSON.parse(notification.data);
        if (data?.albumId) {
          await goto(`/albums/${data.albumId}`);
        }

        break;
      }

      case NotificationType.ClusterGroupRequest: {
        await goto(Route.userSettings({ isOpen: OpenQueryParam.SHARING }));
        break;
      }

      default: {
        break;
      }
    }
  };

  const onclick = (notification: NotificationDto) =>
    executeMutation(
      updateNotificationMutation,
      [{ id: notification.id, notificationUpdateDto: { readAt: new Date().toISOString() } }],
      { onSuccess: () => void handleNotificationAction(notification) },
    );
</script>

<div {@attach portal('body')}>
  <!-- Backdrop to dismiss: fixed inset-0 z-[99998] bg-black/40 backdrop-blur-xs -->
  <div
    transition:fade={{ duration: 120 }}
    class="fixed inset-0 z-[99998] bg-black/40 backdrop-blur-xs"
    onclick={onClose}
    role="presentation"
  ></div>

  <!-- OneDrive Exact Notification Flyout (Teleported to body, z-[99999]) -->
  <div
    in:scale={{ start: 0.96, duration: 160 }}
    out:fade={{ duration: 100 }}
    id="notification-panel"
    class="fixed top-15 right-4 sm:right-6 z-[99999] w-[360px] max-w-[calc(100vw-32px)] rounded-2xl border border-white/15 bg-[#1e1e1e] p-5 text-white shadow-[0_24px_64px_rgba(0,0,0,0.9)] select-none"
    {@attach focusTrap()}
    role="dialog"
    aria-label="Notifications"
  >
    <div class="flex items-center justify-between pb-3.5 border-b border-white/10">
      <span class="text-sm font-semibold tracking-tight text-white font-['Segoe_UI',sans-serif]">
        {$t('notifications')}
      </span>
      <div>
        <button
          type="button"
          disabled={noUnreadNotifications}
          class="flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium text-neutral-300 hover:text-white hover:bg-white/10 transition-colors disabled:opacity-40 disabled:cursor-not-allowed cursor-pointer"
          onclick={() => markAllAsRead()}
        >
          <Icon icon={mdiCheckAll} size="14" class="text-[#0078d4]" />
          <span>{$t('mark_all_as_read')}</span>
        </button>
      </div>
    </div>

    {#if noUnreadNotifications}
      <div class="flex flex-col items-center justify-center py-10 text-neutral-400">
        <div class="flex size-12 items-center justify-center rounded-full bg-white/5 mb-3 text-neutral-400">
          <Icon icon={mdiBellOutline} size="22" />
        </div>
        <p class="text-xs font-semibold text-neutral-200">{$t('no_notifications')}</p>
        <p class="text-[11px] text-neutral-500 mt-1">You're completely caught up</p>
      </div>
    {:else}
      <Scrollable class="max-h-96 immich-scrollbar overflow-y-auto pt-2">
        {#each notifications as notification (notification.id)}
          <div animate:flip={{ duration: 150 }}>
            <NotificationItem {notification} {onclick} />
          </div>
        {/each}
      </Scrollable>
    {/if}
  </div>
</div>
