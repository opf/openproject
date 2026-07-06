import { createExtension } from '@blocknote/core';
import { PasteWorkPackageLinkExtension } from './pasteWorkPackageLinkExtension';

/**
 * Parent connector extension bundling all OpenProject BlockNote extensions.
 *
 * Host applications register this single extension via
 * `editorOptions.extensions: [OpenProjectExtension]` and receive every
 * bundled OpenProject ProseMirror plugin without per-feature wiring.
 */
export const OpenProjectExtension = createExtension({
  key: 'openProject',
  blockNoteExtensions: [
    PasteWorkPackageLinkExtension,
  ],
});
