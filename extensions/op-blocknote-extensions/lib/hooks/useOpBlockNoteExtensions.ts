import type { BlockNoteEditor } from '@blocknote/core';
import { useInlineWpEvents } from './useInlineWpEvents';

/**
 * Wires up the runtime hooks that BlockNote integration needs *after* the
 * editor is mounted.
 *
 * Use {@link PasteDeduplicateInstanceIdsExtension} in your editor's
 * `extensions: [...]` array instead of calling `useDeduplicateInstanceIds`
 * from here. Registering ProseMirror plugins post-mount via
 * `editor.registerPlugin(...)` triggers ProseMirror's `reconfigure()` and
 * destroys the y-prosemirror UndoManager, breaking Ctrl+Z.
 */
export function useOpBlockNoteExtensions(
  editor: BlockNoteEditor<any, any, any>
): void {
  useInlineWpEvents(editor);
}
