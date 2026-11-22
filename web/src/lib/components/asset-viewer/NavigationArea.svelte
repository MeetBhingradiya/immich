<script lang="ts">
  import type { Snippet } from 'svelte';

  interface Props {
    onClick: (e: MouseEvent) => void;
    label: string;
    children?: Snippet;
  }

  let { onClick, label, children }: Props = $props();
</script>

<button
  type="button"
  class="mx-4 my-auto flex size-12 items-center justify-center rounded-full bg-black/50 text-white/90 backdrop-blur-xl border border-white/15 hover:bg-white/20 hover:text-white hover:scale-105 active:scale-95 transition-all duration-200 shadow-[0_4px_24px_rgba(0,0,0,0.6)] cursor-pointer"
  aria-label={label}
  onclick={onClick}
>
  {@render children?.()}
</button>
