import { createExtension } from '@blocknote/core';
import type { AnyEditor } from '../editorTypes';
import { pasteWorkPackageAttributePlugin } from './pasteWorkPackageAttributePlugin';

// Bundled into openProjectWorkPackageAttributeBlockSpec, like PasteWorkPackageLinkExtension.
export const PasteWorkPackageAttributeExtension = createExtension(({ editor }:{ editor:AnyEditor }) => ({
  key: 'pasteWorkPackageAttribute',
  prosemirrorPlugins: [pasteWorkPackageAttributePlugin(editor)],
}))();
