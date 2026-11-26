import { useEffect, useState } from 'react';
import type { RefObject } from 'react';
import type { AnyEditor } from '../editorTypes';
import { findInlineChipAtDOM } from '../utils/inlineChipActions';
import { INLINE_WP_TYPE } from '../utils/nodeTypes';

// Reads the editor's selection, not the native one: Safari reports a selection
// inside a shadow root as one on its host, so it never intersects the chip.
export function useIsNodeInSelection(
  nodeRef:RefObject<HTMLElement | null>,
  editor:AnyEditor | undefined,
  type:string = INLINE_WP_TYPE,
):boolean {
  const [inSelection, setInSelection] = useState(false);

  useEffect(() => {
    if (!editor) return;

    return editor.onSelectionChange(() => {
      const node = nodeRef.current;
      const chip = node && findInlineChipAtDOM(editor, node, type);
      if (!chip) {
        setInSelection(false);
        return;
      }
      const { from, to, empty } = editor.prosemirrorState.selection;
      setInSelection(!empty && from <= chip.position && chip.position + chip.node.nodeSize <= to);
    });
  }, [editor, nodeRef, type]);

  return inSelection;
}
