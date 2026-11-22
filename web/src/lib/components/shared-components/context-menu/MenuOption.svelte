<script lang="ts">
  import { optionClickCallbackStore, selectedIdStore } from '#lib/stores/context-menu.store.ts';
  import { Icon, shortcutLabel as computeShortcutLabel, shortcuts, type IconLike, type Shortcut } from '@immich/ui';

  interface Props {
    text: string;
    subtitle?: string;
    icon?: IconLike;
    activeColor?: string;
    textColor?: string;
    onClick: (event: KeyboardEvent | MouseEvent) => void;
    shortcut?: Shortcut | null;
    shortcutLabel?: string;
  }

  let {
    text,
    subtitle = '',
    icon,
    activeColor = 'bg-neutral-100 dark:bg-white/10 text-neutral-900 dark:text-white',
    textColor = 'text-neutral-700 dark:text-neutral-200',
    onClick,
    shortcut = null,
    shortcutLabel = '',
  }: Props = $props();

  const id = $props.id();
  const isActive = $derived($selectedIdStore === id);

  const handleClick = (event: MouseEvent) => {
    // eslint-disable-next-line unicorn/no-optional-chaining-on-undeclared-variable
    $optionClickCallbackStore?.();
    onClick(event);
  };

  if (shortcut && !shortcutLabel) {
    shortcutLabel = computeShortcutLabel(shortcut);
  }
</script>

<svelte:window {@attach shortcuts(shortcut ? [{ shortcut, onShortcut: onClick }] : [])} />

<!-- svelte-ignore a11y_click_events_have_key_events -->
<!-- svelte-ignore a11y_mouse_events_have_key_events -->
<li
  {id}
  onclick={handleClick}
  onmouseover={() => ($selectedIdStore = id)}
  onmouseleave={() => ($selectedIdStore = undefined)}
  class="w-full px-3.5 py-2.5 text-start text-sm font-medium rounded-xl flex cursor-pointer items-center gap-3 transition-colors duration-150 {textColor} focus:ring-2 focus:outline-none focus:ring-inset {isActive
    ? activeColor
    : 'hover:bg-neutral-100/70 dark:hover:bg-white/5'}"
  role="menuitem"
>
  {#if icon}
    <Icon {icon} aria-hidden size="18" class="shrink-0 text-neutral-500 dark:text-neutral-400 group-hover:text-white" />
  {/if}
  <div class="w-full min-w-0">
    <div class="flex justify-between items-center">
      <span class="truncate">{text}</span>
      {#if shortcutLabel}
        <span class="ps-4 text-xs text-neutral-400 dark:text-neutral-500 font-mono">
          {shortcutLabel}
        </span>
      {/if}
    </div>
    {#if subtitle}
      <p class="text-xs text-neutral-500 dark:text-neutral-400 truncate">
        {subtitle}
      </p>
    {/if}
  </div>
</li>
