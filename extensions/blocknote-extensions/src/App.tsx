import { BlockNoteSchema } from '@blocknote/core';
import '@blocknote/core/fonts/inter.css';
import { enablePrimerDialogs, PrimerEditorView } from '../lib/primer';
import './editor.css';
import { useCreateBlockNote } from '@blocknote/react';
import {
  initializeOpBlockNoteExtensions,
  openProjectWorkPackageBlockSpec,
  openProjectWorkPackageInlineSpec,
  openProjectWorkPackageAttributeInlineSpec,
  openProjectWorkPackageAttributeBlockSpec,
} from '../lib';
import './fetchOverride';

const schema = BlockNoteSchema.create().extend({
  blockSpecs: {
    openProjectWorkPackageBlock: openProjectWorkPackageBlockSpec(),
    openProjectWorkPackageAttributeBlock: openProjectWorkPackageAttributeBlockSpec(),
  },
  inlineContentSpecs: {
    openProjectWorkPackageInline: openProjectWorkPackageInlineSpec,
    openProjectWorkPackageAttributeInline: openProjectWorkPackageAttributeInlineSpec,
  },
});

enablePrimerDialogs();
initializeOpBlockNoteExtensions({
  baseUrl: import.meta.env.VITE_OPENPROJECT_URL ?? 'http://localhost:3000',
  locale: 'en',
});

export default function App() {
  const editor = useCreateBlockNote({ schema });
  return <PrimerEditorView editor={editor} />;
}
