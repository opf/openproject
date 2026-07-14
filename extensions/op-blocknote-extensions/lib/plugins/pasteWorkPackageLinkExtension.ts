import { createExtension } from '@blocknote/core';
import type { BlockNoteEditor } from '@blocknote/core';
import { pasteWorkPackageLinkPlugin } from './pasteWorkPackageLinkPlugin';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyEditor = BlockNoteEditor<any, any, any>;

/**
 * Registers pasteWorkPackageLinkPlugin at editor construction time. Bundled
 * into openProjectWorkPackageBlockSpec, so registering that block spec in the
 * schema is enough — no `editorOptions.extensions` wiring needed.
 */
export const PasteWorkPackageLinkExtension = createExtension(({ editor }:{ editor:AnyEditor }) => ({
  key: 'pasteWorkPackageLink',
  prosemirrorPlugins: [pasteWorkPackageLinkPlugin(editor)],
}))();
