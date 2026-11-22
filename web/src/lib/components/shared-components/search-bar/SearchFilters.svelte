<script lang="ts">
  import { authManager } from '#lib/managers/auth-manager.svelte.ts';
  import { searchManager } from '#lib/managers/search-manager.svelte.ts';
  import { getAllTagsQuery } from '#lib/queries/tag.query.ts';
  import { type PersonResponseDto } from '@immich/sdk';
  import { Button, Icon, Text } from '@immich/ui';
  import {
    mdiAccount,
    mdiCalendarBlank,
    mdiChevronDown,
    mdiChevronUp,
    mdiImage,
    mdiMagnify,
    mdiMapMarker,
    mdiTagMultiple,
    mdiTune,
  } from '@mdi/js';
  import { createQuery } from '@tanstack/svelte-query';
  import { onMount } from 'svelte';
  import { t } from 'svelte-i18n';
  import { fly } from 'svelte/transition';
  import SearchButton from './SearchButton.svelte';
  import SearchCameraSection from './SearchCameraSection.svelte';
  import SearchDateSection from './SearchDateSection.svelte';
  import SearchDisplaySection from './SearchDisplaySection.svelte';
  import SearchHistorySection from './SearchHistorySection.svelte';
  import SearchLocationSection from './SearchLocationSection.svelte';
  import SearchMediaSection from './SearchMediaSection.svelte';
  import SearchPeopleSection from './SearchPeopleSection.svelte';
  import SearchRatingsSection from './SearchRatingsSection.svelte';
  import SearchTagsSection from './SearchTagsSection.svelte';
  import SearchTextSection from './SearchTextSection.svelte';
  import {
    getPeople,
    getSearchDatePreset,
    getSearchDateTitle,
    getSearchMediaTitle,
    getSearchPeopleTitle,
    getSearchPlacesTitle,
    getSearchTagsTitle,
    getSearchTypeTitle,
  } from './search-bar-utils';

  interface Props {
    id: string;
    isOpen?: boolean;
    onSelectSearchTerm: (searchTerm: string) => void;
    onClearSearchTerm: (searchTerm: string) => void;
    onClearAllSearchTerms: () => void;
    onActiveSelectionChange: (selectedId: string | undefined) => void;
    onSearch: () => void;
  }

  let {
    id,
    isOpen = false,
    onSelectSearchTerm,
    onClearSearchTerm,
    onClearAllSearchTerms,
    onActiveSelectionChange,
    onSearch,
  }: Props = $props();

  let searchHistory = $state<SearchHistorySection>();

  let activeFilter = $state<string | undefined>(undefined);
  let showFilters = $state(false);
  let showAdvanced = $state(false);
  let peoplePromise = $state<Promise<PersonResponseDto[]>>();
  let people = $state<PersonResponseDto[]>();
  const tagsQuery = createQuery(() => ({ ...getAllTagsQuery(), enabled: !!searchManager.filter.tagIds?.size }));
  const tags = $derived(tagsQuery.data);

  let typeTitle = $derived(getSearchTypeTitle(searchManager.filter.queryType));
  let peopleTitle = $state<string>();
  let dateTitle = $derived(
    getSearchDateTitle(
      getSearchDatePreset(searchManager.filter.date.takenAfter, searchManager.filter.date.takenBefore),
      searchManager.filter.date.takenAfter,
      searchManager.filter.date.takenBefore,
    ),
  );
  let placesTitle = $derived(
    getSearchPlacesTitle(
      searchManager.filter.location.city,
      searchManager.filter.location.state,
      searchManager.filter.location.country,
    ),
  );
  let tagsTitle = $state<string>();
  let mediaTitle = $derived(getSearchMediaTitle(searchManager.filter.mediaType));

  let filters = [
    {
      name: 'type',
      icon: mdiMagnify,
      title: $t('search_type'),
      activeTitle: () => typeTitle,
    },
    {
      name: 'people',
      icon: mdiAccount,
      title: $t('people'),
      activeTitle: () => peopleTitle,
    },
    {
      name: 'date',
      icon: mdiCalendarBlank,
      title: $t('date'),
      activeTitle: () => dateTitle,
    },
    {
      name: 'places',
      icon: mdiMapMarker,
      title: $t('places'),
      activeTitle: () => placesTitle,
    },
    ...(authManager.authenticated && authManager.preferences.tags.enabled
      ? [
          {
            name: 'tags',
            icon: mdiTagMultiple,
            title: $t('tags'),
            activeTitle: () => tagsTitle,
          },
        ]
      : []),
    {
      name: 'media',
      icon: mdiImage,
      title: $t('media'),
      activeTitle: () => mediaTitle,
    },
  ];

  const advancedFiltersSet = $derived(
    searchManager.filter.display.isArchive ||
      searchManager.filter.display.isFavorite ||
      searchManager.filter.display.isNotInAlbum ||
      searchManager.filter.camera.make !== undefined ||
      searchManager.filter.camera.model !== undefined ||
      searchManager.filter.camera.lensModel !== undefined ||
      searchManager.filter.rating,
  );

  const clear = () => {
    searchManager.reset();
    peopleTitle = tagsTitle = undefined;
  };

  onMount(() => {
    if (searchManager.filter.personIds.size > 0 && !peoplePromise) {
      peoplePromise = getPeople(searchManager.filter.personIds);
      void peoplePromise.then((res) => (people = res));
    }
  });

  $effect(() => {
    if (people) {
      peopleTitle = getSearchPeopleTitle(people, searchManager.filter.personIds);
    }
  });

  $effect(() => {
    if (searchManager.filter.tagIds === null) {
      tagsTitle = $t('untagged');
    } else if (tags) {
      tagsTitle = getSearchTagsTitle(tags, searchManager.filter.tagIds);
    }
  });

  export function moveSelection(increment: 1 | -1) {
    if (searchHistory) {
      searchHistory.moveSelection(increment);
    }
  }

  export function clearSelection() {
    if (searchHistory) {
      searchHistory.clearSelection();
    }
  }

  export function selectActiveOption() {
    if (searchHistory) {
      searchHistory.selectActiveOption();
    }
  }
</script>

<div role="listbox" {id}>
  {#if isOpen}
    <div
      transition:fly={{ y: 25, duration: 250 }}
      class="absolute z-1 max-h-[80svh] w-full overflow-y-auto rounded-b-3xl border-x border-b border-white/20 bg-neutral-900/95 backdrop-blur-2xl shadow-[0_20px_40px_rgba(0,0,0,0.5)] transition-all text-neutral-200"
    >
      <SearchHistorySection
        bind:this={searchHistory}
        {onSelectSearchTerm}
        {onClearSearchTerm}
        {onClearAllSearchTerms}
        {onActiveSelectionChange}
      />
      <!-- Smart Quick Categories (OneDrive Luxury Experience) -->
      <div class="px-5 py-3 border-t border-white/5">
        <p class="text-[11px] font-semibold uppercase tracking-wider text-neutral-400 mb-2">Smart Categories</p>
        <div class="flex flex-wrap gap-1.5">
          {#each [
            { label: '🌅 Sunsets', q: 'sunset' },
            { label: '📸 Screenshots', q: 'screenshot' },
            { label: '👤 Portraits', q: 'portrait face' },
            { label: '🐾 Pets', q: 'pet dog cat animal' },
            { label: '❤️ Favorites', q: 'favorite' },
            { label: '🏖️ Trips', q: 'vacation trip beach' },
            { label: '📄 Documents', q: 'document text receipt' },
            { label: '🌃 Night', q: 'night lights' }
          ] as chip}
            <button
              type="button"
              class="inline-flex items-center rounded-full bg-white/5 hover:bg-primary/20 hover:text-primary hover:border-primary/40 border border-white/10 px-3 py-1 text-xs font-medium text-neutral-300 transition-all cursor-pointer"
              onclick={() => onSelectSearchTerm(chip.q)}
            >
              {chip.label}
            </button>
          {/each}
        </div>
      </div>

      <!-- Filters Expansion Header -->
      <div class="px-5 py-2.5 flex items-center justify-between border-t border-white/5 bg-neutral-900/30">
        <button
          type="button"
          class="inline-flex items-center gap-1.5 text-xs font-medium text-neutral-400 hover:text-white transition-colors cursor-pointer"
          onclick={() => (showFilters = !showFilters)}
        >
          <Icon icon={mdiTune} size="1.1em" />
          <span>{showFilters ? 'Hide Advanced Filters' : 'Filter by Details (People, Date, Camera, Places)'}</span>
          <Icon icon={showFilters ? mdiChevronUp : mdiChevronDown} size="1.1em" />
        </button>

        {#if showFilters}
          <button
            type="button"
            class="text-xs text-neutral-500 hover:text-neutral-300 transition-colors"
            onclick={() => clear()}
          >
            {$t('clear_all')}
          </button>
        {/if}
      </div>

      {#if showFilters}
        <div class="px-5 pt-3">
          <Text class="pb-3 text-xs" fontWeight="medium" aria-hidden={true}>{$t('filter_by')}</Text>
          <div class="flex flex-wrap gap-2">
            {#each filters as item (item.name)}
              <SearchButton
                active={activeFilter === item.name || Boolean(item.activeTitle())}
                leadingIcon={item.icon}
                class={activeFilter === item.name ? 'border-2' : undefined}
                onclick={() => (activeFilter = activeFilter === item.name ? undefined : item.name)}
              >
                {item.activeTitle() ?? item.title}
              </SearchButton>
            {/each}
          </div>
        </div>

        {#if activeFilter}
          <div class="px-5 pt-4">
            {#if activeFilter === 'type'}
              <SearchTextSection />
            {:else if activeFilter === 'people'}
              <SearchPeopleSection bind:title={peopleTitle} parentPromise={peoplePromise} />
            {:else if activeFilter === 'date'}
              <SearchDateSection />
            {:else if activeFilter === 'places'}
              <SearchLocationSection />
            {:else if activeFilter === 'tags'}
              <SearchTagsSection bind:title={tagsTitle} />
            {:else if activeFilter === 'media'}
              <SearchMediaSection />
            {/if}
          </div>
        {/if}

        <div
          class="grid transition-[grid-template-rows] duration-200 ease-in-out {showAdvanced
            ? 'grid-rows-[1fr]'
            : 'grid-rows-[0fr]'}"
          inert={!showAdvanced}
        >
          <div class="overflow-hidden">
            <div class="my-5 h-px w-full bg-light-200 dark:bg-dark-600"></div>
            <div class="px-5">
              <SearchCameraSection />
              {#if authManager.authenticated && authManager.preferences.ratings.enabled}
                <SearchRatingsSection />
              {/if}
              <SearchDisplaySection />
            </div>
          </div>
        </div>

        <div class="my-4 h-px w-full bg-light-200 dark:bg-dark-600"></div>
        <div class="flex flex-wrap gap-2 px-5 pb-4">
          <Button
            size="small"
            variant={advancedFiltersSet ? 'outline' : 'ghost'}
            leadingIcon={mdiTune}
            trailingIcon={showAdvanced ? mdiChevronUp : mdiChevronDown}
            onclick={() => (showAdvanced = !showAdvanced)}>{$t('advanced_filters')}</Button
          >
          <div class="flex-1"></div>
          <Button
            size="small"
            shape="round"
            variant="outline"
            color="secondary"
            class="bg-transparent"
            onclick={() => clear()}>{$t('clear_all')}</Button
          >
          <Button size="small" shape="round" onclick={() => onSearch()}>{$t('search')}</Button>
        </div>
      {/if}
    </div>
  {/if}
</div>
