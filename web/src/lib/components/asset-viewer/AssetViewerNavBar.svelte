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
  class="relative isolate flex h-16 place-items-center justify-between px-4 bg-neutral-950/40 backdrop-blur-xl border-b border-white/5 drop-shadow-[0_4px_12px_rgba(0,0,0,0.5)] transition-transform duration-200"
>
  <div class="pointer-events-none absolute inset-x-0 top-0 -z-10 h-24 bg-black/40 mask-smoothstep-to-bottom"></div>
  <div class="flex items-center gap-2">
    <div class="dark">
      <ActionButton action={Close} />
    </div>
    {#if formattedDate}
      <div class="flex items-center gap-1.5 text-white/90 font-medium text-sm select-none ps-1">
        <Icon icon={mdiCalendarBlankOutline} size="16" class="text-neutral-400" />
        <span>{formattedDate}</span>
      </div>
    {/if}
  </div>

  <div
    class="dark -m-1 flex items-center gap-2 overflow-x-auto p-1 *:shrink-0"
    data-testid="asset-viewer-navbar-actions"
  >
    {#if assetViewerManager.isImageLoading}
      <Tooltip text={$t('loading')}>
        {#snippet child({ props })}
          <div {...props} role="status" aria-label={$t('loading')}>
            <LoadingDots class="me-1" />
          </div>
        {/snippet}
      </Tooltip>
    {/if}

    <!-- OneDrive-style prominent Edit Pill -->
    {#if Actions.Edit && (Actions.Edit.$if?.() ?? true)}
      <button
        type="button"
        class="flex items-center gap-1.5 px-3.5 py-1.5 rounded-full bg-white/12 hover:bg-white/20 text-white text-xs font-semibold backdrop-blur-md border border-white/15 transition-all duration-200 active:scale-95 cursor-pointer shadow-xs me-1"
        onclick={() => Actions.Edit.onAction?.()}
        title={$t('edit')}
      >
        <Icon icon={mdiCrop} size="15" />
        <span>{$t('edit')}</span>
      </button>
    {/if}

    <ActionButton action={Cast} />
    <ActionButton action={Actions.Share} />
    <ActionButton action={Actions.Offline} />
    <ActionButton action={Actions.ZoomIn} />
    <ActionButton action={Actions.ZoomOut} />
    <ActionButton action={Actions.PlayMotionPhoto} />
    <ActionButton action={Actions.StopMotionPhoto} />
    <ActionButton action={Actions.Copy} />
    <ActionButton action={Actions.SharedLinkDownload} />
    <ActionButton action={Actions.Info} />
    <ActionButton action={Actions.Favorite} />
    <ActionButton action={Actions.Unfavorite} />

    {#if isOwner}
      <DeleteAction {asset} {onAction} {preAction} {onUndoDelete} />
    {/if}

    {#if !sharedLink}
      <ButtonContextMenu direction="left" align="top-right" color="secondary" title={$t('more')} icon={mdiDotsHorizontal}>
        <ActionMenuItem action={Actions.PlaySlideshow} />

        <ActionMenuItem action={Actions.Download} />
        <ActionMenuItem action={Actions.DownloadOriginal} />

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
