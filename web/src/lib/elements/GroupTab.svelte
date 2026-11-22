<script lang="ts">
  interface Props {
    filters: string[];
    labels?: string[];
    selected: string;
    label: string;
    onSelect: (selected: string) => void;
  }

  const { filters, selected, label, labels, onSelect }: Props = $props();

  const id = $props.id();
</script>

<fieldset
  class="flex h-full items-center p-1 rounded-full bg-slate-200/60 dark:bg-neutral-900/80 border border-slate-300/40 dark:border-white/10 backdrop-blur-md"
>
  <legend class="sr-only">{label}</legend>
  {#each filters as filter, index (`${id}-${index}`)}
    <div class="group">
      <input
        type="radio"
        name={id}
        id="{id}-{index}"
        class="peer sr-only"
        value={filter}
        checked={filter === selected}
        onchange={() => onSelect(filter)}
      />
      <label
        for="{id}-{index}"
        class="flex h-full cursor-pointer items-center px-4 py-1.5 text-xs sm:text-sm font-medium rounded-full transition-all duration-200 select-none text-neutral-600 dark:text-neutral-400 hover:text-black dark:hover:text-white peer-checked:bg-white peer-checked:text-black peer-checked:shadow-xs peer-checked:dark:bg-white/15 peer-checked:dark:text-white"
      >
        {labels?.[index] ?? filter}
      </label>
    </div>
  {/each}
</fieldset>
