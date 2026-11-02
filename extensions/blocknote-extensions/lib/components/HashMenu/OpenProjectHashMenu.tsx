import { SuggestionMenuController, useBlockNoteEditor } from '@blocknote/react';
import { canOpenHashMenu } from './hashTrigger';
import { useHashWpMenu } from './useHashWpMenu';

const HASH_TRIGGER_CHARACTER = '#';

export const OpenProjectHashMenu = () => {
  const editor = useBlockNoteEditor();
  const { getHashItems, HashWpMenu } = useHashWpMenu(editor);

  return (
    <SuggestionMenuController
      triggerCharacter={HASH_TRIGGER_CHARACTER}
      getItems={getHashItems}
      shouldOpen={canOpenHashMenu}
      suggestionMenuComponent={HashWpMenu}
    />
  );
};
