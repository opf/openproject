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
import {
  findInlineChipAtDOM,
  selectInlineChipAt,
  removeInlineChipAt,
  promoteInlineChipToBlockAt,
} from '../../utils/inlineChipActions';
import { BlockCard } from '../BlockWorkPackage/BlockCard';
import { useTranslation } from 'react-i18next';
import { formatWorkPackageId } from '../../utils/id';
import { useIsNodeInSelection } from '../../hooks/useIsNodeInSelection';
import { useSuppressFormattingToolbar } from '../../hooks/useSuppressFormattingToolbar';
import type { BlockNoteEditor } from '@blocknote/core';

export interface InlineWorkPackageChipProps {
  inlineContent:{ props:{ wpid:string; size:string; displayId:string } };
  contentRef:(node:HTMLElement | null) => void;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  editor?:BlockNoteEditor<any, any, any>;
  // Provided by BlockNote's node view; updates exactly this node instance.
  updateInlineContent?:(update:{
    type:'openProjectWorkPackageInline';
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
    updateInlineContent({ type: 'openProjectWorkPackageInline', props: { ...inlineContent.props, displayId: wp.displayId } });
  }, [wp?.displayId]); // eslint-disable-line react-hooks/exhaustive-deps

  const [isSelected, setIsSelected] = useState(false);
  const chipRef = useRef<HTMLElement | null>(null);
  const [chipEl, setChipEl] = useState<HTMLElement | null>(null);

  const preview = useWorkPackagePreview({ enabled: size === 'xxs', suppressed: isSelected });
  const { previewOpen, closePreview, wasLongPress, triggerProps, cardProps } = preview;

  const isEditorSelected = useIsNodeInSelection(chipRef, editor);

  useSuppressFormattingToolbar(editor, isSelected);

  const setRef = (node:HTMLElement | null) => {
    chipRef.current = node;
    if (pendingCallbacks?.mode === 'create' || node === null) setChipEl(node);
    contentRef(node);
  };

  const selectWorkPackageNode = () => {
    if (!editor || !chipRef.current) return;
    const chip = findInlineChipAtDOM(editor, chipRef.current);
    if (chip) selectInlineChipAt(editor, chip.position);
    editor.getExtension('formattingToolbar')?.store?.setState(false);
  };

  const handleWorkPackageClick = (e:React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();

    // A long press already opened the preview; swallow the trailing click.
    if (wasLongPress()) return;
    closePreview();
    setIsSelected((prev) => !prev);
    selectWorkPackageNode();
  };

  // Close the options popover and long-press preview when the user taps outside the chip
  useEffect(() => {
    if (!isSelected && !previewOpen) return;
    const onClickOutside = (e:MouseEvent) => {
      if (chipRef.current && !chipRef.current.contains(e.target as Node)) {
        setIsSelected(false);
        closePreview();
      }
    };
    document.addEventListener('mousedown', onClickOutside);
    return () => document.removeEventListener('mousedown', onClickOutside);
  }, [isSelected, previewOpen, closePreview]);

  const optionsPopover = (
    <WpOptionsPopover
      wp={wp ?? undefined}
      displayId={displayId}
      currentSize={size}
      // eslint-disable-next-line react-hooks/refs
      anchorEl={chipRef.current}
      onClose={() => setIsSelected(false)}
      onResize={(newSize) => {
        updateInlineContent?.({ type: 'openProjectWorkPackageInline', props: { ...inlineContent.props, size: newSize } });
      }}
      onConvertToBlock={(blockSize) => {
        if (!editor || !chipRef.current) return;
        const chip = findInlineChipAtDOM(editor, chipRef.current);
        if (chip) promoteInlineChipToBlockAt(editor, chip.position, blockSize);
      }}
      onRemove={() => {
        if (!editor || !chipRef.current) return;
        const chip = findInlineChipAtDOM(editor, chipRef.current);
        if (chip) removeInlineChipAt(editor, chip.position);
      }}
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

    return (
      <InlineChip ref={setRef}>
        {pendingCallbacks.mode === 'create'
          ? chipEl && (
            <CreateWorkPackageModal
              anchorEl={chipEl}
              onCreated={resolvePending}
              onCancel={cancelPending}
            />
          )
          : (
            <WorkPackageSearchPopover
              onSelect={resolvePending}
              onCancel={cancelPending}
              renderItem={(searchResult) => <BlockCard workPackage={searchResult} inDropdown />}
            />
          )}
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
    const showPreview = size === 'xxs' && previewOpen && !isSelected;

    return (
      <InlineChip
        data-drag-handle
        role="button"
        aria-label={t('options.chipAriaLabel', { id: formatWorkPackageId(wp.displayId) })}
        ref={setRef}
        selected={isSelected || isEditorSelected}
        {...triggerProps}
        onClick={handleWorkPackageClick}
      >
        {size === 'xxs' && <WpChipXXS wp={wp} />}
        {size === 'xs' && <WpChipXS wp={wp} />}
        {size === 's' && <WpChipS wp={wp} />}

        {showPreview && (
          <WpPreviewPopover
            // eslint-disable-next-line react-hooks/refs
            anchorEl={chipRef.current}
            onClose={closePreview}
            {...cardProps}
          >
            <BlockCard workPackage={wp} size="m" linkTitle />
          </WpPreviewPopover>
        )}

        {isSelected && optionsPopover}
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
        selected={isSelected || isEditorSelected}
        preview={preview}
        onClick={handleWorkPackageClick}
        optionsPopover={isSelected && optionsPopover}
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
