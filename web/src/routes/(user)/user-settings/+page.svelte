<script lang="ts">
  import UserPageLayout from '#lib/components/layouts/UserPageLayout.svelte';
  import { authManager } from '#lib/managers/auth-manager.svelte.ts';
  import { getKeyboardActions } from '#lib/services/keyboard.service.ts';
  import { Container } from '@immich/ui';
  import { t } from 'svelte-i18n';
  import type { PageData } from './$types';
  import UserSettingsList from './UserSettingsList.svelte';

  type Props = {
    data: PageData;
  };

  let { data }: Props = $props();

  const { KeyboardShortcuts } = $derived(getKeyboardActions($t));
</script>

<UserPageLayout title={data.meta.title} actions={[KeyboardShortcuts]}>
  <Container size="medium" center>
    <!-- Samsung One UI Top Profile Card (Screenshot 1, 2 & 4) -->
    <div
      class="mb-6 flex flex-col sm:flex-row sm:items-center justify-between gap-4 rounded-3xl border border-white/10 bg-gradient-to-r from-[#121622]/90 via-[#181d2c]/85 to-[#121622]/90 p-6 backdrop-blur-2xl shadow-xl"
    >
      <div class="flex items-center gap-4">
        <div
          class="relative flex h-14 w-14 shrink-0 items-center justify-center rounded-full bg-gradient-to-tr from-sky-500 via-indigo-600 to-fuchsia-600 p-0.5 shadow-lg shadow-indigo-500/20"
        >
          <div class="flex h-full w-full items-center justify-center rounded-full bg-[#0d1017] text-xl font-bold text-white">
            {authManager.user?.name ? authManager.user.name.charAt(0).toUpperCase() : 'M'}
          </div>
          <span class="absolute bottom-0 right-0 flex h-4 w-4 items-center justify-center rounded-full bg-emerald-500 ring-2 ring-[#0d1017]">
            <span class="h-2 w-2 rounded-full bg-white"></span>
          </span>
        </div>

        <div>
          <div class="flex items-center gap-2">
            <h1 class="text-xl font-bold text-white">
              {authManager.user?.name || 'Meet Bhingradiya'}
            </h1>
            <span class="rounded-full bg-sky-500/15 border border-sky-400/30 px-2.5 py-0.5 text-[11px] font-medium text-sky-300">
              Samsung One UI
            </span>
          </div>
          <p class="text-xs text-neutral-400 mt-0.5">
            {authManager.user?.email ? authManager.user.email.replace(/(.{3})(.*)(@.*)/, '$1***********$3') : 'mee***********@gmail.com'}
          </p>
        </div>
      </div>

      <div class="flex items-center gap-3">
        <div class="flex items-center gap-2 rounded-2xl bg-white/5 border border-white/10 px-4 py-2">
          <span class="h-2 w-2 rounded-full bg-emerald-400 animate-pulse"></span>
          <span class="text-xs font-semibold text-emerald-300 tracking-wide">
            {authManager.isPurchased ? 'Supporter Gold Pro' : 'Free Supporter'}
          </span>
        </div>
      </div>
    </div>

    <!-- Grouped Settings Cards -->
    <UserSettingsList />

    <!-- Samsung Signature "Looking for something else?" (Screenshot 1, 2, 3) -->
    <div
      class="mt-8 mb-12 rounded-3xl border border-sky-500/20 bg-gradient-to-br from-[#0c1b2f]/95 to-[#0b2545]/90 p-6 backdrop-blur-2xl shadow-2xl"
    >
      <h3 class="text-sm font-semibold tracking-wide text-white">
        Looking for something else?
      </h3>
      <div class="mt-3 flex flex-wrap gap-x-6 gap-y-2">
        {#if authManager.user?.isAdmin}
          <a
            href="/admin/system-settings"
            class="text-sm font-medium text-sky-400 transition-colors hover:text-sky-300 hover:underline"
          >
            System administration
          </a>
          <a
            href="/admin/server-status"
            class="text-sm font-medium text-sky-400 transition-colors hover:text-sky-300 hover:underline"
          >
            Server status and performance
          </a>
          <a
            href="/admin/library-management"
            class="text-sm font-medium text-sky-400 transition-colors hover:text-sky-300 hover:underline"
          >
            Library storage & paths
          </a>
          <a
            href="/admin/jobs-status"
            class="text-sm font-medium text-sky-400 transition-colors hover:text-sky-300 hover:underline"
          >
            Machine learning & jobs
          </a>
        {:else}
          <a
            href="/photos"
            class="text-sm font-medium text-sky-400 transition-colors hover:text-sky-300 hover:underline"
          >
            Photos timeline
          </a>
          <a
            href="/explore"
            class="text-sm font-medium text-sky-400 transition-colors hover:text-sky-300 hover:underline"
          >
            Smart AI search
          </a>
          <a
            href="/albums"
            class="text-sm font-medium text-sky-400 transition-colors hover:text-sky-300 hover:underline"
          >
            Shared albums
          </a>
        {/if}
      </div>
    </div>
  </Container>
</UserPageLayout>
