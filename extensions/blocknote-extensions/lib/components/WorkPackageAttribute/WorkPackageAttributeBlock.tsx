import { useState } from 'react';
import type { BlockNoteEditor } from '@blocknote/core';
import { useSelectedBlocks } from '@blocknote/react';
import { selectBlockNode } from '../../utils/selection';
import { blockDragProps } from '../../utils/blockDrag';
import type { AttributeDisplay } from './display';
import { useWorkPackageAttribute } from './useWorkPackageAttribute';
import { useAttributeOptions } from './useAttributeOptions';
import { AttributeOptionsPopover } from './AttributeOptionsPopover';
import { AttributeBlockFrame, MenuAnchor } from './atoms';
import { attributeTitle, WorkPackageAttributeBlockView } from './WorkPackageAttributeView';
import type { AttributeProps } from './types';

interface WorkPackageAttributeBlockProps {
  blockId:string;
  content:AttributeProps;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  editor:BlockNoteEditor<any, any, any>;
  onDisplayChange:(display:AttributeDisplay) => void;
}

export function WorkPackageAttributeBlock({ blockId, content, editor, onDisplayChange }:WorkPackageAttributeBlockProps) {
  const { wpid, displayId, attribute, display } = content;
  const resolved = useWorkPackageAttribute(wpid, attribute);
  const { setElementRef, options, active, pick, toggleProps } = useAttributeOptions({
    editor,
    content,
    resolved,
    onDisplayChange,
    onActivate: () => selectBlockNode(editor, blockId),
  });
  const selected = useSelectedBlocks(editor).some((block) => block.id === blockId);
  const [menuAnchor, setMenuAnchor] = useState<HTMLSpanElement | null>(null);

  return (
    <AttributeBlockFrame
      ref={setElementRef}
      title={attributeTitle(resolved, displayId)}
      $selected={selected || options.isOpen}
      {...blockDragProps(editor, blockId)}
      {...toggleProps}
    >
      <MenuAnchor ref={setMenuAnchor} />
      <WorkPackageAttributeBlockView resolved={resolved} display={display} reference={attribute} />
      {options.isOpen && (
        <AttributeOptionsPopover
          resolved={resolved}
          displayId={displayId}
          reference={attribute}
          active={active}
          anchorEl={menuAnchor}
          autoFocus={options.takesFocus}
          onClose={options.close}
          onRestoreFocus={() => editor.focus()}
          onPick={pick}
          onRemove={() => editor.removeBlocks([blockId])}
        />
      )}
    </AttributeBlockFrame>
  );
}
