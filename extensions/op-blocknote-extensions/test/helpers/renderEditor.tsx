import { BlockNoteSchema } from '@blocknote/core';
import { BlockNoteView } from '@blocknote/mantine';
import { useCreateBlockNote, SuggestionMenuController, getDefaultReactSlashMenuItems } from '@blocknote/react';
import { filterSuggestionItems } from '@blocknote/core/extensions';
import { useCallback } from 'react';
import { render } from 'vitest-browser-react';
import {
  openProjectWorkPackageBlockSpec,
  openProjectWorkPackageInlineSpec,
  workPackageSlashMenu,
  useHashWpMenu,
} from '../../lib';
import { useInlineWpEvents } from '../../lib/hooks/useInlineWpEvents';
import type { HashMenuItem } from '../../lib';

import '@blocknote/core/fonts/inter.css';
import '@blocknote/mantine/style.css';

const schema = BlockNoteSchema.create().extend({
  blockSpecs: {
    openProjectWorkPackageBlock: openProjectWorkPackageBlockSpec(),
  },
  inlineContentSpecs: {
    openProjectWorkPackageInline: openProjectWorkPackageInlineSpec,
  },
});

function Editor() {
  const editor = useCreateBlockNote({ schema });
  useInlineWpEvents(editor as any);

  const { getHashItems, HashWpMenu } = useHashWpMenu(editor as any);

  const getSlashItems = useCallback(
    async (query: string) =>
      filterSuggestionItems(
        [...getDefaultReactSlashMenuItems(editor), workPackageSlashMenu(editor as any)],
        query
      ),
    [editor]
  );

  return (
    <div style={{ paddingTop: 100, height: 500 }}>
    <BlockNoteView editor={editor} slashMenu={false}>
      <SuggestionMenuController triggerCharacter="/" getItems={getSlashItems} />
      <SuggestionMenuController
        triggerCharacter="#"
        getItems={getHashItems}
        suggestionMenuComponent={HashWpMenu}
      />
    </BlockNoteView>
    </div>
  );
}

export function renderEditor() {
  return render(<Editor />);
}