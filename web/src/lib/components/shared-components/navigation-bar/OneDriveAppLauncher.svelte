<script lang="ts">
  import { clickOutside } from '#lib/actions/click-outside.ts';
  import { authManager } from '#lib/managers/auth-manager.svelte.ts';
  import { Route } from '#lib/route.ts';
  import { Icon, IconButton } from '@immich/ui';
  import {
    mdiAccountGroup,
    mdiArchiveArrowDownOutline,
    mdiAutoFix,
    mdiBookMultipleOutline,
    mdiClose,
    mdiCogOutline,
    mdiCreationOutline,
    mdiFolderOutline,
    mdiHeartOutline,
    mdiMagnify,
    mdiMapOutline,
    mdiShieldCrownOutline,
    mdiTagMultipleOutline,
    mdiTrashCanOutline,
    mdiViewGrid,
  } from '@mdi/js';
  import { fade, scale } from 'svelte/transition';

  type Props = {
    onClose: () => void;
  };

  let { onClose }: Props = $props();

  const appItems = $derived([
    {
      title: 'Gallery',
      desc: 'All photos & timeline',
      href: Route.photos(),
      icon: mdiViewGrid,
      color: 'from-blue-500 to-indigo-600',
    },
    {
      title: 'Files',
      desc: 'Folder hierarchy',
      href: Route.folders(),
      icon: mdiFolderOutline,
      color: 'from-sky-500 to-blue-600',
    },
    {
      title: 'Moments',
      desc: 'Memories & highlights',
      href: Route.memories(),
      icon: mdiCreationOutline,
      color: 'from-purple-500 to-pink-500',
    },
    {
      title: 'People',
      desc: 'Face recognition & pets',
      href: Route.people(),
      icon: mdiAccountGroup,
      color: 'from-amber-500 to-orange-600',
    },
    {
      title: 'Albums',
      desc: 'Custom collections',
      href: Route.albums(),
      icon: mdiBookMultipleOutline,
      color: 'from-emerald-500 to-teal-600',
    },
    {
      title: 'Auto Albums',
      desc: 'Smart synced collections',
      href: Route.autoAlbums(),
      icon: mdiAutoFix,
      color: 'from-fuchsia-500 to-rose-600',
    },
    {
      title: 'Favorites',
      desc: 'Starred media',
      href: Route.favorites(),
      icon: mdiHeartOutline,
      color: 'from-rose-500 to-red-600',
    },
    {
      title: 'Explore',
      desc: 'Smart semantic search',
      href: Route.explore(),
      icon: mdiMagnify,
      color: 'from-indigo-500 to-blue-600',
    },
    {
      title: 'World Map',
      desc: 'Geo-located memories',
      href: Route.map(),
      icon: mdiMapOutline,
      color: 'from-teal-500 to-emerald-600',
    },
    {
      title: 'Tags',
      desc: 'Asset metadata tags',
      href: Route.tags(),
      icon: mdiTagMultipleOutline,
      color: 'from-violet-500 to-purple-600',
    },
    {
      title: 'Archive',
      desc: 'Hidden from timeline',
      href: Route.archive(),
      icon: mdiArchiveArrowDownOutline,
      color: 'from-neutral-500 to-neutral-700',
    },
    {
      title: 'Recycle Bin',
      desc: 'Deleted assets',
      href: Route.trash(),
      icon: mdiTrashCanOutline,
      color: 'from-red-500 to-rose-700',
    },
    {
      title: 'Settings',
      desc: 'Account preferences',
      href: Route.userSettings(),
      icon: mdiCogOutline,
      color: 'from-slate-500 to-neutral-600',
    },
    ...(authManager.user.isAdmin
      ? [
          {
            title: 'Administration',
            desc: 'System & users control',
            href: '/admin/system-settings',
            icon: mdiShieldCrownOutline,
            color: 'from-amber-500 to-yellow-600',
          },
        ]
      : []),
  ]);
</script>

<!-- Backdrop -->
<div
  transition:fade={{ duration: 150 }}
  class="fixed inset-0 z-50 bg-black/40 backdrop-blur-xs"
  onclick={onClose}
  role="presentation"
></div>

<!-- App Launcher Dropdown Panel -->
<div
  transition:scale={{ start: 0.95, duration: 200 }}
  use:clickOutside={{ onOutclick: onClose, onEscape: onClose }}
  class="fixed top-14 left-4 z-50 w-full max-w-sm rounded-3xl border border-white/15 bg-neutral-900/95 p-5 text-white shadow-2xl backdrop-blur-2xl"
  role="dialog"
  aria-label="App Launcher"
>
  <div class="mb-4 flex items-center justify-between border-b border-white/10 pb-3">
    <div class="flex items-center gap-2">
      <div class="flex size-7 items-center justify-center rounded-lg bg-blue-600 text-white shadow-sm">
        <svg viewBox="0 0 24 24" class="size-4.5 fill-current">
          <path d="M19.35 10.04C18.67 6.59 15.64 4 12 4 9.11 4 6.6 5.64 5.35 8.04 2.34 8.36 0 10.91 0 14c0 3.31 2.69 6 6 6h13c2.76 0 5-2.24 5-5 0-2.64-2.05-4.78-4.65-4.96z" />
        </svg>
      </div>
      <div>
        <h3 class="text-sm font-semibold tracking-tight">Immich Cloud Apps</h3>
        <p class="text-[11px] text-neutral-400">Microsoft 365 & OneDrive Experience</p>
      </div>
    </div>
    <IconButton
      icon={mdiClose}
      size="small"
      shape="round"
      color="secondary"
      variant="ghost"
      onclick={onClose}
      aria-label="Close"
    />
  </div>

  <div class="grid grid-cols-3 gap-2.5 max-h-[70vh] overflow-y-auto pr-1">
    {#each appItems as app}
      <a
        href={app.href}
        onclick={onClose}
        class="group flex flex-col items-center justify-center rounded-2xl border border-white/5 bg-white/5 p-3 text-center transition-all hover:scale-105 hover:border-white/20 hover:bg-white/10 active:scale-95"
      >
        <div class="mb-2 flex size-11 items-center justify-center rounded-xl bg-gradient-to-tr {app.color} text-white shadow-md transition-shadow group-hover:shadow-lg">
          <Icon icon={app.icon} size="22px" />
        </div>
        <span class="text-xs font-medium text-neutral-200 group-hover:text-white">{app.title}</span>
        <span class="mt-0.5 text-[10px] text-neutral-400 line-clamp-1">{app.desc}</span>
      </a>
    {/each}
  </div>
</div>
