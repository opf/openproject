import { useCallback } from "react";

export const useDragSelection = (editor: any) => {
  return useCallback(() => {
    if (!editor) return;

    const view = editor._tiptapEditor?.view;
    if (!view) return;

    const { state } = view;
    const { from, to } = state.selection;

    if (from !== to) {
      const slice = state.selection.content();
      
      view.dragging = {
        slice,
        move: true,
      };
    }
  }, [editor]);
};