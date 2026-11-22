<script lang="ts">
  import { focusTrap } from '#lib/actions/focus-trap.ts';
  import { authManager } from '#lib/managers/auth-manager.svelte.ts';
  import AvatarEditModal from '#lib/modals/AvatarEditModal.svelte';
  import HelpAndFeedbackModal from '#lib/modals/HelpAndFeedbackModal.svelte';
  import { getAboutInfoQuery } from '#lib/queries/server-info.query.ts';
  import { Route } from '#lib/route.ts';
  import { Icon, modalManager } from '@immich/ui';
  import { mdiCog, mdiLogout, mdiPencil, mdiShieldCheck, mdiWrench } from '@mdi/js';
  import { createQuery } from '@tanstack/svelte-query';
  import { t } from 'svelte-i18n';
  import { fade } from 'svelte/transition';
  import { page } from '$app/state';
  import UserAvatar from '../UserAvatar.svelte';

  type Props = {
    onClose?: () => void;
  };

  let { onClose }: Props = $props();

  const query = createQuery(getAboutInfoQuery);
  const info = $derived(query.data);
</script>

<div
  in:fade={{ duration: 150 }}
  out:fade={{ duration: 100 }}
  id="account-info-panel"
  class="absolute top-17.5 right-6 z-50 w-[min(380px,calc(100vw-32px))] rounded-3xl border border-white/15 bg-neutral-900/98 p-6 text-white shadow-[0_25px_60px_-15px_rgba(0,0,0,0.95)] backdrop-blur-2xl select-none"
  {@attach focusTrap()}
>
  <!-- User Profile Card -->
  <div class="flex flex-col items-center justify-center text-center">
    <div class="relative group">
      <div class="rounded-full ring-2 ring-white/20 p-0.5 shadow-lg">
        <UserAvatar user={authManager.user} size="xl" />
      </div>
      <button
        type="button"
        class="absolute -bottom-1 -right-1 flex size-7 items-center justify-center rounded-full bg-primary-600 text-white shadow-md hover:bg-primary-500 transition-all duration-200 hover:scale-110 active:scale-95 cursor-pointer border-2 border-neutral-900"
        onclick={async () => {
          onClose?.();
          await modalManager.show(AvatarEditModal);
        }}
        aria-label={$t('edit_avatar')}
        title={$t('edit_avatar')}
      >
        <Icon icon={mdiPencil} size="15" />
      </button>
    </div>

    <div class="mt-3.5 space-y-0.5">
      <p class="text-base font-semibold tracking-tight text-white">
        {authManager.user.name}
      </p>
      <p class="text-xs text-neutral-400 font-mono">
        {authManager.user.email}
      </p>
    </div>

    <!-- Supporter Badge -->
    <div class="mt-2.5 inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-500/15 border border-emerald-500/30 text-emerald-300 text-xs font-medium">
      <span class="size-2 rounded-full bg-emerald-400 animate-pulse"></span>
      Supporter Gold Pro
    </div>
  </div>

  <div class="my-5 h-px w-full bg-white/10"></div>

  <!-- Action Links -->
  <div class="flex flex-col gap-2">
    <a
      href={Route.userSettings()}
      onclick={onClose}
      class="flex items-center gap-3 w-full px-4 py-2.5 rounded-2xl bg-white/5 hover:bg-white/10 text-white border border-white/10 hover:border-white/20 transition-all duration-200 active:scale-[0.98] group"
    >
      <div class="flex size-8 items-center justify-center rounded-xl bg-white/10 text-neutral-300 group-hover:text-white group-hover:bg-white/15 transition-colors">
        <Icon icon={mdiCog} size="18" />
      </div>
      <span class="text-sm font-medium">{$t('account_settings')}</span>
    </a>

    {#if authManager.user.isAdmin}
      <a
        href={Route.systemSettings()}
        onclick={onClose}
        aria-current={page.url.pathname.includes('/admin') ? 'page' : undefined}
        class="flex items-center gap-3 w-full px-4 py-2.5 rounded-2xl bg-amber-500/10 hover:bg-amber-500/20 text-amber-300 border border-amber-500/25 hover:border-amber-500/40 transition-all duration-200 active:scale-[0.98] group"
      >
        <div class="flex size-8 items-center justify-center rounded-xl bg-amber-500/20 text-amber-300 group-hover:bg-amber-500/30 transition-colors">
          <Icon icon={mdiWrench} size="18" />
        </div>
        <span class="text-sm font-medium">{$t('administration')}</span>
      </a>
    {/if}

    <a
      href={Route.logout()}
      class="flex items-center gap-3 w-full px-4 py-2.5 rounded-2xl text-neutral-300 hover:text-red-400 hover:bg-red-500/10 border border-transparent hover:border-red-500/20 transition-all duration-200 active:scale-[0.98] group"
    >
      <div class="flex size-8 items-center justify-center rounded-xl bg-white/5 text-neutral-400 group-hover:text-red-400 group-hover:bg-red-500/15 transition-colors">
        <Icon icon={mdiLogout} size="18" />
      </div>
      <span class="text-sm font-medium">{$t('sign_out')}</span>
    </a>
  </div>

  <!-- Support & Feedback Footer -->
  <div class="mt-5 pt-3 border-t border-white/5 text-center">
    <button
      type="button"
      class="text-xs text-neutral-400 hover:text-neutral-200 transition-colors cursor-pointer hover:underline"
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
