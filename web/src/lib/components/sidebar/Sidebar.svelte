<script lang="ts">
  import { clickOutside } from '#lib/actions/click-outside.ts';
  import { focusTrap } from '#lib/actions/focus-trap.ts';
  import { menuButtonId } from '#lib/components/shared-components/navigation-bar/NavigationBar.svelte';
  import { mediaQueryManager } from '#lib/stores/media-query-manager.svelte.ts';
  import { sidebarStore } from '#lib/stores/sidebar.svelte.ts';
  import { onMount, type Snippet } from 'svelte';

  interface Props {
    ariaLabel?: string;
    children?: Snippet;
  }

  let { ariaLabel, children }: Props = $props();

  const isMobileOverlay = $derived(!mediaQueryManager.isFullSidebar && sidebarStore.isOpen);
  const isHidden = $derived(sidebarStore.isHidden);
  const isCollapsed = $derived(sidebarStore.isCollapsed);
  const isExpanded = $derived(sidebarStore.isExpanded);

  let isDragging = $state(false);

  const startResize = (event: MouseEvent) => {
    event.preventDefault();
    isDragging = true;
    const onMouseMove = (e: MouseEvent) => {
      sidebarStore.setWidth(e.clientX);
    };
    const onMouseUp = () => {
      isDragging = false;
      window.removeEventListener('mousemove', onMouseMove);
      window.removeEventListener('mouseup', onMouseUp);
    };
    window.addEventListener('mousemove', onMouseMove);
    window.addEventListener('mouseup', onMouseUp);
  };

  const handleDoubleClick = () => {
    sidebarStore.resetWidth();
  };

  onMount(() => {
    if (!mediaQueryManager.isFullSidebar) {
      sidebarStore.reset();
    }
  });

  const closeSidebar = () => {
    if (!isMobileOverlay) {
      return;
    }
    sidebarStore.reset();
    document.querySelector<HTMLButtonElement>(`#${menuButtonId}`)?.focus();
  };
</script>

<nav
  id="sidebar"
  aria-label={ariaLabel}
  tabindex="-1"
  style={mediaQueryManager.isFullSidebar ? `width: ${sidebarStore.currentWidthPx}px;` : undefined}
  class="relative z-1 overflow-x-hidden overflow-y-auto bg-light pt-6 transition-[width] duration-150 select-none {isDragging ? 'cursor-col-resize select-none !transition-none' : ''}"
  class:w-0={isHidden}
  class:w-[min(100vw,16rem)]={isMobileOverlay}
  class:shadow-2xl={isMobileOverlay}
  class:dark:border-e-immich-dark-gray={isMobileOverlay || isExpanded}
  class:border-r={isMobileOverlay || isExpanded || isCollapsed}
  class:sidebar-rail={isCollapsed}
  data-testid="sidebar-parent"
  inert={isHidden}
  {@attach clickOutside({ onOutclick: closeSidebar, onEscape: isMobileOverlay ? closeSidebar : undefined })}
  {@attach focusTrap({ active: isMobileOverlay })}
>
  <div class="flex h-max min-h-full flex-col gap-1 {isCollapsed ? 'px-2 items-center' : 'pe-4 ps-2'}">
    {@render children?.()}
  </div>

  {#if mediaQueryManager.isFullSidebar && isExpanded}
    <!-- Resizable splitter drag handle strip -->
    <div
      role="separator"
      tabindex="-1"
      aria-orientation="vertical"
      aria-label="Resize sidebar"
      onmousedown={startResize}
      ondblclick={handleDoubleClick}
      title="Drag to resize, double click to reset"
      class="absolute top-0 right-0 z-20 h-full w-1.5 cursor-col-resize transition-colors hover:w-2 hover:bg-primary/40 active:bg-primary active:w-2"
    ></div>
  {/if}
</nav>

<style>
  :global(.sidebar-rail .truncate) {
    display: none !important;
  }
  :global(.sidebar-rail a) {
    justify-content: center !important;
    padding-left: 0.5rem !important;
    padding-right: 0.5rem !important;
    border-radius: 9999px !important;
    width: 3rem !important;
    height: 3rem !important;
    margin: 0.125rem auto !important;
  }
  :global(.sidebar-rail a > div) {
    justify-content: center !important;
    gap: 0 !important;
  }
  :global(.sidebar-rail .hover\:text-primary) {
    justify-content: center !important;
  }
</style>
