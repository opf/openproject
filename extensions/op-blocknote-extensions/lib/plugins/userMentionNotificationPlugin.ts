import { Plugin, PluginKey } from 'prosemirror-state';
import type { Transaction } from 'prosemirror-state';
import type { Node as ProsemirrorNode } from 'prosemirror-model';
import { contextDocumentId } from '../services/editorContext';
import { notifyMentionedUser } from '../services/openProjectApi';
import { USER_MENTION_TYPE } from '../utils/nodeTypes';

// y-prosemirror's sync key, matched by name like BlockNote does, so the bundle needs no y-prosemirror.
const Y_SYNC_META_KEY = 'y-sync$';

/** Per user: mentions inserted minus removed by local transactions. */
type MentionTally = ReadonlyMap<string, number>;

const userMentionNotificationKey = new PluginKey<MentionTally>('userMentionNotification');

function isFromYjs(transaction:Transaction):boolean {
  return transaction.getMeta(Y_SYNC_META_KEY) !== undefined;
}

function isUserMention(node:ProsemirrorNode):boolean {
  return node.type.name === USER_MENTION_TYPE;
}

function addMentions(counts:Map<string, number>, userId:string, amount:number):void {
  counts.set(userId, (counts.get(userId) ?? 0) + amount);
}

function mentionedUserId(node:ProsemirrorNode):string {
  return String(node.attrs.userId);
}

// A move removes as many mentions of the user as it inserts, so it nets out.
function mentionChanges(transaction:Transaction):Map<string, number> {
  const changes = new Map<string, number>();
  let insertedRanges:{ from:number; to:number }[] = [];
  transaction.steps.forEach((step, index) => {
    const stepMap = step.getMap();
    insertedRanges = insertedRanges
      .map(({ from, to }) => ({ from: stepMap.map(from, 1), to: stepMap.map(to, -1) }))
      .filter(({ from, to }) => from < to);

    stepMap.forEach((oldStart, oldEnd, newStart, newEnd) => {
      if (newStart < newEnd) insertedRanges.push({ from: newStart, to: newEnd });
      transaction.docs[index].nodesBetween(oldStart, oldEnd, (node) => {
        if (isUserMention(node)) addMentions(changes, mentionedUserId(node), -1);
      });
    });
  });

  const counted = new Set<number>();
  for (const { from, to } of insertedRanges) {
    transaction.doc.nodesBetween(from, to, (node, position) => {
      if (!isUserMention(node) || counted.has(position)) return;
      counted.add(position);
      addMentions(changes, mentionedUserId(node), 1);
    });
  }
  return changes;
}

function tallied(tally:MentionTally, transaction:Transaction):MentionTally {
  if (!transaction.docChanged || isFromYjs(transaction)) return tally;

  const changes = mentionChanges(transaction);
  if (changes.size === 0) return tally;

  const next = new Map(tally);
  changes.forEach((change, userId) => addMentions(next, userId, change));
  return next;
}

function notify(documentId:string | number, userId:string):void {
  notifyMentionedUser(documentId, userId).catch((error:unknown) => {
    console.error(`[user mention] Failed to notify user ${userId}:`, error);
  });
}

// Sends from the view, not from `apply`, so a state that is never applied notifies nobody.
export function userMentionNotificationPlugin():Plugin<MentionTally> {
  return new Plugin<MentionTally>({
    key: userMentionNotificationKey,
    state: {
      init: () => new Map(),
      apply: (transaction, tally) => tallied(tally, transaction),
    },
    view: () => ({
      update(view, previousState) {
        const tally = userMentionNotificationKey.getState(view.state);
        const previousTally = userMentionNotificationKey.getState(previousState);
        const documentId = contextDocumentId();
        if (!tally || !previousTally || tally === previousTally || documentId === undefined) return;

        tally.forEach((mentions, userId) => {
          if (mentions > (previousTally.get(userId) ?? 0)) notify(documentId, userId);
        });
      },
    }),
  });
}
