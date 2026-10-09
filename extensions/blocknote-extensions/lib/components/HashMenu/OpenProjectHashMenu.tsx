import { SuggestionMenuController, useBlockNoteEditor } from '@blocknote/react';
import { HASH_TRIGGER } from './hashTrigger';
import { useHashWpMenu } from './useHashWpMenu';

export const OpenProjectHashMenu = () => {
  const editor = useBlockNoteEditor();
  const { getHashItems, HashWpMenu, shouldOpenHashMenu } = useHashWpMenu(editor);

  return (
    <SuggestionMenuController
      triggerCharacter={HASH_TRIGGER}
      getItems={getHashItems}
      shouldOpen={shouldOpenHashMenu}
      suggestionMenuComponent={HashWpMenu}
    />
  );
};
