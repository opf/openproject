import { createExtension } from '@blocknote/core';
import type { BlockNoteEditor } from '@blocknote/core';
import { pasteWorkPackageLinkPlugin } from './pasteWorkPackageLinkPlugin';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyEditor = BlockNoteEditor<any, any, any>;

/**
 * BlockNote extension that registers the pasteWorkPackageLinkPlugin at editor
 * construction time.
 *
 * Register it in `editorOptions.extensions: [...]` — directly or via the
 * OpenProjectExtension connector. ProseMirror plugins must be supplied at
 * editor construction time, not registered after the editor is mounted.
 */
export const PasteWorkPackageLinkExtension = createExtension(({ editor }:{ editor:AnyEditor }) => ({
  key: 'pasteWorkPackageLink',
  prosemirrorPlugins: [pasteWorkPackageLinkPlugin(editor)],
}))();
