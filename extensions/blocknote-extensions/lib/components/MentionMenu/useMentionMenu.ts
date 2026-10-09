import { useCallback } from 'react';
import type { AnyEditor } from '../../editorTypes';
import type { MentionableUser } from '../../openProjectTypes';
import { searchMentionableUsers } from '../../services/openProjectApi';
import { useDebouncedSearch } from '../../hooks/useDebouncedSearch';
import { useSuggestionSearch } from '../../hooks/useSuggestionSearch';
import type { SuggestionPlan } from '../../hooks/useSuggestionSearch';
import { insertInline } from '../../utils/insertInline';
import { USER_MENTION_TYPE } from '../../utils/nodeTypes';
import { canOpenMentionMenu, MENTION_TRIGGER } from './mentionTrigger';
import { createMentionMenuComponent } from './MentionMenu';

function insertMention(editor:AnyEditor, user:MentionableUser):void {
  insertInline(editor, [
    { type: USER_MENTION_TYPE, props: { userId: String(user.id), name: user.name } },
    { type: 'text', text: ' ', styles: {} },
  ]);
  editor.focus();
}

export function useMentionMenu(editor:AnyEditor) {
  const { search, cancel } = useDebouncedSearch(searchMentionableUsers, { searchBlank: true });

  const planFor = useCallback(
    ():SuggestionPlan<MentionableUser> => ({ kind: 'search', pick: (user) => insertMention(editor, user) }),
    [editor]
  );

  const { getItems, Menu } = useSuggestionSearch(editor, {
    trigger: MENTION_TRIGGER,
    planFor,
    search,
    cancelSearch: cancel,
    logPrefix: '[mention search] Failed to load users from OpenProject:',
    createMenu: createMentionMenuComponent,
  });

  return { getMentionItems: getItems, MentionMenu: Menu, shouldOpenMentionMenu: canOpenMentionMenu };
}
