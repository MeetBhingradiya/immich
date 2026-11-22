<script lang="ts" module>
  export const headerId = 'user-page-header';
</script>

<script lang="ts">
  import NavigationBar from '#lib/components/shared-components/navigation-bar/NavigationBar.svelte';
  import OneDriveFloatingAction from '#lib/components/shared-components/OneDriveFloatingAction.svelte';
  import type { HeaderButtonActionItem } from '#lib/types.ts';
  import { openFileUploadDialog } from '#lib/utils/file-uploader.ts';
  import { Button, ContextMenuButton, HStack, isMenuItemType, type MenuItemType } from '@immich/ui';
  import type { Snippet } from 'svelte';
  import { t } from 'svelte-i18n';
  import { page } from '$app/state';

  interface Props {
    hideNavbar?: boolean;
    title?: string | undefined;
    description?: string | undefined;
    scrollbar?: boolean;
    actions?: Array<HeaderButtonActionItem | MenuItemType>;
    sidebar?: Snippet;
    buttons?: Snippet;
    children?: Snippet;
  }

  let {
    hideNavbar = false,
    title = undefined,
    description = undefined,
    scrollbar = true,
    actions = [],
    sidebar,
    buttons,
    children,
    ...rest
  }: Props = $props();

  const enabledActions = $derived(
    actions
      .filter((action): action is HeaderButtonActionItem => !isMenuItemType(action))
      .filter((action) => action.$if?.() ?? true),
  );

  let scrollbarClass = $derived(scrollbar ? 'immich-scrollbar' : 'scrollbar-hidden');
  let hasTitleClass = $derived(title ? 'top-16 h-[calc(100%-(--spacing(16)))]' : 'top-0 h-full');
</script>

<header>
  {#if !hideNavbar}
    <NavigationBar onUploadClick={() => openFileUploadDialog()} />
  {/if}
</header>
<div
  tabindex="-1"
  class="relative z-0 flex w-full overflow-hidden
    {hideNavbar ? 'h-dvh' : 'h-[calc(100dvh-var(--navbar-height))] max-md:h-[calc(100dvh-var(--navbar-height-md))]'}
    {hideNavbar ? 'pt-(--navbar-height)' : ''}
    {hideNavbar ? 'max-md:pt-(--navbar-height-md)' : ''}"
>
  {#if sidebar}
    {@render sidebar()}
  {/if}

  <main class="relative h-full w-full flex-1 overflow-hidden">
    <div class="{scrollbarClass} absolute {hasTitleClass} w-full overflow-y-auto" {...rest}>
      {@render children?.()}
    </div>

    {#if title || buttons}
      <div class="absolute flex h-16 w-full place-items-center justify-between border-b border-white/10 p-2 text-dark bg-neutral-900/60 backdrop-blur-md">
        <div class="flex items-center gap-2">
          {#if title}
            <div class="pe-8 outline-none text-base font-bold text-white" tabindex="-1" id={headerId}>{title}</div>
          {/if}
          {#if description}
            <p class="text-sm text-neutral-400">{description}</p>
          {/if}
        </div>

        {@render buttons?.()}

        {#if enabledActions.length > 0}
          <div class="hidden md:block">
            <HStack gap={0}>
              {#each enabledActions as action, i (i)}
                <Button
                  variant="ghost"
                  size="small"
                  color={action.color ?? 'secondary'}
                  leadingIcon={action.icon}
                  onclick={(event: MouseEvent) => action.onAction({ event, action })}
                  title={action.data?.title}
                >
                  {action.title}
                </Button>
              {/each}
            </HStack>
          </div>

          <ContextMenuButton aria-label={$t('open')} items={actions} class="md:hidden" />
        {/if}
      </div>
    {/if}
  </main>
</div>

<!-- OneDrive Floating Bottom Action Capsule (Upload / New Album / Search) -->
{#if !page.url.pathname.includes('/admin')}
  <OneDriveFloatingAction onUploadClick={() => openFileUploadDialog()} />
{/if}
