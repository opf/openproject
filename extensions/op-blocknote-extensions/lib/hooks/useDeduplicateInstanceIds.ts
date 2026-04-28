import { useEffect } from "react";
import type { BlockNoteEditor } from "@blocknote/core";
import {
  pasteDeduplicatePlugin,
  pasteDeduplicatePluginKey,
} from "../plugins/pasteDeduplicatePlugin";

export function useDeduplicateInstanceIds(
  editor: BlockNoteEditor<any, any, any>
): void {
  useEffect(() => {
    // accessing private tiptap instance until public API is available
    const tiptap = (editor as any)._tiptapEditor;
    if (!tiptap) return;

    tiptap.registerPlugin(pasteDeduplicatePlugin);

    return () => {
      tiptap.unregisterPlugin(pasteDeduplicatePluginKey);
    };
  }, [editor]);
}