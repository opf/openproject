import type { Node as ProsemirrorNode } from 'prosemirror-model';
import type { Transaction } from 'prosemirror-state';
import type { AnyEditor } from '../../editorTypes';
import type { BlockWpSize, InlineWpSize } from '../WorkPackage/types';

/**
 * What the hash menu inserts for the work package the user picks. How many `#`
 * characters precede the search query decides it:
 *
 *   #query -> inline chip, "xxs" (ID only)
 *   ##query -> inline chip, "xs" (ID + type + subject)
 *   ###query -> inline chip, "s" (ID + type + status + subject)
 *   ####query -> block card, "m"
 *   #####... -> nothing; the hashes stay on screen as typed
 */
export type HashTarget =
  | { kind:'inline'; size:InlineWpSize }
  | { kind:'block'; size:BlockWpSize }
  | { kind:'none' };

const TARGET_BY_HASH_COUNT:readonly HashTarget[] = [
  { kind: 'inline', size: 'xxs' },
  { kind: 'inline', size: 'xs' },
  { kind: 'inline', size: 's' },
  { kind: 'block', size: 'm' },
];

const NO_TARGET:HashTarget = { kind: 'none' };

export const MAX_TRIGGER_HASHES = TARGET_BY_HASH_COUNT.length;

export function hashTargetFor(editor:AnyEditor, query:string):HashTarget {
  const { doc, selection } = editor.prosemirrorState;
  const queryStart = Math.max(0, selection.from - query.length);
  const hashCount = trailingHashes(doc, queryStart) + leadingHashes(query);

  return TARGET_BY_HASH_COUNT[hashCount - 1] ?? NO_TARGET;
}

/**
 * Runs before the typed `#` is inserted, so the run standing in the document is
 * one shorter than the one the user ends up with: at `###` this opens the menu
 * that `####` needs, at `####` it refuses the fifth hash.
 */
export function canOpenHashMenu(transaction:Transaction):boolean {
  return trailingHashes(transaction.doc, transaction.selection.from) < MAX_TRIGGER_HASHES;
}

// Keeps hash runs on either side of an atom node (an inline chip) apart.
const LEAF_PLACEHOLDER = '\uFFFC';

function trailingHashes(doc:ProsemirrorNode, position:number):number {
  const resolved = doc.resolve(position);
  if (!resolved.parent.isTextblock) return 0;

  const textBefore = resolved.parent.textBetween(
    0,
    resolved.parentOffset,
    undefined,
    LEAF_PLACEHOLDER
  );
  return /#*$/.exec(textBefore)?.[0].length ?? 0;
}

function leadingHashes(query:string):number {
  return /^#*/.exec(query)?.[0].length ?? 0;
}
