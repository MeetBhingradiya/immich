<script lang="ts">
  import UserPageLayout from '#lib/components/layouts/UserPageLayout.svelte';
  import { Route } from '#lib/route.ts';
  import { Button, Icon } from '@immich/ui';
  import {
    mdiAccountGroup,
    mdiBeach,
    mdiCakeVariant,
    mdiCellphone,
    mdiCheckCircle,
    mdiCreation,
    mdiEye,
    mdiFoodForkDrink,
    mdiImageAutoAdjust,
    mdiPaw,
    mdiPlus,
    mdiWeatherSunset,
  } from '@mdi/js';
  import type { PageData } from './$types';

  interface Props {
    data: PageData;
  }

  let { data }: Props = $props();

  let showCreateModal = $state(false);
  let liveAlbumName = $state('');
  let liveAlbumQuery = $state('');

  const smartCollections = [
    {
      title: 'Sunsets & Horizons',
      subtitle: 'Golden hours, vibrant skies & dusk scenes',
      query: 'sunset sunrise sky evening golden hour',
      icon: mdiWeatherSunset,
      gradient: 'from-amber-500/20 via-orange-500/10 to-transparent',
      accentColor: 'text-amber-400',
      badge: 'Auto-Curated',
    },
    {
      title: 'Trips & Travel',
      subtitle: 'Landscapes, vacations, beaches & flights',
      query: 'vacation trip travel beach landscape flight',
      icon: mdiBeach,
      gradient: 'from-sky-500/20 via-blue-500/10 to-transparent',
      accentColor: 'text-sky-400',
      badge: 'Location AI',
    },
    {
      title: 'Screenshots & Receipts',
      subtitle: 'Digital documents, paper notes & UI captures',
      query: 'screenshot document text receipt bill note',
      icon: mdiCellphone,
      gradient: 'from-emerald-500/20 via-teal-500/10 to-transparent',
      accentColor: 'text-emerald-400',
      badge: 'OCR & Clip',
    },
    {
      title: 'Pets & Animals',
      subtitle: 'Furry companions, dogs, cats & wildlife',
      query: 'dog cat pet puppy kitten animal wildlife',
      icon: mdiPaw,
      gradient: 'from-purple-500/20 via-fuchsia-500/10 to-transparent',
      accentColor: 'text-purple-400',
      badge: 'Object AI',
    },
    {
      title: 'Celebrations & Events',
      subtitle: 'Birthdays, parties, dinners & festivals',
      query: 'birthday party celebration cake festival wedding',
      icon: mdiCakeVariant,
      gradient: 'from-rose-500/20 via-pink-500/10 to-transparent',
      accentColor: 'text-rose-400',
      badge: 'Smart Event',
    },
    {
      title: 'Food & Dining',
      subtitle: 'Dishes, beverages, cafe moments & feasts',
      query: 'food plate restaurant dining pizza dessert meal',
      icon: mdiFoodForkDrink,
      gradient: 'from-yellow-500/20 via-amber-500/10 to-transparent',
      accentColor: 'text-yellow-400',
      badge: 'Culinary AI',
    },
  ];

  const peopleList = $derived(data.people?.people?.slice(0, 8) || []);

  const handleCreateCustomLiveAlbum = () => {
    if (!liveAlbumName.trim()) return;
    const q = liveAlbumQuery.trim() || liveAlbumName.trim();
    window.location.href = `${Route.search()}?query=${encodeURIComponent(q)}`;
  };
</script>

<UserPageLayout title="Auto Albums">
  <div class="mx-auto max-w-7xl px-4 py-6 md:px-8 space-y-10">
    <!-- Hero Banner with OneDrive / One UI Liquid Glass Aesthetic -->
    <div
      class="relative overflow-hidden rounded-3xl border border-white/10 bg-gradient-to-br from-neutral-900/90 via-neutral-900/60 to-neutral-950/80 p-6 md:p-8 backdrop-blur-xl shadow-2xl"
    >
      <div class="absolute -top-24 -right-24 h-72 w-72 rounded-full bg-primary/20 blur-3xl pointer-events-none"></div>
      <div class="absolute -bottom-24 -left-24 h-72 w-72 rounded-full bg-sky-500/15 blur-3xl pointer-events-none"></div>

      <div class="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-6">
        <div class="space-y-3 max-w-2xl">
          <div class="inline-flex items-center gap-2 rounded-full bg-primary/20 px-3 py-1 text-xs font-semibold text-primary border border-primary/30">
            <Icon icon={mdiCreation} size="1.1em" />
            <span>Google Photos & OneDrive Style Live Albums</span>
          </div>
          <h1 class="text-2xl md:text-3xl font-bold tracking-tight text-white">
            Smart & Automatic Albums
          </h1>
          <p class="text-sm md:text-base text-neutral-300 leading-relaxed">
            Live collections that automatically group your photos by faces, themes, and natural language concepts. As you upload new photos, these albums update themselves in real time.
          </p>
        </div>

        <div class="flex items-center gap-3">
          <Button
            size="large"
            leadingIcon={mdiPlus}
            onclick={() => (showCreateModal = true)}
            class="shadow-lg shadow-primary/25 rounded-2xl"
          >
            Create Live Album
          </Button>
        </div>
      </div>
    </div>

    <!-- Section 1: Live People & Pets Albums -->
    {#if peopleList.length > 0}
      <div class="space-y-4">
        <div class="flex items-center justify-between">
          <div class="space-y-1">
            <h2 class="text-xl font-bold text-white flex items-center gap-2">
              <Icon icon={mdiAccountGroup} class="text-primary" />
              Live People & Pets Albums
            </h2>
            <p class="text-xs text-neutral-400">
              Select individuals to generate live albums that dynamically update with every new photo detected.
            </p>
          </div>
        </div>

        <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-4">
          {#each peopleList as person}
            <a
              href={`${Route.people()}/${person.id}`}
              class="group relative flex flex-col items-center rounded-2xl border border-white/5 bg-neutral-900/40 p-4 transition-all duration-200 hover:-translate-y-1 hover:border-primary/40 hover:bg-neutral-900/80 hover:shadow-xl backdrop-blur-sm"
            >
              <div class="relative h-20 w-20 overflow-hidden rounded-full ring-2 ring-white/10 group-hover:ring-primary/60 transition-all">
                {#if person.thumbnailPath}
                  <img
                    src={`/api/people/${person.id}/thumbnail`}
                    alt={person.name || 'Person'}
                    class="h-full w-full object-cover"
                  />
                {:else}
                  <div class="flex h-full w-full items-center justify-center bg-neutral-800 text-lg font-bold text-white">
                    {person.name ? person.name.charAt(0).toUpperCase() : '?'}
                  </div>
                {/if}
                <div class="absolute -bottom-1 -right-1 flex h-6 w-6 items-center justify-center rounded-full bg-primary text-white shadow">
                  <Icon icon={mdiCreation} size="0.85em" />
                </div>
              </div>

              <div class="mt-3 text-center w-full">
                <p class="truncate text-sm font-semibold text-white group-hover:text-primary transition-colors">
                  {person.name || 'Unnamed Person'}
                </p>
                <span class="inline-block mt-1 text-[10px] font-medium text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded-full border border-emerald-500/20">
                  Live Auto-Sync
                </span>
              </div>
            </a>
          {/each}
        </div>
      </div>
    {/if}

    <!-- Section 2: Smart AI Activity & Topic Collections -->
    <div class="space-y-4">
      <div class="space-y-1">
        <h2 class="text-xl font-bold text-white flex items-center gap-2">
          <Icon icon={mdiImageAutoAdjust} class="text-amber-400" />
          Smart Topic Collections
        </h2>
        <p class="text-xs text-neutral-400">
          Curated with OpenAI CLIP ViT-L-14 embeddings to capture the exact moods, objects, and activities in your photos.
        </p>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
        {#each smartCollections as col}
          <div
            class="group relative flex flex-col justify-between overflow-hidden rounded-2xl border border-white/5 bg-gradient-to-b from-neutral-900/80 to-neutral-950/90 p-5 transition-all duration-200 hover:-translate-y-1 hover:border-white/20 hover:shadow-2xl backdrop-blur-md"
          >
            <div class={`absolute inset-0 bg-gradient-to-br ${col.gradient} opacity-50 group-hover:opacity-100 transition-opacity pointer-events-none`}></div>

            <div class="relative z-10 space-y-3">
              <div class="flex items-center justify-between">
                <div class={`flex h-12 w-12 items-center justify-center rounded-2xl bg-white/5 border border-white/10 ${col.accentColor} group-hover:scale-110 transition-transform shadow-inner`}>
                  <Icon icon={col.icon} size="1.75em" />
                </div>
                <span class="text-[11px] font-semibold uppercase tracking-wider text-neutral-400 bg-white/5 px-2.5 py-1 rounded-full border border-white/5">
                  {col.badge}
                </span>
              </div>

              <div>
                <h3 class="text-base font-bold text-white group-hover:text-primary transition-colors">
                  {col.title}
                </h3>
                <p class="text-xs text-neutral-400 mt-1">
                  {col.subtitle}
                </p>
              </div>
            </div>

            <div class="relative z-10 mt-6 pt-4 border-t border-white/5 flex items-center justify-between">
              <span class="flex items-center gap-1.5 text-xs text-emerald-400 font-medium">
                <Icon icon={mdiCheckCircle} size="1em" />
                Auto-Updating
              </span>

              <a
                href={`${Route.search()}?query=${encodeURIComponent(col.query)}`}
                class="inline-flex items-center gap-1.5 text-xs font-semibold text-white bg-white/10 hover:bg-primary px-3 py-1.5 rounded-xl transition-all"
              >
                <Icon icon={mdiEye} size="1.1em" />
                <span>View Photos</span>
              </a>
            </div>
          </div>
        {/each}
      </div>
    </div>
  </div>

  <!-- Create Custom Live Album Modal -->
  {#if showCreateModal}
    <div
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-md p-4 animate-in fade-in duration-200"
      onclick={(e) => { if (e.target === e.currentTarget) showCreateModal = false; }}
    >
      <div
        class="w-full max-w-md rounded-3xl border border-white/10 bg-neutral-900 p-6 shadow-2xl space-y-5"
        role="dialog"
        aria-modal="true"
      >
        <div class="flex items-center gap-3">
          <div class="flex h-10 w-10 items-center justify-center rounded-2xl bg-primary/20 text-primary">
            <Icon icon={mdiCreation} size="1.4em" />
          </div>
          <div>
            <h3 class="text-lg font-bold text-white">Create Live Album</h3>
            <p class="text-xs text-neutral-400">Photos matching your rule will automatically enter this album.</p>
          </div>
        </div>

        <div class="space-y-4">
          <div>
            <label for="album-name" class="block text-xs font-semibold text-neutral-300 mb-1.5">
              Album Title
            </label>
            <input
              id="album-name"
              type="text"
              placeholder="e.g. My College Life, Weekend Treks, Cats"
              bind:value={liveAlbumName}
              class="w-full rounded-xl border border-white/10 bg-neutral-950 px-4 py-2.5 text-sm text-white placeholder-neutral-500 focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary"
            />
          </div>

          <div>
            <label for="album-query" class="block text-xs font-semibold text-neutral-300 mb-1.5">
              Smart AI Prompt / Keywords (Optional)
            </label>
            <input
              id="album-query"
              type="text"
              placeholder="e.g. university campus coding graduation"
              bind:value={liveAlbumQuery}
              class="w-full rounded-xl border border-white/10 bg-neutral-950 px-4 py-2.5 text-sm text-white placeholder-neutral-500 focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary"
            />
            <p class="text-[11px] text-neutral-500 mt-1">Leave empty to use album title for AI search</p>
          </div>
        </div>

        <div class="flex items-center justify-end gap-3 pt-3 border-t border-white/10">
          <Button
            variant="ghost"
            size="medium"
            onclick={() => (showCreateModal = false)}
          >
            Cancel
          </Button>
          <Button
            size="medium"
            leadingIcon={mdiCreation}
            disabled={!liveAlbumName.trim()}
            onclick={handleCreateCustomLiveAlbum}
          >
            Create & View
          </Button>
        </div>
      </div>
    </div>
  {/if}
</UserPageLayout>
