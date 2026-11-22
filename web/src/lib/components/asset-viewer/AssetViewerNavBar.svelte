<script lang="ts">
  import ActionMenuItem from '#lib/components/ActionMenuItem.svelte';
  import LoadingDots from '#lib/components/LoadingDots.svelte';
  import ArchiveAction from '#lib/components/asset-viewer/actions/ArchiveAction.svelte';
  import DeleteAction from '#lib/components/asset-viewer/actions/DeleteAction.svelte';
  import RestoreAction from '#lib/components/asset-viewer/actions/RestoreAction.svelte';
  import SetVisibilityAction from '#lib/components/asset-viewer/actions/SetVisibilityAction.svelte';
  import type { OnAction, PreAction } from '#lib/components/asset-viewer/actions/action.ts';
  import ButtonContextMenu from '#lib/components/shared-components/context-menu/ButtonContextMenu.svelte';
  import { assetViewerManager } from '#lib/managers/asset-viewer-manager.svelte.ts';
  import { authManager } from '#lib/managers/auth-manager.svelte.ts';
  import { languageManager } from '#lib/managers/language-manager.svelte.ts';
  import { getAlbumAssetActions } from '#lib/services/album.service.ts';
  import { getGlobalActions } from '#lib/services/app.service.ts';
  import { getAssetActions } from '#lib/services/asset.service.ts';
  import { getPersonAssetActions } from '#lib/services/person.service.ts';
  import { getStackActions } from '#lib/services/stack.service.ts';
  import { getSharedLink, withoutIcons } from '#lib/utils.ts';
  import type { OnUndoDelete } from '#lib/utils/actions.ts';
  import { toTimelineAsset } from '#lib/utils/timeline-util.ts';
  import {
    AssetTypeEnum,
    AssetVisibility,
    type AlbumResponseDto,
    type AssetResponseDto,
    type PersonResponseDto,
    type StackResponseDto,
  } from '@immich/sdk';
  import { ActionButton, CommandPaletteDefaultProvider, Icon, Tooltip, type ActionItem } from '@immich/ui';
  import {
    mdiArrowLeft,
    mdiArrowRight,
    mdiCalendarBlankOutline,
    mdiCrop,
    mdiDotsHorizontal,
    mdiFullscreen,
    mdiVideoOutline,
  } from '@mdi/js';
  import { t } from 'svelte-i18n';

  interface Props {
    asset: AssetResponseDto;
    album?: AlbumResponseDto;
    person?: PersonResponseDto | null;
    stack?: StackResponseDto;
    preAction: PreAction;
    onAction: OnAction;
    onUndoDelete?: OnUndoDelete;
    onClose?: () => void;
    isPlayingOriginalVideo: boolean;
    setPlayOriginalVideo: (value: boolean) => void;
  }

  let {
    asset,
    album,
    person = null,
    stack,
    preAction,
    onAction,
    onUndoDelete = undefined,
    onClose,
    isPlayingOriginalVideo = false,
    setPlayOriginalVideo,
  }: Props = $props();

  const isOwner = $derived(authManager.authenticated && asset.ownerId === authManager.user.id);
  const isLocked = $derived(asset.visibility === AssetVisibility.Locked);

  const { Cast } = $derived(getGlobalActions($t));

  const Close: ActionItem = $derived({
    title: $t('go_back'),
    icon: languageManager.rtl ? mdiArrowRight : mdiArrowLeft,
    $if: () => !!onClose && !assetViewerManager.isFaceEditMode && !assetViewerManager.isEditFacesPanelOpen,
    onAction: () => onClose?.(),
    shortcuts: [{ key: 'Escape' }],
  });

  const PlayOriginalVideo: ActionItem = $derived({
    title: isPlayingOriginalVideo ? $t('play_transcoded_video') : $t('play_original_video'),
    icon: mdiVideoOutline,
    $if: () => asset.type === AssetTypeEnum.Video,
    onAction: () => setPlayOriginalVideo(!isPlayingOriginalVideo),
  });

  const Actions = $derived(getAssetActions($t, { ...asset, stackPrimaryAssetId: stack?.primaryAssetId }, album));
  const StackActions = $derived(getStackActions($t, stack, asset));
  const sharedLink = getSharedLink();

  const formattedDate = $derived.by(() => {
    const raw = asset.localDateTime || asset.fileCreatedAt;
    if (!raw) return '';
    try {
      const d = new Date(raw);
      if (isNaN(d.getTime())) return '';
      return d.toLocaleDateString(undefined, { year: 'numeric', month: 'long', day: 'numeric' });
    } catch {
      return '';
    }
  });
</script>

<CommandPaletteDefaultProvider name={$t('assets')} actions={withoutIcons([Close, Cast, ...Object.values(Actions)])} />

<div
  class="relative isolate flex h-14 place-items-center justify-between px-6 bg-transparent transition-transform duration-200"
>
  <div class="flex items-center gap-3">
    {#if onClose && !assetViewerManager.isFaceEditMode && !assetViewerManager.isEditFacesPanelOpen}
      <button
        type="button"
        class="flex size-9 items-center justify-center rounded-full hover:bg-white/10 text-white/90 hover:text-white transition-colors cursor-pointer"
        onclick={() => onClose?.()}
        title={$t('go_back')}
      >
        <Icon icon={languageManager.rtl ? mdiArrowRight : mdiArrowLeft} size="20" />
      </button>
    {/if}
    {#if formattedDate}
      <div class="flex items-center gap-2 text-sm font-medium text-white/90 select-none">
        <Icon icon={mdiCalendarBlankOutline} size="16" class="text-white/70" />
        <span>{formattedDate}</span>
      </div>
    {/if}
  </div>

  <div
    class="flex items-center gap-1 px-2.5 py-1 rounded-full bg-neutral-900/80 backdrop-blur-2xl border border-white/10 shadow-2xl"
    data-testid="asset-viewer-navbar-actions"
  >
    {#if assetViewerManager.isImageLoading}
      <Tooltip text={$t('loading')}>
        {#snippet child({ props })}
          <div {...props} role="status" aria-label={$t('loading')}>
            <LoadingDots class="mx-1" />
          </div>
        {/snippet}
      </Tooltip>
    {/if}

    <!-- OneDrive-style prominent Edit Pill -->
    {#if Actions.Edit && (Actions.Edit.$if?.() ?? true)}
      <button
        type="button"
        class="flex items-center gap-1.5 px-3 py-1.5 rounded-full hover:bg-white/15 text-white text-xs font-medium transition-colors cursor-pointer"
        onclick={() => Actions.Edit.onAction?.()}
        title={$t('edit')}
      >
        <Icon icon={mdiCrop} size="16" />
        <span>{$t('edit')}</span>
      </button>
    {/if}

    <ActionButton action={Actions.Share} />
    {#if isOwner}
      <DeleteAction {asset} {onAction} {preAction} {onUndoDelete} />
    {/if}
    <ActionButton action={Actions.Favorite} />
    <ActionButton action={Actions.Unfavorite} />

    {#if !sharedLink}
      <ButtonContextMenu direction="left" align="top-right" color="secondary" title={$t('more')} icon={mdiDotsHorizontal}>
        <ActionMenuItem action={Actions.PlaySlideshow} />
        <ActionMenuItem action={Actions.Download} />
        <ActionMenuItem action={Actions.DownloadOriginal} />
        <ActionMenuItem action={Actions.Copy} />
        <ActionMenuItem action={Actions.Offline} />
        <ActionMenuItem action={Actions.PlayMotionPhoto} />
        <ActionMenuItem action={Actions.StopMotionPhoto} />
        <ActionMenuItem action={Actions.SharedLinkDownload} />

        {#if !isLocked && asset.isTrashed}
          <RestoreAction {asset} {onAction} />
        {/if}

        <ActionMenuItem action={Actions.AddToAlbum} />
        <ActionMenuItem action={Actions.RemoveFromAlbum} />

        <ActionMenuItem action={StackActions.AddUploads} />
        <ActionMenuItem action={StackActions.Unstack} />
        <ActionMenuItem action={StackActions.KeepThisDeleteOthers} />
        <ActionMenuItem action={StackActions.SetPrimaryAsset} />
        <ActionMenuItem action={StackActions.RemoveAsset} />

        {#if album}
          {const { SetCover } = $derived(getAlbumAssetActions($t, album, asset))}
          <ActionMenuItem action={SetCover} />
        {/if}
        {#if person}
          {const { SetFeaturedPhoto } = $derived(getPersonAssetActions($t, person, asset))}
          <ActionMenuItem action={SetFeaturedPhoto} />
        {/if}

        <ActionMenuItem action={Actions.SetProfilePicture} />

        {#if isOwner && !isLocked}
          <ArchiveAction {asset} {onAction} {preAction} />
        {/if}
        <ActionMenuItem action={Actions.ViewInTimeline} />
        <ActionMenuItem action={Actions.ViewSimilar} />

        {#if !asset.isTrashed && isOwner}
          <SetVisibilityAction asset={toTimelineAsset(asset)} {onAction} {preAction} />
        {/if}

        <ActionMenuItem action={PlayOriginalVideo} />

        {#if isOwner}
          <hr />
          <ActionMenuItem action={Actions.RefreshFacesJob} />
          <ActionMenuItem action={Actions.RefreshMetadataJob} />
          <ActionMenuItem action={Actions.RegenerateThumbnailJob} />
          <ActionMenuItem action={Actions.TranscodeVideoJob} />
        {/if}
      </ButtonContextMenu>
    {/if}
  </div>
</div>
