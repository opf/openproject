import { useCallback } from 'react';
import { BlockNoteSchema } from '@blocknote/core';
import { filterSuggestionItems } from '@blocknote/core/extensions';
import '@blocknote/core/fonts/inter.css';
import { BlockNoteView } from '@blocknote/mantine';
import '@blocknote/mantine/style.css';
import {
  getDefaultReactSlashMenuItems,
  SuggestionMenuController,
  useCreateBlockNote,
} from '@blocknote/react';
import {
  initializeOpBlockNoteExtensions,
  openProjectWorkPackageBlockSpec,
  openProjectWorkPackageInlineSpec,
  getOpenProjectSlashMenuItems,
  OpenProjectFormattingToolbar,
  OpenProjectHashMenu,
} from '../lib';
import './fetchOverride';

const schema = BlockNoteSchema.create().extend({
  blockSpecs: {
    openProjectWorkPackageBlock: openProjectWorkPackageBlockSpec(),
  },
  inlineContentSpecs: {
    openProjectWorkPackageInline: openProjectWorkPackageInlineSpec,
  },
});

initializeOpBlockNoteExtensions({
  baseUrl: import.meta.env.VITE_OPENPROJECT_URL ?? 'http://localhost:3000',
  locale: 'en',
});

type EditorType = typeof schema.BlockNoteEditor;

function buildSlashMenuItems(editor:EditorType) {
  return [
    ...getDefaultReactSlashMenuItems(editor),
    // eslint-disable-next-line @typescript-eslint/no-explicit-any, @typescript-eslint/no-unsafe-argument
    ...getOpenProjectSlashMenuItems(editor as any),
  ];
}

export default function App() {
  const editor = useCreateBlockNote({ schema });

  const getSlashItems = useCallback(
    // eslint-disable-next-line @typescript-eslint/require-await
    async (query:string) => filterSuggestionItems(buildSlashMenuItems(editor), query),
    [editor]
  );

  return (
    <BlockNoteView editor={editor} slashMenu={false} formattingToolbar={false}>
      <OpenProjectFormattingToolbar />

      <SuggestionMenuController
        triggerCharacter="/"
        getItems={getSlashItems}
      />

      <OpenProjectHashMenu />
    </BlockNoteView>
  );
}
