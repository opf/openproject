import { useState } from 'react';
import type { BlockNoteEditor } from '@blocknote/core';
import { isPendingWpid } from '../../utils/pending';
import { BLOCK_WP_ATTRIBUTE_TYPE, INLINE_WP_ATTRIBUTE_TYPE } from '../../utils/nodeTypes';
import { findInlineChipAtDOM, removeInlineChipAt, selectInlineChipAtDOM } from '../../utils/inlineChipActions';
import { useColors } from '../../services/colors';
import { useIsNodeInSelection } from '../../hooks/useIsNodeInSelection';
import type { AttributeDisplay } from './display';
import { useWorkPackageAttribute } from './useWorkPackageAttribute';
import { pendingAttributes } from './pending';
import { lastChoice, rememberChoice } from './lastChoice';
import { InsertAttributeModal } from './InsertAttributeModal';
import { AttributeOptionsPopover } from './AttributeOptionsPopover';
import { AttributeInline } from './atoms';
import { attributeTitle, WorkPackageAttributeView } from './WorkPackageAttributeView';
import { useAttributeOptions } from './useAttributeOptions';
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
  const { elementRef, options, active, pick, toggleProps } = useAttributeOptions({
    editor,
    display,
    onDisplayChange,
    onActivate: () => selectAttributeNode(),
  });

  const inSelection = useIsNodeInSelection(elementRef, editor);

  function selectAttributeNode() {
    if (editor && elementRef.current) selectInlineChipAtDOM(editor, elementRef.current, INLINE_WP_ATTRIBUTE_TYPE);
  }

  function removeAttributeNode() {
    if (!editor || !elementRef.current) return;
    const node = findInlineChipAtDOM(editor, elementRef.current, INLINE_WP_ATTRIBUTE_TYPE);
    if (node) removeInlineChipAt(editor, node.position, INLINE_WP_ATTRIBUTE_TYPE);
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
      aria-expanded={options.isOpen}
      $selected={options.isOpen || inSelection}
      data-drag-handle
      {...toggleProps}
    >
      <WorkPackageAttributeView resolved={resolved} display={display} reference={attribute} />
      {options.isOpen && (
        <AttributeOptionsPopover
          resolved={resolved}
          displayId={displayId}
          reference={attribute}
          active={active}
          // eslint-disable-next-line react-hooks/refs
          anchorEl={elementRef.current}
          autoFocus={options.takesFocus}
          onClose={options.close}
          onRestoreFocus={() => editor?.focus()}
          onPick={pick}
          onRemove={removeAttributeNode}
        />
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
