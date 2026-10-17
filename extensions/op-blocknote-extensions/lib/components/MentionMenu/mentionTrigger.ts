import type { Transaction } from 'prosemirror-state';
import { textBefore } from '../../utils/suggestionTrigger';

export const MENTION_TRIGGER = '@';

// Like CKEditor's mention feature: "@" only starts a mention where a word would start.
const OPENS_AFTER = /^$|[\s([{"']$/;

/** Runs before the typed "@" is inserted. */
export function canOpenMentionMenu(transaction:Transaction):boolean {
  const characterBefore = textBefore(transaction.selection.$from, 1);
  return characterBefore !== null && OPENS_AFTER.test(characterBefore);
}
