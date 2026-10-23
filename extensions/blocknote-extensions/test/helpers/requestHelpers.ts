import { onTestFinished } from 'vitest';
import type { AnyEditor } from '../../lib/editorTypes';
import { mentionContent } from './content';
import { worker } from '../mocks/browser';

export async function requestsDuring(endpoint:string, act:() => Promise<void>):Promise<string[]> {
  const asked:string[] = [];
  const record = ({ request }:{ request:Request }) => {
    if (request.url.includes(endpoint)) asked.push(request.url);
  };

  worker.events.on('request:start', record);
  try {
    await act();
  } finally {
    worker.events.removeListener('request:start', record);
  }

  return asked;
}

function mentionNotification(documentId:number, userId:number) {
  return {
    reason: 'mentioned',
    _links: {
      resource: { href: `/api/v3/documents/${documentId}` },
      recipient: { href: `/api/v3/users/${userId}` },
    },
  };
}

export function recordMentionNotifications():() => Promise<unknown[]> {
  const bodies:Promise<unknown>[] = [];
  const record = ({ request }:{ request:Request }) => {
    if (request.method === 'POST' && request.url.endsWith('/api/v3/notifications')) bodies.push(request.clone().json());
  };

  worker.events.on('request:start', record);
  onTestFinished(() => worker.events.removeListener('request:start', record));

  return () => Promise.all(bodies);
}

const FENCE_USER_ID = 7;

/** Mentions one more user: once its notification arrives, a late duplicate sent before it would have too. */
export function fenceMentionNotifications(
  editor:AnyEditor,
  { documentId, userIds }:{ documentId:number; userIds:number[] }
):ReturnType<typeof mentionNotification>[] {
  editor.insertInlineContent([mentionContent(String(FENCE_USER_ID), 'Anna Kovalenko')]);

  return [...userIds, FENCE_USER_ID].map((userId) => mentionNotification(documentId, userId));
}
