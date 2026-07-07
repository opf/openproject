import { createExtension } from '@blocknote/core';
import type { BlockNoteEditor } from '@blocknote/core';
import { pasteWorkPackageLinkPlugin } from './pasteWorkPackageLinkPlugin';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyEditor = BlockNoteEditor<any, any, any>;

/**
 * BlockNote extension that registers the pasteWorkPackageLinkPlugin at editor
 * construction time.
 *
 * Bundled with the openProjectWorkPackageBlockSpec (see
 * BlockWorkPackage/spec.tsx), so hosts get it by registering the spec in the
 * schema - no `editorOptions.extensions` entry needed. ProseMirror plugins
 * must be supplied at editor construction time, not registered after the
 * editor is mounted.
 */
export const PasteWorkPackageLinkExtension = createExtension(({ editor }:{ editor:AnyEditor }) => ({
  key: 'pasteWorkPackageLink',
  prosemirrorPlugins: [pasteWorkPackageLinkPlugin(editor)],
}))();
