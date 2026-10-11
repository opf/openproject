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

import { randomUUID } from "node:crypto";

interface Entry {
  state: Uint8Array;
  storedAt: number;
}

/**
 * Keeps the Yjs state of recently read document revisions in memory,
 * so a later edit can be expressed relative to the exact state it was based on.
 */
export class RevisionStore {
  private readonly entries = new Map<string, Entry>();

  constructor(
    private readonly maxEntries = 200,
    private readonly ttlMs = 60 * 60 * 1000,
  ) {}

  remember(documentName: string, state: Uint8Array): string {
    const revision = randomUUID();
    this.store(documentName, revision, state);
    return revision;
  }

  replace(documentName: string, revision: string, state: Uint8Array): void {
    this.store(documentName, revision, state);
  }

  recall(documentName: string, revision: string): Uint8Array | undefined {
    const key = this.key(documentName, revision);
    const entry = this.entries.get(key);

    if (!entry) return undefined;
    if (Date.now() - entry.storedAt > this.ttlMs) {
      this.entries.delete(key);
      return undefined;
    }

    return entry.state;
  }

  private store(documentName: string, revision: string, state: Uint8Array): void {
    const key = this.key(documentName, revision);
    this.entries.delete(key);
    this.entries.set(key, { state, storedAt: Date.now() });

    while (this.entries.size > this.maxEntries) {
      this.entries.delete(this.entries.keys().next().value!);
    }
  }

  private key(documentName: string, revision: string): string {
    return `${revision}@${documentName}`;
  }
}
