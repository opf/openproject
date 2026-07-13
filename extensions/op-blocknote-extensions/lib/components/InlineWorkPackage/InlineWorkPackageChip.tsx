import { useEffect, useRef, useState } from 'react';
import styled, { css } from 'styled-components';
import { useWorkPackage } from '../../hooks/useWorkPackage';
import { useWorkPackagePreview } from '../../hooks/useWorkPackagePreview';
import { useColors } from '../../services/colors';
import { CHIP_STYLES } from '../WorkPackage/tokens';
import { ChipBase, ChipBaseXXS } from './chipLayouts';
import { WorkPackageId } from '../WorkPackage/atoms';
import { WpChipXXS, WpChipXS, WpChipS } from './InlineChips';
import { WorkPackageSearchPopover } from '../Search/WorkPackageSearchPopover';
import { WpOptionsPopover } from '../WorkPackage/OptionsPopover';
import { WpPreviewPopover } from '../WorkPackage/PreviewPopover';
import { UnavailableCard } from '../WorkPackage/UnavailableCard';
import { getPendingCallbacks, clearInlineWpCallbacks } from './callbacks';
import type { InlineWpSize } from '../WorkPackage/types';
import {
  findInlineChipAtDOM,
  selectInlineChipAt,
  removeInlineChipAt,
  promoteInlineChipToBlockAt,
} from '../../utils/inlineChipActions';
import { EyeClosedIcon, AlertIcon } from '@primer/octicons-react';
import { BlockCard } from '../BlockWorkPackage/BlockCard';
import { useTranslation } from 'react-i18next';
import { defaultWpVariables } from '../WorkPackage/atoms';
import { formatWorkPackageId } from '../../utils/id';
import { useIsNodeInSelection } from '../../hooks/useIsNodeInSelection';
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

const UnavailableLabel = styled.span`
  color: var(--bn-colors-editor-text);
`;

const InlineChip = styled.span.attrs({
  className: 'op-bn-inline-wp',
  contentEditable: false,
})<{ selected?:boolean }>`
  ${defaultWpVariables}
  display: inline;
  cursor: pointer;
  user-select: none;
  -webkit-touch-callout: none;
  border-radius: ${CHIP_STYLES.radius};
  position: relative;
  line-height: 1;

  &:active {
    cursor: grabbing;
  }

  ${({ selected }) =>
    selected &&
    css`
      & > .op-bn-inline-wp-base {
        box-shadow: ${CHIP_STYLES.inlineFocusShadow};
      }
    `}
`;

export const InlineWorkPackageChip = ({ inlineContent, contentRef, editor, updateInlineContent }:InlineWorkPackageChipProps) => {
  const { t } = useTranslation();
  const rawWpid = inlineContent.props.wpid;
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

  const { previewOpen, closePreview, wasLongPress, triggerProps, cardProps } =
    useWorkPackagePreview({ enabled: size === 'xxs', suppressed: isSelected });

  const isEditorSelected = useIsNodeInSelection(chipRef, editor);

  const setRef = (node:HTMLElement | null) => {
    chipRef.current = node;
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

  // Pending: waiting for user to pick a WP via search
  if (pendingCallbacks) {
    return (
      <InlineChip ref={setRef}>
        <WorkPackageSearchPopover
          onSelect={(selectedWp) => {
            pendingCallbacks.onSelect(selectedWp.id, selectedWp.displayId);
            clearInlineWpCallbacks(rawWpid);
          }}
          onCancel={() => {
            pendingCallbacks.onCancel();
            clearInlineWpCallbacks(rawWpid);
          }}
          renderItem={(wp) => <BlockCard workPackage={wp} inDropdown />}
        />
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

  const unavailableWorkPackage = (kind:'unauthorized' | 'error') => {
    const inlineIcon = kind === 'unauthorized'
      ? <EyeClosedIcon size={12} verticalAlign="middle" />
      : <AlertIcon size={12} verticalAlign="middle" />;
    const cardIcon = kind === 'unauthorized'
      ? <EyeClosedIcon size={16} />
      : <AlertIcon size={16} />;
    const shortLabel = t(`unavailableWorkPackage.${kind}.short_message`);

    // xxs stays tiny (icon only); the full message lives in the hover/long-press preview.
    const iconOnly = size === 'xxs';
    const Base = iconOnly ? ChipBaseXXS : ChipBase;
    const showPreview = iconOnly && previewOpen;

    return (
      <InlineChip
        ref={setRef}
        data-drag-handle
        // icon-only xxs is a labelled state graphic; larger sizes carry visible text
        role={iconOnly ? 'img' : undefined}
        selected={isSelected || isEditorSelected}
        aria-label={iconOnly ? shortLabel : undefined}
        {...triggerProps}
        onClick={handleWorkPackageClick}
      >
        <Base>
          {inlineIcon}
          {!iconOnly && <UnavailableLabel>{shortLabel}</UnavailableLabel>}
        </Base>

        {showPreview && (
          <WpPreviewPopover
            anchorEl={chipRef.current}
            onClose={closePreview}
            {...cardProps}
          >
            <UnavailableCard
              icon={cardIcon}
              header={t(`unavailableWorkPackage.${kind}.header`)}
              message={t(`unavailableWorkPackage.${kind}.message`)}
            />
          </WpPreviewPopover>
        )}

        {isSelected && optionsPopover}
      </InlineChip>
    );
  };

  // eslint-disable-next-line react-hooks/refs
  if (wpid && unauthorized) return unavailableWorkPackage('unauthorized');
  // eslint-disable-next-line react-hooks/refs
  if (wpid && error) return unavailableWorkPackage('error');

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
