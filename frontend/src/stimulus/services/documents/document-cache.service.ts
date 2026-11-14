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

import type * as Y from 'yjs';
import { IndexeddbPersistence } from 'y-indexeddb';
import { getMetaValue } from 'core-app/core/setup/globals/global-helpers';

const DB_PREFIX = 'op-document:';
const DEFAULT_TIMEOUT_MS = 3000;
const BLOCKED_GRACE_MS = 1000;
const STORES = ['updates', 'custom'];

interface OpenOptions {
  timeoutMs?:number;
}

export class DocumentCache {
  static async open(
    documentName:string,
    doc:Y.Doc,
    { timeoutMs = DEFAULT_TIMEOUT_MS }:OpenOptions = {},
  ):Promise<DocumentCache|null> {
    const name = DocumentCache.databaseName(documentName);
    if (!name) return null;

    let persistence:IndexeddbPersistence;
    try {
      persistence = new IndexeddbPersistence(name, doc);
    } catch {
      return null;
    }

    const opening = DocumentCache.connection(persistence);
    opening
      .then((db) => DocumentCache.detachOnVersionChange(persistence, db))
      .catch(() => {
        // A failed open is reported through the readiness race below.
      });

    const cachedContentApplied = persistence.whenSynced.then(() => true);

    const openFailed = new Promise<boolean>((resolve) => {
      opening.catch(() => resolve(false));
    });

    let timeout:ReturnType<typeof setTimeout>|undefined;
    const timedOut = new Promise<boolean>((resolve) => {
      timeout = setTimeout(() => resolve(false), timeoutMs);
    });

    const ready = await Promise.race([cachedContentApplied, openFailed, timedOut]);
    clearTimeout(timeout);

    if (!ready) {
      void DocumentCache.detach(persistence);
      return null;
    }

    return new DocumentCache(name, persistence);
  }

  static async evict(documentName:string):Promise<void> {
    const name = DocumentCache.databaseName(documentName);
    if (!name) return;

    await DocumentCache.deleteDatabase(name);
  }

  private constructor(
    private readonly name:string,
    private readonly persistence:IndexeddbPersistence,
  ) {}

  close():void {
    void DocumentCache.detach(this.persistence);
  }

  async evict():Promise<void> {
    const { db } = this.persistence;
    // Listeners are removed synchronously by destroy, and the clear transaction is created in the
    // same tick, so no update can be written in between and the queued close waits for the clear.
    const detached = DocumentCache.detach(this.persistence);

    if (db) {
      await DocumentCache.clearStores(db);
    }

    await detached;
    await DocumentCache.deleteDatabase(this.name);
  }

  /**
   * Name of the cache database: one per user and document. Scoping by user keeps one person's
   * unsynced edits from loading under another account on a shared browser. Null when nobody is
   * logged in, which means: do not cache.
   *
   * @example
   * "op-document:42:https://example.org/api/v3/documents/7"
   */
  private static databaseName(documentName:string):string|null {
    if (getMetaValue('current_user', 'loggedIn') !== 'true') return null;

    const userId = getMetaValue('current_user', 'id');
    if (!userId) return null;

    return `${DB_PREFIX}${userId}:${documentName}`;
  }

  /**
   * The library's internal open promise, which it does not expose. Its public ready signal never
   * settles when IndexedDB is unavailable (private browsing, blocked site data), while this
   * promise rejects, so opening can give up at once instead of waiting out the timeout. It also
   * hands over the connection as soon as it opens, before cached content has been applied.
   */
  private static connection(persistence:IndexeddbPersistence):Promise<IDBDatabase> {
    // eslint-disable-next-line no-underscore-dangle
    return (persistence as unknown as { _db:Promise<IDBDatabase> })._db;
  }

  /**
   * A deleted database leaves the library's connection closed but still attached to the doc,
   * and its next write would throw inside the doc's update emit.
   */
  private static detachOnVersionChange(persistence:IndexeddbPersistence, db:IDBDatabase):void {
    const closeConnection = db.onversionchange;
    db.onversionchange = (event) => {
      void DocumentCache.detach(persistence);
      closeConnection?.call(db, event);
    };
  }

  private static async detach(persistence:IndexeddbPersistence):Promise<void> {
    try {
      await persistence.destroy();
    } catch {
      // The database never opened, so there is nothing to close.
    }
  }

  private static clearStores(db:IDBDatabase):Promise<void> {
    return DocumentCache.bounded((finish) => {
      const transaction = db.transaction(STORES, 'readwrite');
      STORES.forEach((store) => transaction.objectStore(store).clear());
      transaction.oncomplete = finish;
      transaction.onerror = finish;
      transaction.onabort = finish;
    });
  }

  private static deleteDatabase(name:string):Promise<void> {
    return DocumentCache.bounded((finish) => {
      const request = indexedDB.deleteDatabase(name);
      request.onsuccess = finish;
      request.onerror = finish;
    });
  }

  /**
   * Resolves when the operation finishes, or after a grace period so a blocked one never hangs
   * the caller.
   */
  private static bounded(start:(finish:() => void) => void):Promise<void> {
    return new Promise((resolve) => {
      const grace = setTimeout(resolve, BLOCKED_GRACE_MS);
      const finish = () => {
        clearTimeout(grace);
        resolve();
      };

      try {
        start(finish);
      } catch {
        finish();
      }
    });
  }
}
