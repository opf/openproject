import { useEffect, useState } from "react";
import type { RefObject } from "react";
import { isNodeInSelection } from "../utils/selection";

interface SelectionSource {
  onSelectionChange: (callback: () => void) => () => void;
}

// Tracks whether `nodeRef` is part of the current editor selection. Shadow-DOM safe. 
export function useIsNodeInSelection(
  nodeRef: RefObject<HTMLElement | null>,
  editor: SelectionSource | undefined,
): boolean {
  const [inSelection, setInSelection] = useState(false);

  useEffect(() => {
    if (!editor) return;

    return editor.onSelectionChange(() => {
      const node = nodeRef.current;
      if (!node) {
        setInSelection(false);
        return;
      }
      setInSelection(isNodeInSelection(node));
    });
  }, [editor, nodeRef]);

  return inSelection;
}