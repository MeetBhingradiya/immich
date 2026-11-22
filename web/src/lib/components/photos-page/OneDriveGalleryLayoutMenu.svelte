<script lang="ts">
  import { clickOutside } from '#lib/actions/click-outside.ts';
  import type { TimelineManager } from '#lib/managers/timeline-manager/timeline-manager.svelte.ts';
  import { onMount } from 'svelte';

  interface Props {
    timelineManager?: TimelineManager;
  }

  let { timelineManager }: Props = $props();

  let isOpen = $state(false);
  let layoutMode = $state<'river' | 'waterfall' | 'square'>('river');
  let densityMode = $state<'roomy' | 'compact'>('compact');
  let dateMode = $state<'dynamic' | 'inline'>('inline');

  onMount(() => {
    const savedLayout = localStorage.getItem('onedrive_gallery_layout');
    if (savedLayout === 'river' || savedLayout === 'waterfall' || savedLayout === 'square') {
      layoutMode = savedLayout;
    }

    const savedDensity = localStorage.getItem('onedrive_gallery_density');
    if (savedDensity === 'roomy' || savedDensity === 'compact') {
      densityMode = savedDensity;
      applyDensity(savedDensity);
    }

    const savedDate = localStorage.getItem('onedrive_gallery_date');
    if (savedDate === 'dynamic' || savedDate === 'inline') {
      dateMode = savedDate;
    }
  });

  function applyDensity(density: 'roomy' | 'compact') {
    if (!timelineManager?.virtualScrollManager) return;
    if (density === 'roomy') {
      timelineManager.virtualScrollManager.setLayoutOptions({ rowHeight: 280, gap: 14 });
    } else {
      timelineManager.virtualScrollManager.setLayoutOptions({ rowHeight: 165, gap: 8 });
    }
  }

  function setLayout(mode: 'river' | 'waterfall' | 'square') {
    layoutMode = mode;
    localStorage.setItem('onedrive_gallery_layout', mode);
  }

  function setDensity(mode: 'roomy' | 'compact') {
    densityMode = mode;
    localStorage.setItem('onedrive_gallery_density', mode);
    applyDensity(mode);
  }

  function setDate(mode: 'dynamic' | 'inline') {
    dateMode = mode;
    localStorage.setItem('onedrive_gallery_date', mode);
  }
</script>

<div class="relative z-30" {@attach clickOutside({ onOutclick: () => (isOpen = false) })}>
  <!-- OneDrive Gallery Layout Toggle Button -->
  <button
    type="button"
    class="flex items-center gap-2 px-3 py-1.5 rounded-full bg-neutral-900/80 hover:bg-neutral-800 text-white/90 hover:text-white border border-white/10 backdrop-blur-xl text-xs font-medium transition-all shadow-lg active:scale-95 cursor-pointer"
    onclick={() => (isOpen = !isOpen)}
    aria-label="Layout options"
    title="Change gallery layout and density"
  >
    <svg class="size-4" viewBox="0 0 24 24" fill="currentColor">
      <path d="M4 5h7v5H4V5zm0 9h7v5H4v-5zm9-9h7v14h-7V5z" />
    </svg>
    <span class="capitalize">{layoutMode}</span>
    <svg class="size-3 transition-transform {isOpen ? 'rotate-180' : ''}" viewBox="0 0 24 24" fill="currentColor">
      <path d="M7.41 8.59L12 13.17l4.59-4.58L18 10l-6 6-6-6 1.41-1.41z" />
    </svg>
  </button>

  {#if isOpen}
    <!-- OneDrive exact layout popover panel -->
    <div
      class="absolute right-0 top-10 w-64 rounded-2xl bg-neutral-900/98 backdrop-blur-2xl border border-white/10 shadow-[0_20px_50px_rgba(0,0,0,0.7)] p-4 text-white z-50 flex flex-col gap-4 select-none duration-150 animate-in fade-in zoom-in-95"
    >
      <!-- Layout Section -->
      <div class="flex flex-col gap-2">
        <span class="text-xs font-semibold text-neutral-400">Layout</span>
        <div class="grid grid-cols-3 gap-2">
          <!-- River -->
          <button
            type="button"
            onclick={() => setLayout('river')}
            class="flex flex-col items-center justify-center gap-1.5 p-2 rounded-xl transition-all cursor-pointer {layoutMode === 'river'
              ? 'border-2 border-[#0078d4] bg-white/10 text-white shadow-sm'
              : 'border border-white/5 hover:border-white/20 text-neutral-400 hover:text-white bg-white/2'}"
          >
            <div class="size-7 flex flex-col justify-between p-1 bg-white/5 rounded-md">
              <div class="w-full h-2 bg-current rounded-[2px]"></div>
              <div class="flex gap-1">
                <div class="w-1/2 h-2 bg-current rounded-[2px]"></div>
                <div class="w-1/2 h-2 bg-current rounded-[2px]"></div>
              </div>
            </div>
            <span class="text-[11px] font-semibold">River</span>
          </button>

          <!-- Waterfall -->
          <button
            type="button"
            onclick={() => setLayout('waterfall')}
            class="flex flex-col items-center justify-center gap-1.5 p-2 rounded-xl transition-all cursor-pointer {layoutMode === 'waterfall'
              ? 'border-2 border-[#0078d4] bg-white/10 text-white shadow-sm'
              : 'border border-white/5 hover:border-white/20 text-neutral-400 hover:text-white bg-white/2'}"
          >
            <div class="size-7 flex gap-1 p-1 bg-white/5 rounded-md">
              <div class="w-1/2 flex flex-col justify-between">
                <div class="w-full h-3 bg-current rounded-[2px]"></div>
                <div class="w-full h-1.5 bg-current rounded-[2px]"></div>
              </div>
              <div class="w-1/2 flex flex-col justify-between">
                <div class="w-full h-1.5 bg-current rounded-[2px]"></div>
                <div class="w-full h-3 bg-current rounded-[2px]"></div>
              </div>
            </div>
            <span class="text-[11px] font-semibold">Waterfall</span>
          </button>

          <!-- Square -->
          <button
            type="button"
            onclick={() => setLayout('square')}
            class="flex flex-col items-center justify-center gap-1.5 p-2 rounded-xl transition-all cursor-pointer {layoutMode === 'square'
              ? 'border-2 border-[#0078d4] bg-white/10 text-white shadow-sm'
              : 'border border-white/5 hover:border-white/20 text-neutral-400 hover:text-white bg-white/2'}"
          >
            <div class="size-7 grid grid-cols-2 gap-1 p-1 bg-white/5 rounded-md">
              <div class="size-full bg-current rounded-[2px]"></div>
              <div class="size-full bg-current rounded-[2px]"></div>
              <div class="size-full bg-current rounded-[2px]"></div>
              <div class="size-full bg-current rounded-[2px]"></div>
            </div>
            <span class="text-[11px] font-semibold">Square</span>
          </button>
        </div>
      </div>

      <!-- Density Section -->
      <div class="flex flex-col gap-2">
        <span class="text-xs font-semibold text-neutral-400">Density</span>
        <div class="grid grid-cols-2 gap-2">
          <button
            type="button"
            onclick={() => setDensity('roomy')}
            class="py-1.5 px-3 rounded-full text-xs font-semibold transition-all cursor-pointer {densityMode === 'roomy'
              ? 'border-2 border-[#0078d4] bg-white/10 text-white shadow-sm'
              : 'border border-white/10 text-neutral-400 hover:text-white hover:bg-white/5'}"
          >
            Roomy
          </button>
          <button
            type="button"
            onclick={() => setDensity('compact')}
            class="py-1.5 px-3 rounded-full text-xs font-semibold transition-all cursor-pointer {densityMode === 'compact'
              ? 'border-2 border-[#0078d4] bg-white/10 text-white shadow-sm'
              : 'border border-white/10 text-neutral-400 hover:text-white hover:bg-white/5'}"
          >
            Compact
          </button>
        </div>
      </div>

      <!-- Date Section -->
      <div class="flex flex-col gap-2">
        <span class="text-xs font-semibold text-neutral-400">Date</span>
        <div class="grid grid-cols-2 gap-2">
          <button
            type="button"
            onclick={() => setDate('dynamic')}
            class="py-1.5 px-3 rounded-full text-xs font-semibold transition-all cursor-pointer {dateMode === 'dynamic'
              ? 'border-2 border-[#0078d4] bg-white/10 text-white shadow-sm'
              : 'border border-white/10 text-neutral-400 hover:text-white hover:bg-white/5'}"
          >
            Dynamic
          </button>
          <button
            type="button"
            onclick={() => setDate('inline')}
            class="py-1.5 px-3 rounded-full text-xs font-semibold transition-all cursor-pointer {dateMode === 'inline'
              ? 'border-2 border-[#0078d4] bg-white/10 text-white shadow-sm'
              : 'border border-white/10 text-neutral-400 hover:text-white hover:bg-white/5'}"
          >
            Inline
          </button>
        </div>
      </div>
    </div>
  {/if}
</div>
