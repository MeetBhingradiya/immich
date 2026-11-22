<script lang="ts">
  import { authManager } from '#lib/managers/auth-manager.svelte.ts';
  import { handleError } from '#lib/utils/handle-error.ts';
  import { activateProduct, getActivationKey } from '#lib/utils/license-utils.ts';
  import { Button, Heading, LoadingSpinner, Text } from '@immich/ui';
  import { t } from 'svelte-i18n';
  import UserPurchaseOptionCard from './IndividualPurchaseOptionCard.svelte';
  import ServerPurchaseOptionCard from './ServerPurchaseOptionCard.svelte';

  interface Props {
    onActivate: () => void;
    showTitle?: boolean;
    showMessage?: boolean;
  }

  let { onActivate, showTitle = true, showMessage = true }: Props = $props();
  let productKey = $state('');
  let isLoading = $state(false);

  const activate = async () => {
    try {
      productKey = productKey.trim();
      isLoading = true;

      const activationKey = await getActivationKey(productKey);
      await activateProduct(productKey, activationKey);

      onActivate();
      authManager.isPurchased = true;
    } catch (error) {
      handleError(error, $t('purchase_failed_activation'));
    } finally {
      isLoading = false;
    }
  };
</script>

<section class="space-y-6">
  {#if showTitle}
    <div class="space-y-1">
      <Heading color="primary" tag="h1" class="text-3xl font-black tracking-tight text-white">
        {$t('purchase_option_title')}
      </Heading>
      <p class="text-sm text-neutral-400">
        {$t('purchase_product_key_description')}
      </p>
    </div>
  {:else}
    <p class="text-sm text-neutral-400">
      {$t('purchase_product_key_description')}
    </p>
  {/if}

  {#if showMessage}
    <div class="rounded-2xl border border-white/10 bg-white/5 p-4 backdrop-blur-md">
      <p class="text-xs leading-relaxed text-neutral-300">
        {$t('purchase_panel_info_1')}
      </p>
    </div>
  {/if}

  <div class="flex flex-col justify-start gap-6 sm:flex-row">
    <ServerPurchaseOptionCard />
    <UserPurchaseOptionCard />
  </div>

  <!-- Activation Key Input - Samsung One UI Card Style -->
  <div class="rounded-3xl border border-white/10 bg-[#121622]/90 p-6 backdrop-blur-2xl shadow-xl">
    <label for="purchaseKey" class="block text-sm font-semibold text-white">
      {$t('purchase_input_suggestion')}
    </label>
    <p class="mt-1 text-xs text-neutral-400">
      Enter your license key (e.g. IMSV-... or IMCL-...) to unlock full supporter features on this server.
    </p>

    <form class="mt-4 flex flex-col gap-3 sm:flex-row sm:items-center" onsubmit={activate}>
      <input
        class="immich-form-input flex-1 rounded-full border border-white/15 bg-neutral-900/80 px-5 py-3 text-sm text-white placeholder-neutral-500 shadow-inner outline-none transition-all focus:border-sky-500 focus:ring-2 focus:ring-sky-500/20"
        id="purchaseKey"
        type="text"
        bind:value={productKey}
        required
        placeholder="IMCL-MEET-BHIN-GRAD-IYA1-2026-FLEX-GOLD-PRO1"
        disabled={isLoading}
      />
      <Button
        type="submit"
        shape="round"
        class="rounded-full px-8 py-3 text-sm font-semibold shadow-lg shadow-sky-600/25 sm:w-auto"
      >
        {#if isLoading}
          <LoadingSpinner />
        {:else}
          {$t('purchase_button_activate')}
        {/if}
      </Button>
    </form>
  </div>
</section>
