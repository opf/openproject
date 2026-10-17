import { useCallback } from 'react';
import type { AnyEditor } from '../../editorTypes';
import type { Principal } from '../../openProjectTypes';
import { searchMentionableUsers } from '../../services/openProjectApi';
import { useDebouncedSearch } from '../../hooks/useDebouncedSearch';
import { useSuggestionSearch } from '../../hooks/useSuggestionSearch';
import type { SuggestionPlan } from '../../hooks/useSuggestionSearch';
import { insertInline } from '../../utils/insertInline';
import { USER_MENTION_TYPE } from '../../utils/nodeTypes';
import { canOpenMentionMenu, MENTION_TRIGGER } from './mentionTrigger';
import { createMentionMenuComponent } from './MentionMenu';

function insertMention(editor:AnyEditor, principal:Principal):void {
  insertInline(editor, [
    { type: USER_MENTION_TYPE, props: { userId: String(principal.id), name: principal.name } },
    { type: 'text', text: ' ', styles: {} },
  ]);
  editor.focus();
}

export function useMentionMenu(editor:AnyEditor) {
  const { search, cancel } = useDebouncedSearch(searchMentionableUsers, { searchBlank: true });

  const planFor = useCallback(
    ():SuggestionPlan<Principal> => ({ kind: 'search', pick: (principal) => insertMention(editor, principal) }),
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
