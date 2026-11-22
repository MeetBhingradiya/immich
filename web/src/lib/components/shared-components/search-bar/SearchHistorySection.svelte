<script lang="ts">
  import { searchManager } from '#lib/managers/search-manager.svelte.ts';
  import { searchStore } from '#lib/stores/search.svelte.ts';
  import { Icon } from '@immich/ui';
  import { mdiClose } from '@mdi/js';
  import { t } from 'svelte-i18n';

  interface Props {
    onSelectSearchTerm: (searchTerm: string) => void;
    onClearSearchTerm: (searchTerm: string) => void;
    onClearAllSearchTerms: () => void;
    onActiveSelectionChange: (selectedId: string | undefined) => void;
  }

  let { onSelectSearchTerm, onClearSearchTerm, onClearAllSearchTerms, onActiveSelectionChange }: Props = $props();

  let searchBoxText = $derived(searchManager.filter.query);
  let filteredSearchTerms = $derived(
    searchStore.savedSearchTerms.filter((term) => term.toLowerCase().includes(searchBoxText.toLowerCase())),
  );

  let isSearchSuggestions = $derived(filteredSearchTerms.length > 0);
  let showClearAll = $derived(searchBoxText === '');
  let selectedIndex: number | undefined = $state(undefined);

  const rootId = $props.id();

  export function moveSelection(increment: 1 | -1) {
    if (!isSearchSuggestions) return;
    const count = filteredSearchTerms.length;
    if (selectedIndex === undefined) {
      selectedIndex = increment === 1 ? 0 : count - 1;
    } else {
      selectedIndex = (selectedIndex + increment + count) % count;
    }
    onActiveSelectionChange(getId(selectedIndex));
  }

  export function clearSelection() {
    selectedIndex = undefined;
    onActiveSelectionChange(undefined);
  }

  export function selectActiveOption() {
    if (selectedIndex === undefined) return;
    const term = filteredSearchTerms[selectedIndex];
    if (term) handleSelect(term);
  }

  const handleClearAll = () => {
    clearSelection();
    onClearAllSearchTerms();
  };

  const handleClearSingle = (searchTerm: string) => {
    clearSelection();
    onClearSearchTerm(searchTerm);
  };

  const handleSelect = (searchTerm: string) => {
    clearSelection();
    onSelectSearchTerm(searchTerm);
  };

  const getId = (index: number | undefined) => {
    if (index === undefined) return undefined;
    return `${rootId}-entry-${index}`;
  };
</script>

<div id="history-section" class="px-5 pt-4 pb-2">
  {#if isSearchSuggestions}
    <div class="flex items-center justify-between mb-2">
      <span class="text-xs font-semibold text-neutral-400">{$t('recent_searches')}</span>
      {#if showClearAll}
        <button
          type="button"
          class="text-xs text-neutral-400 hover:text-white transition-colors cursor-pointer"
          onclick={handleClearAll}
        >
          {$t('clear_all')}
        </button>
      {/if}
    </div>

    <!-- Chips Row matching OneDrive Reference Screenshot 7 -->
    <div class="flex flex-wrap gap-2 mb-3">
      {#each filteredSearchTerms as savedSearchTerm, i (i)}
        <div
          id={getId(i)}
          class="inline-flex items-center gap-1.5 rounded-full bg-white/10 hover:bg-white/15 border border-white/10 px-3 py-1 text-xs text-neutral-200 transition-all cursor-pointer group"
          role="option"
          tabindex="-1"
          aria-selected={selectedIndex === i}
        >
          <button
            type="button"
            class="hover:text-white"
            onclick={() => handleSelect(savedSearchTerm)}
          >
            {savedSearchTerm}
          </button>
          <button
            type="button"
            class="text-neutral-400 hover:text-white p-0.5 rounded-full hover:bg-white/10"
            onclick={() => handleClearSingle(savedSearchTerm)}
            aria-label="Remove"
          >
            <Icon icon={mdiClose} size="12px" />
          </button>
        </div>
      {/each}
    </div>
  {/if}

  <!-- Examples Section matching OneDrive Reference Screenshot 7 -->
  <div class="mt-2 pt-2 border-t border-white/5">
    <p class="text-xs font-semibold text-neutral-400 mb-2">Examples</p>
    <div class="space-y-1">
      {#each [
        'Hiking in the mountains',
        'Fireworks by the beach',
        'Field hockey action shot',
        'Sunset at golden hour',
        'Screenshots and documents'
      ] as example}
        <button
          type="button"
          class="flex w-full items-center gap-2.5 rounded-xl px-2.5 py-1.5 text-xs text-neutral-300 hover:bg-white/10 hover:text-white text-start transition-colors cursor-pointer"
          onclick={() => handleSelect(example)}
        >
          <span class="text-amber-400 text-sm">💡</span>
          <span>{example}</span>
        </button>
      {/each}
    </div>
  </div>
</div>
