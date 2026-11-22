<script lang="ts">
  import { effectsManager, type MarkupPoint, type MarkupStroke } from '#lib/managers/edit/effects-manager.svelte.ts';
  import { ResizeBoundary, transformManager } from '#lib/managers/edit/transform-manager.svelte.ts';
  import { getAssetMediaUrl } from '#lib/utils.ts';
  import { getAltText } from '#lib/utils/thumbnail-util.ts';
  import { toTimelineAsset } from '#lib/utils/timeline-util.ts';
  import { AssetMediaSize, type AssetResponseDto } from '@immich/sdk';
  import { Icon } from '@immich/ui';
  import { onMount } from 'svelte';
  import { t } from 'svelte-i18n';

  interface Props {
    asset: AssetResponseDto;
  }

  let { asset }: Props = $props();

  // viewBox 0 0 24 24 is assumed. Without rotation this icon is top-left.
  const cornerIcon = 'M 12 24 L 12 12 L 24 12';

  let canvasContainer = $state<HTMLElement | null>(null);
  let markupCanvas = $state<HTMLCanvasElement | null>(null);
  let isDrawing = $state(false);
  let currentStroke = $state<MarkupStroke | null>(null);

  let imageSrc = $derived(
    getAssetMediaUrl({ id: asset.id, cacheKey: asset.thumbhash, edited: false, size: AssetMediaSize.Preview }),
  );

  let imageTransform = $derived.by(() => {
    const transforms: string[] = [];

    if (transformManager.mirrorHorizontal) {
      transforms.push('scaleX(-1)');
    }
    if (transformManager.mirrorVertical) {
      transforms.push('scaleY(-1)');
    }

    return transforms.join(' ');
  });

  const edges = [ResizeBoundary.Top, ResizeBoundary.Right, ResizeBoundary.Bottom, ResizeBoundary.Left];
  const corners = [
    ResizeBoundary.TopLeft,
    ResizeBoundary.TopRight,
    ResizeBoundary.BottomRight,
    ResizeBoundary.BottomLeft,
  ];
  function rotateBoundary(arr: ResizeBoundary[], input: ResizeBoundary, times: number) {
    return arr[(arr.indexOf(input) + times) % 4];
  }

  function redrawCanvas() {
    if (!markupCanvas) return;
    const ctx = markupCanvas.getContext('2d');
    if (!ctx) return;

    ctx.clearRect(0, 0, markupCanvas.width, markupCanvas.height);

    for (const stroke of effectsManager.strokes) {
      drawStroke(ctx, stroke);
    }
    if (currentStroke) {
      drawStroke(ctx, currentStroke);
    }
  }

  function drawStroke(ctx: CanvasRenderingContext2D, stroke: MarkupStroke) {
    if (stroke.points.length < 2) return;
    ctx.save();
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';

    if (stroke.tool === 'eraser') {
      ctx.globalCompositeOperation = 'destination-out';
      ctx.lineWidth = stroke.width * 2.5;
    } else if (stroke.tool === 'highlighter') {
      ctx.globalCompositeOperation = 'source-over';
      ctx.globalAlpha = 0.4;
      ctx.strokeStyle = stroke.color;
      ctx.lineWidth = stroke.width * 2.5;
    } else {
      ctx.globalCompositeOperation = 'source-over';
      ctx.globalAlpha = 1.0;
      ctx.strokeStyle = stroke.color;
      ctx.lineWidth = stroke.width;
    }

    ctx.beginPath();
    ctx.moveTo(stroke.points[0].x, stroke.points[0].y);
    for (let i = 1; i < stroke.points.length; i++) {
      ctx.lineTo(stroke.points[i].x, stroke.points[i].y);
    }
    ctx.stroke();
    ctx.restore();
  }

  $effect(() => {
    void effectsManager.strokes;
    void effectsManager.undoneStrokes;
    redrawCanvas();
  });

  function getCanvasCoords(e: PointerEvent): MarkupPoint | null {
    if (!markupCanvas) return null;
    const rect = markupCanvas.getBoundingClientRect();
    const scaleX = markupCanvas.width / rect.width;
    const scaleY = markupCanvas.height / rect.height;
    return {
      x: (e.clientX - rect.left) * scaleX,
      y: (e.clientY - rect.top) * scaleY,
    };
  }

  function onPointerDown(e: PointerEvent) {
    if (effectsManager.activeMode !== 'markup') return;
    const pt = getCanvasCoords(e);
    if (!pt) return;
    isDrawing = true;
    currentStroke = {
      tool: effectsManager.markupTool,
      color: effectsManager.markupColor,
      width: effectsManager.markupWidth,
      points: [pt],
    };
    redrawCanvas();
  }

  function onPointerMove(e: PointerEvent) {
    if (!isDrawing || !currentStroke) return;
    const pt = getCanvasCoords(e);
    if (!pt) return;
    currentStroke.points.push(pt);
    redrawCanvas();
  }

  function onPointerUp() {
    if (!isDrawing || !currentStroke) return;
    isDrawing = false;
    if (currentStroke.points.length > 1) {
      effectsManager.addStroke(currentStroke);
    }
    currentStroke = null;
    redrawCanvas();
  }

  onMount(() => {
    const resizeObserver = new ResizeObserver(() => {
      transformManager.resizeCanvas();
      if (markupCanvas && transformManager.cropAreaEl) {
        markupCanvas.width = transformManager.cropAreaEl.clientWidth || 800;
        markupCanvas.height = transformManager.cropAreaEl.clientHeight || 600;
        redrawCanvas();
      }
    });

    resizeObserver.observe(canvasContainer!);

    return () => {
      resizeObserver.disconnect();
    };
  });
</script>

<div class="flex size-full flex-col items-center justify-center p-8" bind:this={canvasContainer}>
  <div
    class="crop-area relative max-h-full max-w-full transition-transform motion-reduce:transition-none"
    class:rotated={transformManager.normalizedRotation % 180 > 0}
    style:rotate={transformManager.imageRotation + 'deg'}
    bind:this={transformManager.cropAreaEl}
    aria-label="Crop area"
  >
    <img
      draggable="false"
      src={imageSrc}
      alt={$getAltText(toTimelineAsset(asset))}
      class="h-full transition-transform select-none motion-reduce:transition-none"
      style:transform={imageTransform}
      style:filter={effectsManager.cssFilter}
      onload={(e) => {
        if (markupCanvas) {
          const target = e.currentTarget as HTMLImageElement;
          markupCanvas.width = target.clientWidth || 800;
          markupCanvas.height = target.clientHeight || 600;
          redrawCanvas();
        }
      }}
    />

    <!-- Real-time Markup Canvas -->
    <canvas
      bind:this={markupCanvas}
      class="absolute inset-0 size-full {effectsManager.activeMode === 'markup' ? 'pointer-events-auto cursor-crosshair z-20' : 'pointer-events-none z-10'}"
      onpointerdown={onPointerDown}
      onpointermove={onPointerMove}
      onpointerup={onPointerUp}
      onpointerleave={onPointerUp}
    ></canvas>

    {#if effectsManager.activeMode === 'crop'}
      <div
        class={[
          'overlay pointer-events-none absolute top-0 size-full transition-colors motion-reduce:transition-none',
          transformManager.isInteracting ? 'bg-black/30' : 'bg-black/56',
        ]}
        bind:this={transformManager.overlayEl}
      ></div>
      <div class="crop-frame absolute border-2 border-white" bind:this={transformManager.cropFrame}>
        <!-- OneDrive-style Aspect Ratio & Resolution Badges -->
        {#if transformManager.cropAspectRatio && transformManager.cropAspectRatio !== 'free'}
          <div class="pointer-events-none absolute -top-8 left-1/2 -translate-x-1/2 px-2.5 py-0.5 rounded-md bg-black/75 backdrop-blur-md border border-white/20 text-[11px] font-semibold text-white tracking-wide shadow-lg select-none">
            {transformManager.cropAspectRatio}
          </div>
        {/if}

        {#if transformManager.cropImageSize?.width && transformManager.cropImageSize?.height}
          <div class="pointer-events-none absolute -bottom-8 left-1/2 -translate-x-1/2 px-2.5 py-0.5 rounded-md bg-black/75 backdrop-blur-md border border-white/20 text-[11px] font-mono text-neutral-300 tracking-wide shadow-lg select-none">
            {Math.round(transformManager.cropImageSize.width)} x {Math.round(transformManager.cropImageSize.height)}
          </div>
        {/if}

        <!-- svelte-ignore a11y_no_static_element_interactions -->
        <div
          class={[
            'grid size-full cursor-move transition-opacity motion-reduce:transition-none',
            transformManager.isInteracting ? 'opacity-100' : 'opacity-0',
          ]}
          onmousedown={(e) => transformManager.handleMouseDownOn(e, ResizeBoundary.None)}
        ></div>

        {#each edges as edge (edge)}
          {const rotatedEdge = $derived(rotateBoundary(edges, edge, transformManager.normalizedRotation / 90))}
          <button
            class={['absolute', edge]}
            style={`${edge}: -10px`}
            onmousedown={(e) => transformManager.handleMouseDownOn(e, edge)}
            type="button"
            aria-label={$t('editor_handle_edge', { values: { edge: rotatedEdge } })}
          ></button>
        {/each}

        {#each corners as corner (corner)}
          {const rotatedCorner = $derived(rotateBoundary(corners, corner, transformManager.normalizedRotation / 90))}
          <button
            class={['corner', corner]}
            onmousedown={(e) => transformManager.handleMouseDownOn(e, corner)}
            type="button"
            aria-label={$t('editor_handle_corner', { values: { corner: rotatedCorner.replace('-', '_') } })}
          >
            <Icon icon={cornerIcon} size="30" strokeWidth={4} strokeColor="white" color="transparent" />
          </button>
        {/each}
      </div>
    {/if}
  </div>
</div>

<style>
  .crop-frame.transition {
    transition: all 0.15s ease;
  }

  .grid {
    --color: white;
    --shadow: #00000057;
    background-image:
      linear-gradient(var(--color) 1px, transparent 0), linear-gradient(90deg, var(--color) 1px, transparent 0),
      linear-gradient(var(--shadow) 3px, transparent 0), linear-gradient(90deg, var(--shadow) 3px, transparent 0);
    background-size: calc(100% / 3) calc(100% / 3);
  }

  .left,
  .right {
    top: 0;
    width: 20px;
    height: 100%;
    cursor: ew-resize;
  }

  .top,
  .bottom {
    width: 100%;
    height: 20px;
    cursor: ns-resize;
  }

  .corner {
    position: absolute;
    --offset: -15px;
  }

  .top-left {
    top: var(--offset);
    left: var(--offset);
    cursor: nwse-resize;
  }

  .top-right {
    top: var(--offset);
    right: var(--offset);
    cursor: nesw-resize;
    rotate: 90deg;
  }

  .bottom-right {
    bottom: var(--offset);
    right: var(--offset);
    cursor: nwse-resize;
    rotate: 180deg;
  }

  .bottom-left {
    bottom: var(--offset);
    left: var(--offset);
    cursor: nesw-resize;
    rotate: 270deg;
  }

  .crop-area.rotated {
    max-width: calc(100vh - 16 * var(--spacing));
    max-height: calc(100vw - 400px - 16 * var(--spacing));

    .left,
    .right {
      cursor: ns-resize;
    }
    .top,
    .bottom {
      cursor: ew-resize;
    }
    .top-left,
    .bottom-right {
      cursor: nesw-resize;
    }
    .top-right,
    .bottom-left {
      cursor: nwse-resize;
    }
  }
</style>
