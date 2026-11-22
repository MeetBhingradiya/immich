<script lang="ts">
  import { accordionManager } from '#lib/managers/accordion-manager.svelte.ts';
  import { Icon } from '@immich/ui';
  import { onDestroy, type Snippet } from 'svelte';
  import { slide } from 'svelte/transition';

  interface Props {
    title: string;
    subtitle?: string;
    key: string;
    isOpen?: boolean;
    autoScrollTo?: boolean;
    icon?: string;
    subtitleSnippet?: Snippet;
    children?: Snippet;
  }

  let {
    title,
    subtitle = '',
    key,
    isOpen = $bindable(false),
    autoScrollTo = false,
    icon = '',
    subtitleSnippet,
    children,
  }: Props = $props();

  let accordionElement: HTMLDivElement | undefined = $state();

  const getBadgeGradient = (k: string) => {
    if (k.includes('app') || k.includes('feature')) return 'from-emerald-500 to-teal-600 shadow-emerald-500/20';
    if (k.includes('account') || k.includes('user-usage')) return 'from-blue-600 to-indigo-600 shadow-blue-500/20';
    if (k.includes('api') || k.includes('device')) return 'from-cyan-500 to-blue-600 shadow-cyan-500/20';
    if (k.includes('notif')) return 'from-orange-500 to-amber-600 shadow-orange-500/20';
    if (k.includes('pass') || k.includes('oauth') || k.includes('pin')) return 'from-violet-600 to-purple-700 shadow-purple-500/20';
    if (k.includes('purchase')) return 'from-amber-500 to-yellow-500 shadow-amber-500/20';
    if (k.includes('shar')) return 'from-rose-500 to-pink-600 shadow-pink-500/20';
    return 'from-blue-500 to-cyan-600 shadow-blue-500/20';
  };

  $effect(() => {
    isOpen = accordionManager.isOpen(key);
  });

  const toggleOpen = () => {
    if (isOpen) {
      accordionManager.close(key);
    } else {
      accordionManager.open(key);

      if (autoScrollTo) {
        setTimeout(() => {
          accordionElement?.scrollIntoView({
            behavior: 'smooth',
            block: 'start',
          });
        }, 200);
      }
    }
  };

  onDestroy(() => {
    accordionManager.close(key);
  });
</script>

<div
  class="mt-3 rounded-2xl border border-neutral-200/80 bg-white/70 p-4 transition-all duration-200 dark:border-white/10 dark:bg-[#121620]/80 backdrop-blur-xl shadow-sm hover:border-neutral-300 dark:hover:border-white/20 {isOpen
    ? 'dark:border-white/25 border-primary/40 shadow-md'
    : ''}"
  bind:this={accordionElement}
>
  <button
    type="button"
    aria-expanded={isOpen}
    onclick={toggleOpen}
    class="flex w-full place-items-center justify-between text-start"
  >
    <div class="flex place-items-center gap-3.5">
      {#if icon}
        <div
          class="flex h-10 w-10 shrink-0 place-content-center place-items-center rounded-full bg-gradient-to-br {getBadgeGradient(key)} text-white shadow-md"
        >
          <Icon {icon} size="22" class="text-white" aria-hidden />
        </div>
      {/if}
      <div>
        <h2 class="text-base font-semibold text-neutral-900 dark:text-white">
          {title}
        </h2>

        {#if subtitleSnippet}{@render subtitleSnippet()}{:else}
          <p class="mt-0.5 text-xs text-neutral-500 dark:text-neutral-400">{subtitle}</p>
        {/if}
      </div>
    </div>

    <div
      class="flex h-9 w-9 shrink-0 place-content-center place-items-center rounded-full bg-neutral-100 transition-all hover:bg-neutral-200 dark:bg-white/5 dark:text-neutral-300 dark:hover:bg-white/10"
    >
      <svg
        width="18"
        height="18"
        fill="none"
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2.2"
        viewBox="0 0 24 24"
        stroke="currentColor"
      >
        <path d="M19 9l-7 7-7-7" />
      </svg>
    </div>
  </button>

  {#if isOpen}
    <div transition:slide={{ duration: 180 }} class="mt-4 border-t border-neutral-200/60 pt-4 dark:border-white/10">
      <ul class="ms-1 mb-1">
        {@render children?.()}
      </ul>
    </div>
  {/if}
</div>

<style>
  svg {
    transition: transform 0.25s cubic-bezier(0.16, 1, 0.3, 1);
  }

  [aria-expanded='true'] svg {
    transform: rotate(0.5turn);
  }
</style>
