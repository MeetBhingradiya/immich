<script lang="ts">
  import { focusTrap } from '#lib/actions/focus-trap.ts';
  import { portal } from '#lib/elements/Portal.svelte';
  import { authManager } from '#lib/managers/auth-manager.svelte.ts';
  import AvatarEditModal from '#lib/modals/AvatarEditModal.svelte';
  import HelpAndFeedbackModal from '#lib/modals/HelpAndFeedbackModal.svelte';
  import { getAboutInfoQuery } from '#lib/queries/server-info.query.ts';
  import { Route } from '#lib/route.ts';
  import { Icon, modalManager } from '@immich/ui';
  import { mdiCogOutline, mdiLogout, mdiPencil, mdiShieldAccountOutline } from '@mdi/js';
  import { createQuery } from '@tanstack/svelte-query';
  import { t } from 'svelte-i18n';
  import { fade, scale } from 'svelte/transition';
  import { page } from '$app/state';
  import UserAvatar from '../UserAvatar.svelte';

  type Props = {
    onClose?: () => void;
  };

  let { onClose }: Props = $props();

  const query = createQuery(getAboutInfoQuery);
  const info = $derived(query.data);
</script>

<div {@attach portal('body')}>
  <!-- Backdrop to dismiss: fixed inset-0 z-[99998] bg-black/50 backdrop-blur-xs -->
  <div
    transition:fade={{ duration: 120 }}
    class="fixed inset-0 z-[99998] bg-black/50 backdrop-blur-xs"
    onclick={onClose}
    role="presentation"
  ></div>

  <!-- OneDrive Exact Account Flyout (Teleported to body, z-[99999]) -->
  <div
    in:scale={{ start: 0.96, duration: 160 }}
    out:fade={{ duration: 100 }}
    id="account-info-panel"
    class="fixed top-15 right-4 sm:right-6 z-[99999] w-[340px] max-w-[calc(100vw-32px)] rounded-2xl border border-white/15 bg-[#1e1e1e] p-6 text-white shadow-[0_24px_64px_rgba(0,0,0,0.9)] select-none"
    {@attach focusTrap()}
    role="dialog"
    aria-label="Account details"
  >
    <!-- User Profile Header -->
    <div class="flex flex-col items-center justify-center text-center">
      <div class="relative group">
        <div class="rounded-full ring-2 ring-white/20 p-0.5 shadow-xl bg-neutral-800">
          <UserAvatar user={authManager.user} size="xl" />
        </div>
        <button
          type="button"
          class="absolute -bottom-1 -right-1 flex size-7 items-center justify-center rounded-full bg-[#0078d4] text-white shadow-md hover:bg-[#106ebe] transition-all duration-150 hover:scale-105 active:scale-95 cursor-pointer border-2 border-[#1e1e1e]"
          onclick={async () => {
            onClose?.();
            await modalManager.show(AvatarEditModal);
          }}
          aria-label={$t('edit_avatar')}
          title={$t('edit_avatar')}
        >
          <Icon icon={mdiPencil} size="14" />
        </button>
      </div>

      <div class="mt-3.5 space-y-0.5">
        <p class="text-base font-semibold tracking-tight text-white font-['Segoe_UI',sans-serif]">
          {authManager.user.name}
        </p>
        <p class="text-xs text-neutral-400 truncate max-w-[260px]">
          {authManager.user.email}
        </p>
      </div>

      <!-- Cloud Status Badge -->
      <div class="mt-3 inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-white/6 border border-white/10 text-neutral-200 text-[11px] font-medium">
        <span class="size-2 rounded-full bg-[#0078d4] shadow-[0_0_6px_#0078d4]"></span>
        OneDrive Personal Cloud
      </div>
    </div>

    <div class="my-4 h-px w-full bg-white/10"></div>

    <!-- Action Links (OneDrive Fluent Menu style) -->
    <div class="flex flex-col gap-1.5">
      <a
        href={Route.userSettings()}
        onclick={onClose}
        class="flex items-center gap-3.5 w-full px-4 py-2.5 rounded-xl bg-white/5 hover:bg-white/10 text-white border border-white/5 hover:border-white/15 transition-all duration-150 active:scale-[0.98] group cursor-pointer"
      >
        <div class="flex size-7 items-center justify-center rounded-lg bg-white/10 text-neutral-300 group-hover:text-white group-hover:bg-[#0078d4]/20 transition-colors">
          <Icon icon={mdiCogOutline} size="16" />
        </div>
        <span class="text-xs font-medium">{$t('account_settings')}</span>
      </a>

      {#if authManager.user.isAdmin}
        <a
          href={Route.systemSettings()}
          onclick={onClose}
          aria-current={page.url.pathname.includes('/admin') ? 'page' : undefined}
          class="flex items-center gap-3.5 w-full px-4 py-2.5 rounded-xl bg-white/5 hover:bg-white/10 text-white border border-white/5 hover:border-white/15 transition-all duration-150 active:scale-[0.98] group cursor-pointer"
        >
          <div class="flex size-7 items-center justify-center rounded-lg bg-white/10 text-neutral-300 group-hover:text-white group-hover:bg-[#0078d4]/20 transition-colors">
            <Icon icon={mdiShieldAccountOutline} size="16" />
          </div>
          <span class="text-xs font-medium">{$t('administration')}</span>
        </a>
      {/if}

      <a
        href={Route.logout()}
        class="flex items-center gap-3.5 w-full px-4 py-2.5 rounded-xl text-neutral-300 hover:text-red-400 hover:bg-red-500/10 border border-transparent hover:border-red-500/20 transition-all duration-150 active:scale-[0.98] group cursor-pointer"
      >
        <div class="flex size-7 items-center justify-center rounded-lg bg-white/5 text-neutral-400 group-hover:text-red-400 transition-colors">
          <Icon icon={mdiLogout} size="16" />
        </div>
        <span class="text-xs font-medium">{$t('sign_out')}</span>
      </a>
    </div>

    <!-- Help & Feedback Footer -->
    <div class="mt-4 pt-3 border-t border-white/10 text-center">
      <button
        type="button"
        class="text-[11px] text-neutral-400 hover:text-white transition-colors cursor-pointer hover:underline"
        onclick={async () => {
          onClose?.();
          if (info) {
            await modalManager.show(HelpAndFeedbackModal, { info });
          }
        }}
      >
        {$t('support_and_feedback')}
      </button>
    </div>
  </div>
</div>
