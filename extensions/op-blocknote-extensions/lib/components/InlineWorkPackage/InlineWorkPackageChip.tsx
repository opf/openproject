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
import { useIsNodeInSelection } from '../../hooks/useIsNodeInSelection';
import { useSuppressFormattingToolbar } from '../../hooks/useSuppressFormattingToolbar';
import { useOptionsMenu } from '../../hooks/useOptionsMenu';
import { useSelectionAnnouncement } from '../../hooks/useSelectionAnnouncement';
import { useTapActivation } from '../../utils/tapActivation';
import { useOptionsHost } from '../../utils/optionsHost';
import { isKeyboardClick, menuButtonProps } from '../../utils/a11y';
import { describeLinkedWorkPackage, unavailableKindOf, workPackageLabel } from '../WorkPackage/description';
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

  const options = useOptionsMenu();
  const chipRef = useRef<HTMLElement | null>(null);
  const [chipEl, setChipEl] = useState<HTMLElement | null>(null);

  const preview = useWorkPackagePreview({
    enabled: size === 'xxs',
    suppressed: options.isOpen,
    // The indicator shows the preview instead of the options menu, not over it.
    onOpen: options.close,
  });
  const { previewOpen, closePreview, triggerProps, cardProps } = preview;

  const isEditorSelected = useIsNodeInSelection(chipRef, editor);

  useSuppressFormattingToolbar(editor, options.isOpen || previewOpen);

  const unavailableKind = unavailableKindOf({ unauthorized, error });
  const hasOptions = Boolean(wpid && (wp ?? unavailableKind));

  const optionsHostRef = useOptionsHost(() => {
    if (!hasOptions) return;
    closePreview();
    options.open(true);
  });

  useSelectionAnnouncement(chipRef, editor, describeLinkedWorkPackage(t, displayId, wp, unavailableKind));

  const setRef = (node:HTMLElement | null) => {
    chipRef.current = node;
    if (pendingCallbacks || node === null) setChipEl(node);
    optionsHostRef(node);
    contentRef(node);
  };

  const selectWorkPackageNode = () => {
    if (!editor || !chipRef.current) return;
    const chip = findInlineChipAtDOM(editor, chipRef.current);
    if (chip) selectInlineChipAt(editor, chip.position);
    editor.getExtension('formattingToolbar')?.store?.setState(false);
  };

  const toggleOptions = (takesFocus:boolean) => {
    closePreview();
    options.toggle(takesFocus);
    selectWorkPackageNode();
  };

  const tapProps = useTapActivation();
  // The closure is handed to the element, not run while rendering.
  // eslint-disable-next-line react-hooks/refs
  const onChipActivation = tapProps((event) => {
    event?.preventDefault();
    event?.stopPropagation();
    toggleOptions(isKeyboardClick(event));
  });

  // Close the options popover and the preview when the user taps outside the chip
  const { isOpen: isOptionsOpen, close: closeOptions } = options;
  useEffect(() => {
    if (!isOptionsOpen && !previewOpen) return;
    const onPressOutside = (e:Event) => {
      if (chipRef.current && !chipRef.current.contains(e.target as Node)) {
        closeOptions();
        closePreview();
      }
    };
    // Touch as well: a tap another element answers never becomes a mousedown.
    document.addEventListener('mousedown', onPressOutside);
    document.addEventListener('touchstart', onPressOutside);
    return () => {
      document.removeEventListener('mousedown', onPressOutside);
      document.removeEventListener('touchstart', onPressOutside);
    };
  }, [isOptionsOpen, previewOpen, closeOptions, closePreview]);

  const optionsPopover = (
    <WpOptionsPopover
      wp={wp ?? undefined}
      displayId={displayId}
      currentSize={size}
      // eslint-disable-next-line react-hooks/refs
      anchorEl={chipRef.current}
      autoFocus={options.takesFocus}
      onClose={options.close}
      onRestoreFocus={() => editor?.focus()}
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
    const showPreview = size === 'xxs' && previewOpen && !options.isOpen;
    const menuButton = menuButtonProps(workPackageLabel(t, wp.displayId), options.isOpen);

    return (
      <InlineChip
        data-drag-handle
        ref={setRef}
        selected={options.isOpen || isEditorSelected}
        {...triggerProps}
        {...onChipActivation}
      >
        {size === 'xxs' && <WpChipXXS wp={wp} preview={preview} menuButton={menuButton} />}
        {size === 'xs' && <WpChipXS wp={wp} menuButton={menuButton} />}
        {size === 's' && <WpChipS wp={wp} menuButton={menuButton} />}

        {showPreview && (
          <WpPreviewPopover
            // eslint-disable-next-line react-hooks/refs
            anchorEl={chipRef.current}
            {...cardProps}
          >
            <BlockCard workPackage={wp} size="m" linkTitle />
          </WpPreviewPopover>
        )}

        {options.isOpen && optionsPopover}
      </InlineChip>
    );
  }

  // Unavailable: the work package exists but this user cannot see it, or the fetch failed
  if (wpid && unavailableKind) {
    return (
      <UnavailableChip
        kind={unavailableKind}
        size={size}
        displayId={displayId}
        setRef={setRef}
        // eslint-disable-next-line react-hooks/refs
        anchorEl={chipRef.current}
        selected={options.isOpen || isEditorSelected}
        optionsOpen={options.isOpen}
        preview={preview}
        onActivation={onChipActivation}
        optionsPopover={options.isOpen && optionsPopover}
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
