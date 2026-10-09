import { useEffect, useRef, useState } from 'react';
import { useWorkPackage } from '../../hooks/useWorkPackage';
import { useWorkPackagePreview } from '../../hooks/useWorkPackagePreview';
import { useColors } from '../../services/colors';
import { ChipBase, InlineChip } from './chipLayouts';
import { WorkPackageId } from '../WorkPackage/atoms';
import { WpChipXXS, WpChipXS, WpChipS } from './InlineChips';
import { UnavailableChip } from './UnavailableChip';
import { WorkPackageSearchPopover } from '../Search/WorkPackageSearchPopover';
import { CreateWorkPackageModal } from '../CreateWorkPackage';
import { WpOptionsPopover } from '../WorkPackage/OptionsPopover';
import { WpPreviewPopover } from '../WorkPackage/PreviewPopover';
import { getPendingCallbacks, clearInlineWpCallbacks } from './callbacks';
import type { InlineWpSize } from '../WorkPackage/types';
import type { WorkPackage } from '../../openProjectTypes';
import { promoteInlineChipToBlockAt } from '../../utils/inlineChipActions';
import { INLINE_WP_TYPE } from '../../utils/nodeTypes';
import { BlockCard } from '../BlockWorkPackage/BlockCard';
import { useTranslation } from 'react-i18next';
import { formatWorkPackageId } from '../../utils/id';
import { useIsNodeInSelection } from '../../hooks/useIsNodeInSelection';
import { useSuppressFormattingToolbar } from '../../hooks/useSuppressFormattingToolbar';
import { useInlineNodeOptions } from '../../hooks/useInlineNodeOptions';
import { usePressOutside } from '../../hooks/usePressOutside';
import type { BlockNoteEditor } from '@blocknote/core';

export interface InlineWorkPackageChipProps {
  inlineContent:{ props:{ wpid:string; size:string; displayId:string } };
  contentRef:(node:HTMLElement | null) => void;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  editor?:BlockNoteEditor<any, any, any>;
  // Provided by BlockNote's node view; updates exactly this node instance.
  updateInlineContent?:(update:{
    type:typeof INLINE_WP_TYPE;
    props:{ wpid:string; size:string; displayId:string };
  }) => void;
}

export const InlineWorkPackageChip = ({ inlineContent, contentRef, editor, updateInlineContent }:InlineWorkPackageChipProps) => {
  const { t } = useTranslation();
  const rawWpid = inlineContent.props.wpid;
  const displayId = inlineContent.props.displayId || rawWpid;
  const size = (inlineContent.props.size ?? 's') as InlineWpSize;

  const pendingCallbacks = getPendingCallbacks(rawWpid);
  const wpid = pendingCallbacks === undefined && rawWpid ? Number(rawWpid) : undefined;

  useColors();

  const { workPackage: wp, loading, unauthorized, error } = useWorkPackage(wpid);

  useEffect(() => {
    if (!wp || !updateInlineContent) return;
    if (wp.displayId === inlineContent.props.displayId) return;
    updateInlineContent({ type: INLINE_WP_TYPE, props: { ...inlineContent.props, displayId: wp.displayId } });
  }, [wp?.displayId]); // eslint-disable-line react-hooks/exhaustive-deps

  const chipRef = useRef<HTMLElement | null>(null);
  const [chipEl, setChipEl] = useState<HTMLElement | null>(null);

  const { optionsOpen, closeOptions, activationProps, findNode, removeNode } =
    useInlineNodeOptions(editor, chipRef, INLINE_WP_TYPE);

  const preview = useWorkPackagePreview({
    enabled: size === 'xxs',
    suppressed: optionsOpen,
    // The indicator shows the preview instead of the options menu, not over it.
    onOpen: closeOptions,
  });
  const { previewOpen, closePreview, triggerProps, cardProps } = preview;

  const isEditorSelected = useIsNodeInSelection(chipRef, editor);

  useSuppressFormattingToolbar(editor, previewOpen);
  usePressOutside(chipRef, previewOpen, closePreview);

  const setRef = (node:HTMLElement | null) => {
    chipRef.current = node;
    if (pendingCallbacks || node === null) setChipEl(node);
    contentRef(node);
  };

  const onChipActivation = activationProps(closePreview);

  const optionsPopover = (
    <WpOptionsPopover
      wp={wp ?? undefined}
      displayId={displayId}
      currentSize={size}
      // eslint-disable-next-line react-hooks/refs
      anchorEl={chipRef.current}
      onClose={closeOptions}
      onResize={(newSize) => {
        updateInlineContent?.({ type: INLINE_WP_TYPE, props: { ...inlineContent.props, size: newSize } });
      }}
      onConvertToBlock={(blockSize) => {
        const chip = findNode();
        if (editor && chip) promoteInlineChipToBlockAt(editor, chip.position, blockSize);
      }}
      onRemove={removeNode}
    />
  );

  if (pendingCallbacks) {
    const resolvePending = (resolvedWp:WorkPackage) => {
      pendingCallbacks.onSelect(resolvedWp.id, resolvedWp.displayId);
      clearInlineWpCallbacks(rawWpid);
    };
    const cancelPending = () => {
      pendingCallbacks.onCancel();
      clearInlineWpCallbacks(rawWpid);
    };

    const pendingPopover = pendingCallbacks.mode === 'create'
      ? (
        <CreateWorkPackageModal
          anchorEl={chipEl}
          onCreated={resolvePending}
          onCancel={cancelPending}
        />
      )
      : (
        <WorkPackageSearchPopover
          anchorEl={chipEl}
          onSelect={resolvePending}
          onCancel={cancelPending}
        />
      );

    return (
      <InlineChip ref={setRef}>
        {chipEl && pendingPopover}
      </InlineChip>
    );
  }

  // Loading
  if (wpid && loading) {
    return (
      <InlineChip ref={setRef} selected={isEditorSelected} data-drag-handle>
        <ChipBase>
          <WorkPackageId as="span" $compact>#{wpid}…</WorkPackageId>
        </ChipBase>
      </InlineChip>
    );
  }

  // Resolved
  if (wpid && wp) {
    // Hidden while the options menu is open so the two popovers never stack.
    const showPreview = size === 'xxs' && previewOpen && !optionsOpen;
    const chipLabel = t('options.chipAriaLabel', { id: formatWorkPackageId(wp.displayId) });
    const hasIndicator = preview.indicatorProps !== undefined;

    return (
      <InlineChip
        data-drag-handle
        role={hasIndicator ? undefined : 'button'}
        aria-label={hasIndicator ? undefined : chipLabel}
        ref={setRef}
        selected={optionsOpen || isEditorSelected}
        {...triggerProps}
        {...onChipActivation}
      >
        {size === 'xxs' && <WpChipXXS wp={wp} preview={preview} actionLabel={chipLabel} />}
        {size === 'xs' && <WpChipXS wp={wp} />}
        {size === 's' && <WpChipS wp={wp} />}

        {showPreview && (
          <WpPreviewPopover
            // eslint-disable-next-line react-hooks/refs
            anchorEl={chipRef.current}
            {...cardProps}
          >
            <BlockCard workPackage={wp} size="m" linkTitle />
          </WpPreviewPopover>
        )}

        {optionsOpen && optionsPopover}
      </InlineChip>
    );
  }

  // Unavailable: the work package exists but this user cannot see it, or the fetch failed
  if (wpid && (unauthorized || error)) {
    return (
      <UnavailableChip
        kind={unauthorized ? 'unauthorized' : 'error'}
        size={size}
        displayId={displayId}
        setRef={setRef}
        // eslint-disable-next-line react-hooks/refs
        anchorEl={chipRef.current}
        selected={optionsOpen || isEditorSelected}
        preview={preview}
        onActivation={onChipActivation}
        optionsPopover={optionsOpen && optionsPopover}
      />
    );
  }

  // Unknown / transitional
  if (wpid) {
    return (
      <InlineChip ref={setRef} data-drag-handle selected={isEditorSelected} style={{ opacity: 0.6 }}>
        <ChipBase>
          <WorkPackageId as="span" $compact>#{wpid}</WorkPackageId>
        </ChipBase>
      </InlineChip>
    );
  }

  return <InlineChip ref={setRef} />;
};
