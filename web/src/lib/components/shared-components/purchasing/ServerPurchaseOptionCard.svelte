<script lang="ts">
  import { ImmichProduct } from '#lib/constants.ts';
  import { getLicenseLink } from '#lib/utils/license-utils.ts';
  import { Button, Icon } from '@immich/ui';
  import { mdiCheckCircleOutline, mdiServer } from '@mdi/js';
  import { t } from 'svelte-i18n';
</script>

<!-- SERVER Purchase Option - Samsung One UI Liquid Glass -->
<div
  class="relative w-[min(380px,100%)] overflow-hidden rounded-3xl border border-white/10 bg-[#121622]/90 p-8 backdrop-blur-2xl shadow-2xl transition-all duration-300 hover:border-sky-500/40 hover:shadow-sky-500/10"
>
  <div class="flex items-center gap-4">
    <div
      class="flex h-14 w-14 shrink-0 items-center justify-center rounded-2xl bg-gradient-to-br from-blue-600 to-indigo-600 text-white shadow-lg shadow-blue-500/25"
    >
      <Icon icon={mdiServer} size="32" class="text-white" />
    </div>
    <div>
      <span class="rounded-full bg-blue-500/15 border border-blue-400/30 px-2.5 py-0.5 text-[10px] font-semibold tracking-wider text-blue-300 uppercase">
        Enterprise Server
      </span>
      <p class="mt-0.5 text-lg font-bold text-white">{$t('purchase_server_title')}</p>
    </div>
  </div>

  <div class="mt-6 flex items-baseline gap-2">
    <span class="text-5xl font-black tracking-tight text-white">$100</span>
    <span class="text-sm font-medium text-neutral-400">{$t('purchase_per_server')}</span>
  </div>

  <div class="my-6 border-t border-white/10"></div>

  <div class="flex min-h-48 flex-col justify-between">
    <div class="flex flex-col gap-3">
      <div class="flex items-center gap-3">
        <div class="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-emerald-500/20 text-emerald-400">
          <Icon icon={mdiCheckCircleOutline} size="18" />
        </div>
        <p class="text-xs text-neutral-200">{$t('purchase_server_description_1')}</p>
      </div>

      <div class="flex items-center gap-3">
        <div class="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-emerald-500/20 text-emerald-400">
          <Icon icon={mdiCheckCircleOutline} size="18" />
        </div>
        <p class="text-xs text-neutral-200">{$t('purchase_lifetime_description')}</p>
      </div>

      <div class="flex items-center gap-3">
        <div class="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-emerald-500/20 text-emerald-400">
          <Icon icon={mdiCheckCircleOutline} size="18" />
        </div>
        <p class="text-xs text-neutral-200">{$t('purchase_server_description_2')}</p>
      </div>
    </div>

    <div class="mt-6">
      <Button shape="round" href={getLicenseLink(ImmichProduct.Server)} fullWidth class="rounded-full py-2.5 shadow-lg shadow-blue-600/20">
        {$t('purchase_button_select')}
      </Button>
    </div>
  </div>
</div>
