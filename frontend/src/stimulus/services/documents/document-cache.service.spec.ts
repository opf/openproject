//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import * as Y from 'yjs';
import { afterEach, beforeEach, describe, expect, it, onTestFinished, vi } from 'vitest';
import { DocumentCache } from './document-cache.service';

const documentName = 'http://localhost/api/v3/documents/1';
const dbPrefix = 'op-document:';

function setCurrentUser(id:string|null, loggedIn = true) {
  document.head.querySelector('meta[name="current_user"]')?.remove();
  if (id === null) return;

  const meta = document.createElement('meta');
  meta.name = 'current_user';
  meta.dataset.id = id;
  meta.dataset.loggedIn = String(loggedIn);
  document.head.appendChild(meta);
}

function textOf(doc:Y.Doc):string {
  return doc.getText('t').toJSON();
}

async function cachedDatabaseNames() {
  const databases = await indexedDB.databases();
  return databases.map((db) => db.name!).filter((name) => name.startsWith(dbPrefix));
}

async function storedUpdateCount(name:string) {
  const db = await new Promise<IDBDatabase>((resolve, reject) => {
    const request = indexedDB.open(name);
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(new Error('open failed'));
  });
  const count = await new Promise<number>((resolve) => {
    const request = db.transaction('updates').objectStore('updates').count();
    request.onsuccess = () => resolve(request.result);
  });
  db.close();
  return count;
}

describe('document cache', () => {
  const caches:DocumentCache[] = [];

  beforeEach(() => setCurrentUser('7'));

  afterEach(async () => {
    vi.restoreAllMocks();
    caches.splice(0).forEach((cache) => cache.close());
    await Promise.all(['7', '8'].map((id) => {
      setCurrentUser(id);
      return DocumentCache.evict(documentName);
    }));
    setCurrentUser(null);
  });

  async function track(doc:Y.Doc) {
    const cache = await DocumentCache.open(documentName, doc);
    expect(cache).not.toBeNull();
    caches.push(cache!);
    return cache!;
  }

  it('restores content for the same user and document, but not for another user', async () => {
    const first = new Y.Doc();
    const cache = await track(first);
    first.getText('t').insert(0, 'offline edit');
    cache.close();

    const restored = new Y.Doc();
    await track(restored);
    expect(textOf(restored)).toBe('offline edit');

    setCurrentUser('8');
    const other = new Y.Doc();
    await track(other);
    expect(textOf(other)).toBe('');
  });

  it('evicts through a handle and by document name', async () => {
    const doc = new Y.Doc();
    const cache = await track(doc);
    doc.getText('t').insert(0, 'to be evicted');

    await cache.evict();
    expect(await cachedDatabaseNames()).toHaveLength(0);

    const fresh = new Y.Doc();
    const reopened = await track(fresh);
    expect(textOf(fresh)).toBe('');
    reopened.close();
    expect(await cachedDatabaseNames()).toHaveLength(1);

    await DocumentCache.evict(documentName);
    expect(await cachedDatabaseNames()).toHaveLength(0);
  });

  it('keeps other update listeners running when another handle evicts the database', async () => {
    const evictingCache = await track(new Y.Doc());
    const second = new Y.Doc();
    await track(second);
    const listener = vi.fn();
    second.on('update', listener);

    await evictingCache.evict();

    expect(() => second.getText('t').insert(0, 'after eviction')).not.toThrow();
    expect(listener).toHaveBeenCalledTimes(1);
  });

  it('leaves nothing attached to the doc when the open times out', async () => {
    const realOpen = indexedDB.open.bind(indexedDB);
    const hung = {} as IDBOpenDBRequest;
    vi.spyOn(indexedDB, 'open').mockImplementation(() => hung);
    const doc = new Y.Doc();

    const cache = await DocumentCache.open(documentName, doc, { timeoutMs: 20 });
    expect(cache).toBeNull();

    const lateOpen = realOpen(`${dbPrefix}7:${documentName}`);
    lateOpen.onupgradeneeded = (event) => hung.onupgradeneeded?.call(lateOpen, event);
    await new Promise<void>((resolve) => {
      lateOpen.onsuccess = (event) => {
        hung.onsuccess?.call(lateOpen, event);
        resolve();
      };
    });

    doc.getText('t').insert(0, 'still usable');
    expect(textOf(doc)).toBe('still usable');
    vi.restoreAllMocks();
    expect(await storedUpdateCount(`${dbPrefix}7:${documentName}`)).toBe(0);
  });

  it('resolves to no cache promptly when the open fails', async () => {
    // The library leaves its own open chain unhandled when the open fails.
    const ignoreRejection = (event:PromiseRejectionEvent) => event.preventDefault();
    window.addEventListener('unhandledrejection', ignoreRejection);
    onTestFinished(() => window.removeEventListener('unhandledrejection', ignoreRejection));
    vi.spyOn(indexedDB, 'open').mockImplementation(() => {
      const request = {} as IDBOpenDBRequest;
      setTimeout(() => request.onerror?.call(request, { target: { error: new Error('blocked') } } as unknown as Event));
      return request;
    });
    const doc = new Y.Doc();
    const startedAt = performance.now();

    const cache = await DocumentCache.open(documentName, doc, { timeoutMs: 5000 });

    expect(cache).toBeNull();
    expect(performance.now() - startedAt).toBeLessThan(1000);
    expect(() => doc.getText('t').insert(0, 'still usable')).not.toThrow();
  });

  it('does not cache for a logged-out user', async () => {
    setCurrentUser('2', false);
    expect(await DocumentCache.open(documentName, new Y.Doc())).toBeNull();
    expect(await cachedDatabaseNames()).toHaveLength(0);
  });
});
