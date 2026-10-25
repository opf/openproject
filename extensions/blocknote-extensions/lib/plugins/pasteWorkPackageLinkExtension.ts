import { createExtension } from '@blocknote/core';
import type { AnyEditor } from '../editorTypes';
import { pasteWorkPackageLinkPlugin } from './pasteWorkPackageLinkPlugin';

/**
 * Registers pasteWorkPackageLinkPlugin at editor construction time. Bundled
 * into openProjectWorkPackageBlockSpec, so registering that block spec in the
 * schema is enough — no `editorOptions.extensions` wiring needed.
 */
export const PasteWorkPackageLinkExtension = createExtension(({ editor }:{ editor:AnyEditor }) => ({
  key: 'pasteWorkPackageLink',
  prosemirrorPlugins: [pasteWorkPackageLinkPlugin(editor)],
}))();
