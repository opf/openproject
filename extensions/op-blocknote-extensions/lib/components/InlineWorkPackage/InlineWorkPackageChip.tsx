import { useEffect, useRef, useState } from 'react';
import styled, { css } from 'styled-components';
import { useWorkPackage } from '../../hooks/useWorkPackage';
import { useColors } from '../../services/colors';
import { CHIP_STYLES } from '../WorkPackage/tokens';
import { ChipBase } from './chipLayouts';
import { WorkPackageId } from '../WorkPackage/atoms';
import { WpChipXXS, WpChipXS, WpChipS } from './InlineChips';
import { WorkPackageSearchPopover } from '../Search/WorkPackageSearchPopover';
import { WpOptionsPopover } from '../WorkPackage/OptionsPopover';
import { getPendingCallbacks, clearInlineWpCallbacks } from './callbacks';
import type { InlineWpSize } from '../WorkPackage/types';
import {
  findInlineChipAtDOM,
  selectInlineChipAt,
  removeInlineChipAt,
  promoteInlineChipToBlockAt,
} from '../../utils/inlineChipActions';
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

const InlineChip = styled.span.attrs({
  className: 'op-bn-inline-wp',
  contentEditable: false,
})<{ selected?:boolean }>`
  ${defaultWpVariables}
  display: inline;
  cursor: pointer;
  user-select: none;
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

  const { workPackage: wp, loading } = useWorkPackage(wpid);

  useEffect(() => {
    if (!wp || !updateInlineContent) return;
    if (wp.displayId === inlineContent.props.displayId) return;
    updateInlineContent({ type: 'openProjectWorkPackageInline', props: { ...inlineContent.props, displayId: wp.displayId } });
  }, [wp?.displayId]); // eslint-disable-line react-hooks/exhaustive-deps

  const [isSelected, setIsSelected] = useState(false);
  const chipRef = useRef<HTMLElement | null>(null);

  const isEditorSelected = useIsNodeInSelection(chipRef, editor);

  const setRef = (node:HTMLElement | null) => {
    chipRef.current = node;
    contentRef(node);
  };

  // Close the options popover when the user clicks outside the chip
  useEffect(() => {
    if (!isSelected) return;
    const onClickOutside = (e:MouseEvent) => {
      if (chipRef.current && !chipRef.current.contains(e.target as Node)) {
        setIsSelected(false);
      }
    };
    document.addEventListener('mousedown', onClickOutside);
    return () => document.removeEventListener('mousedown', onClickOutside);
  }, [isSelected]);

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
    return (
      <InlineChip
        data-drag-handle
        role="button"
        aria-label={t('options.chipAriaLabel', { id: formatWorkPackageId(wp.displayId) })}
        ref={setRef}
        selected={isSelected || isEditorSelected}
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
          setIsSelected((prev) => !prev);
          if (editor && chipRef.current) {
            const chip = findInlineChipAtDOM(editor, chipRef.current);
            if (chip) selectInlineChipAt(editor, chip.position);
            editor.getExtension('formattingToolbar')?.store?.setState(false);
          }
        }}
      >
        {size === 'xxs' && <WpChipXXS wp={wp} />}
        {size === 'xs' && <WpChipXS wp={wp} />}
        {size === 's' && <WpChipS wp={wp} />}

        {isSelected && (
          <WpOptionsPopover
            wp={wp}
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
        )}
      </InlineChip>
    );
  }

  // Error / unknown
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
