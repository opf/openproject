import { createExtension } from '@blocknote/core';
import { pasteDeduplicatePlugin } from './pasteDeduplicatePlugin';

/**
 * BlockNote extension that registers the pasteDeduplicatePlugin at editor
 * construction time.
 *
 * IMPORTANT — register this in `editorOptions.extensions: [...]` rather than
 * calling `editor.registerPlugin(...)` after the editor is mounted. Tiptap's
 * `registerPlugin` calls ProseMirror's `reconfigure()` under the hood, which
 * rebuilds every PluginView — including y-prosemirror's `yUndoPlugin.view`.
 * Its destroy callback calls `Y.UndoManager.destroy()`, removing the
 * `afterTransaction` listener from the Y.Doc. The plugin state is carried
 * over by `reconfigure`, so `init` never re-runs and the listener is never
 * reattached: the editor goes on running, but no edits are ever captured by
 * the UndoManager, and `Ctrl+Z` silently does nothing.
 *
 * Adding the plugin to the editor's initial extension list avoids the
 * `reconfigure` pass entirely.
 */
export const PasteDeduplicateInstanceIdsExtension = createExtension({
  key: 'pasteDeduplicateInstanceIds',
  prosemirrorPlugins: [pasteDeduplicatePlugin],
});
