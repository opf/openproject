import { useState } from 'react';
import type { BlockNoteEditor } from '@blocknote/core';
import { PENDING_PREFIX } from '../InlineWorkPackage/callbacks';
import { BLOCK_ATTRIBUTE_TYPE } from '../../utils/nodeTypes';
import { useColors } from '../../services/colors';
import type { AttributeDisplay } from './externalHtml';
import { useWorkPackageAttribute } from './useWorkPackageAttribute';
import { getPendingAttribute } from './pending';
import { lastAttributeChoice, rememberAttributeChoice } from './lastChoice';
import { InsertAttributeModal } from './InsertAttributeModal';
import { AttributeDisplayMenu } from './AttributeDisplayMenu';
import { AttributeChip } from './atoms';
import { attributeTitle, WorkPackageAttributeView } from './WorkPackageAttributeView';
import { useAttributeDisplayMenu } from './useAttributeDisplayMenu';
import type { AttributeProps } from './types';

interface WorkPackageAttributeChipProps {
  content:AttributeProps;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  editor?:BlockNoteEditor<any, any, any>;
  contentRef?:(node:HTMLElement | null) => void;
  onDisplayChange?:(display:AttributeDisplay) => void;
}

function ResolvedAttributeChip({ content, editor, contentRef, onDisplayChange }:WorkPackageAttributeChipProps) {
  const { wpid, displayId, attribute, display } = content;
  const resolved = useWorkPackageAttribute(wpid, attribute);
  useColors();
  const { elementRef, menuOpen, active, pick, toggleProps } = useAttributeDisplayMenu({ editor, display, onDisplayChange });

  return (
    <AttributeChip
      ref={(node:HTMLElement | null) => {
        elementRef.current = node;
        contentRef?.(node);
      }}
      title={attributeTitle(resolved, displayId)}
      role="button"
      aria-haspopup="menu"
      aria-expanded={menuOpen}
      $selected={menuOpen}
      data-drag-handle
      {...toggleProps}
    >
      <WorkPackageAttributeView resolved={resolved} display={display} reference={attribute} />
      {menuOpen && (
        // eslint-disable-next-line react-hooks/refs
        <AttributeDisplayMenu anchorEl={elementRef.current} active={active} onPick={pick} />
      )}
    </AttributeChip>
  );
}

export function WorkPackageAttributeChip({ content, editor, contentRef, onDisplayChange }:WorkPackageAttributeChipProps) {
  const [anchorEl, setAnchorEl] = useState<HTMLElement | null>(null);
  const pending = getPendingAttribute(content.wpid);

  if (pending) {
    return (
      <AttributeChip
        ref={(node:HTMLElement | null) => {
          setAnchorEl(node);
          contentRef?.(node);
        }}
      >
        {anchorEl && (
          <InsertAttributeModal
            anchorEl={anchorEl}
            prefill={lastAttributeChoice()}
            offersLongText={BLOCK_ATTRIBUTE_TYPE in ((editor?.schema.blockSchema ?? {}) as Record<string, unknown>)}
            onInsert={(choice, kind) => {
              rememberAttributeChoice(choice);
              pending.onInsert(choice, kind);
            }}
            onCancel={pending.onCancel}
          />
        )}
      </AttributeChip>
    );
  }

  // Another collaborator's dialog is still open on it.
  if (content.wpid.startsWith(PENDING_PREFIX)) return <span ref={contentRef} />;

  return <ResolvedAttributeChip content={content} editor={editor} contentRef={contentRef} onDisplayChange={onDisplayChange} />;
}
