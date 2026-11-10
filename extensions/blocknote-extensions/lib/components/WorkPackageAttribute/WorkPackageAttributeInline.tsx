import { useState } from 'react';
import type { BlockNoteEditor } from '@blocknote/core';
import { isPendingWpid } from '../../utils/pending';
import { BLOCK_WP_ATTRIBUTE_TYPE, INLINE_WP_ATTRIBUTE_TYPE } from '../../utils/nodeTypes';
import { selectInlineChipAtDOM } from '../../utils/inlineChipActions';
import { useColors } from '../../services/colors';
import { useIsNodeInSelection } from '../../hooks/useIsNodeInSelection';
import type { AttributeDisplay } from './display';
import { useWorkPackageAttribute } from './useWorkPackageAttribute';
import { pendingAttributes } from './pending';
import { lastChoice, rememberChoice } from './lastChoice';
import { InsertAttributeModal } from './InsertAttributeModal';
import { AttributeDisplayMenu } from './AttributeDisplayMenu';
import { AttributeInline } from './atoms';
import { attributeTitle, WorkPackageAttributeView } from './WorkPackageAttributeView';
import { useAttributeDisplayMenu } from './useAttributeDisplayMenu';
import type { AttributeProps } from './types';

interface WorkPackageAttributeInlineProps {
  content:AttributeProps;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  editor?:BlockNoteEditor<any, any, any>;
  contentRef?:(node:HTMLElement | null) => void;
  onDisplayChange?:(display:AttributeDisplay) => void;
}

function ResolvedAttributeInline({ content, editor, contentRef, onDisplayChange }:WorkPackageAttributeInlineProps) {
  const { wpid, displayId, attribute, display } = content;
  const resolved = useWorkPackageAttribute(wpid, attribute);
  useColors();
  const { elementRef, menuOpen, active, pick, toggleProps } = useAttributeDisplayMenu({
    editor,
    display,
    onDisplayChange,
    onActivate: () => selectAttributeNode(),
  });

  const inSelection = useIsNodeInSelection(elementRef, editor);

  function selectAttributeNode() {
    if (editor && elementRef.current) selectInlineChipAtDOM(editor, elementRef.current, INLINE_WP_ATTRIBUTE_TYPE);
  }

  return (
    <AttributeInline
      ref={(node:HTMLElement | null) => {
        elementRef.current = node;
        contentRef?.(node);
      }}
      title={attributeTitle(resolved, displayId)}
      role="button"
      aria-haspopup="menu"
      aria-expanded={menuOpen}
      $selected={menuOpen || inSelection}
      data-drag-handle
      {...toggleProps}
    >
      <WorkPackageAttributeView resolved={resolved} display={display} reference={attribute} />
      {menuOpen && (
        // eslint-disable-next-line react-hooks/refs
        <AttributeDisplayMenu anchorEl={elementRef.current} active={active} onPick={pick} />
      )}
    </AttributeInline>
  );
}

export function WorkPackageAttributeInline({ content, editor, contentRef, onDisplayChange }:WorkPackageAttributeInlineProps) {
  const [anchorEl, setAnchorEl] = useState<HTMLElement | null>(null);
  const pending = pendingAttributes.get(content.wpid);

  if (pending) {
    return (
      <AttributeInline
        ref={(node:HTMLElement | null) => {
          setAnchorEl(node);
          contentRef?.(node);
        }}
      >
        {anchorEl && (
          <InsertAttributeModal
            anchorEl={anchorEl}
            prefill={lastChoice()}
            offersLongText={BLOCK_WP_ATTRIBUTE_TYPE in ((editor?.schema.blockSchema ?? {}) as Record<string, unknown>)}
            onInsert={(choice, kind) => {
              rememberChoice(choice);
              pending.onResolve({ choice, kind });
            }}
            onCancel={pending.onCancel}
          />
        )}
      </AttributeInline>
    );
  }

  // Another collaborator's dialog is still open on it.
  if (isPendingWpid(content.wpid)) return <span ref={contentRef} />;

  return <ResolvedAttributeInline content={content} editor={editor} contentRef={contentRef} onDisplayChange={onDisplayChange} />;
}
