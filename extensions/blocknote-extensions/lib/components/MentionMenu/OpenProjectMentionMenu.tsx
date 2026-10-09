import { SuggestionMenuController, useBlockNoteEditor } from '@blocknote/react';
import { MENTION_TRIGGER } from './mentionTrigger';
import { useMentionMenu } from './useMentionMenu';

export const OpenProjectMentionMenu = () => {
  const editor = useBlockNoteEditor();
  const { getMentionItems, MentionMenu, shouldOpenMentionMenu } = useMentionMenu(editor);

  return (
    <SuggestionMenuController
      triggerCharacter={MENTION_TRIGGER}
      getItems={getMentionItems}
      shouldOpen={shouldOpenMentionMenu}
      suggestionMenuComponent={MentionMenu}
    />
  );
};
