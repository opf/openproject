import { useState } from 'react';
import type { BlockNoteEditor } from '@blocknote/core';
import { useSelectedBlocks } from '@blocknote/react';
import { selectBlockNode } from '../../utils/selection';
import { blockDragProps } from '../../utils/blockDrag';
import type { AttributeDisplay } from './externalHtml';
import { useWorkPackageAttribute } from './useWorkPackageAttribute';
import { useAttributeDisplayMenu } from './useAttributeDisplayMenu';
import { AttributeDisplayMenu } from './AttributeDisplayMenu';
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
  const { elementRef, menuOpen, active, pick, toggleProps } = useAttributeDisplayMenu({
    editor,
    display,
    onDisplayChange,
    onActivate: () => selectBlockNode(editor, blockId),
  });
  const selected = useSelectedBlocks(editor).some((block) => block.id === blockId);
  const [menuAnchor, setMenuAnchor] = useState<HTMLSpanElement | null>(null);

  return (
    <AttributeBlockFrame
      ref={(node:HTMLDivElement | null) => { elementRef.current = node; }}
      title={attributeTitle(resolved, displayId)}
      $selected={selected || menuOpen}
      {...blockDragProps(editor, blockId)}
      {...toggleProps}
    >
      <MenuAnchor ref={setMenuAnchor} />
      <WorkPackageAttributeBlockView resolved={resolved} display={display} reference={attribute} />
      {menuOpen && <AttributeDisplayMenu anchorEl={menuAnchor} placement="above" active={active} onPick={pick} />}
    </AttributeBlockFrame>
  );
}
