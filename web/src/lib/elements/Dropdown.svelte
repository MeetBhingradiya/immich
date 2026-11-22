<script lang="ts" module>
  // Necessary for eslint
  /* eslint-disable @typescript-eslint/no-explicit-any */
  type T = any;

  export type RenderedOption = {
    title: string;
    icon?: string;
    disabled?: boolean;
  };
</script>

<script lang="ts" generics="T">
  import { clickOutside } from '#lib/actions/click-outside.ts';
  import { Button, Icon, Text } from '@immich/ui';
  import { mdiCheck } from '@mdi/js';
  import { isEqual } from 'lodash-es';
  import { fly } from 'svelte/transition';

  interface Props {
    class?: string;
    options: T[];
    selectedOption?: any;
    showMenu?: boolean;
    controlable?: boolean;
    hideTextOnSmallScreen?: boolean;
    title?: string | undefined;
    position?: 'bottom-left' | 'bottom-right';
    onSelect: (option: T) => void;
    onClickOutside?: () => void;
    render?: (item: T) => string | RenderedOption;
  }

  let {
    position = 'bottom-left',
    class: className = '',
    options,
    selectedOption = $bindable(options[0]),
    showMenu = $bindable(false),
    controlable = false,
    hideTextOnSmallScreen = true,
    title = undefined,
    onSelect,
    onClickOutside = () => {},
    render = String,
  }: Props = $props();

  const handleClickOutside = () => {
    if (!controlable) {
      showMenu = false;
    }

    onClickOutside();
  };

  const handleSelectOption = (option: T) => {
    onSelect(option);
    selectedOption = option;

    showMenu = false;
  };

  const renderOption = (option: T): RenderedOption => {
    const renderedOption = render(option);
    switch (typeof renderedOption) {
      case 'string': {
        return { title: renderedOption };
      }
      default: {
        return {
          title: renderedOption.title,
          icon: renderedOption.icon,
          disabled: renderedOption.disabled,
        };
      }
    }
  };

  let renderedSelectedOption = $derived(renderOption(selectedOption));

  const getAlignClass = (position: 'bottom-left' | 'bottom-right') => {
    switch (position) {
      case 'bottom-left': {
        return 'inset-s-0';
      }
      case 'bottom-right': {
        return 'inset-e-0';
      }

      default: {
        return '';
      }
    }
  };
</script>

<div {@attach clickOutside({ onOutclick: handleClickOutside, onEscape: handleClickOutside })} class="relative">
  <!-- BUTTON TITLE -->
  <Button onclick={() => (showMenu = true)} fullWidth {title} variant="ghost" color="secondary" size="small">
    {#if renderedSelectedOption?.icon}
      <Icon icon={renderedSelectedOption.icon} />
    {/if}
    <Text class={hideTextOnSmallScreen ? 'hidden sm:block' : ''}>{renderedSelectedOption.title}</Text>
  </Button>

  <!-- DROP DOWN MENU -->
  {#if showMenu}
    <div
      transition:fly={{ y: -20, duration: 200 }}
      class="absolute z-50 flex max-h-[70vh] min-w-72 immich-scrollbar flex-col gap-0.5 overflow-y-auto rounded-2xl bg-white/95 p-1.5 text-sm font-medium text-neutral-800 shadow-2xl backdrop-blur-2xl border border-slate-200/80 dark:border-white/10 dark:bg-neutral-900/95 dark:text-neutral-100 {className} {getAlignClass(
        position,
      )}"
    >
      {#each options as option (option)}
        {const renderedOption = renderOption(option)}
        {const isCurrent = isEqual(selectedOption, option)}
        <button
          type="button"
          class="grid grid-cols-[32px_1fr] items-center px-3 py-2 rounded-xl text-start transition-colors duration-150 disabled:opacity-40 cursor-pointer {isCurrent ? 'bg-primary-50 text-primary dark:bg-white/10 dark:text-white font-semibold' : 'text-neutral-700 dark:text-neutral-200 hover:bg-neutral-100 dark:hover:bg-white/5'}"
          disabled={renderedOption.disabled}
          onclick={() => !renderedOption.disabled && handleSelectOption(option)}
        >
          {#if isCurrent}
            <div class="text-primary dark:text-blue-400">
              <Icon icon={mdiCheck} size="18" />
            </div>
            <p class="justify-self-start truncate">
              {renderedOption.title}
            </p>
          {:else}
            <div></div>
            <p class="justify-self-start truncate">
              {renderedOption.title}
            </p>
          {/if}
        </button>
      {/each}
    </div>
  {/if}
</div>
