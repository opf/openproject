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

import { DestroyRef, Injectable, inject } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { Observable, Subscription } from 'rxjs';

export type AddCardPermissionKey = 'add'|'reference';

export interface AddCardPermission {
  /** The permission once looked up, `undefined` while loading or after a failure. */
  readonly known:boolean|undefined;
  /** The latest state: whether a looked-up permission is granted. */
  readonly current:boolean;
  /** Settles once the lookup succeeds or fails, looking a failed one up again. */
  settle():Promise<void>;
}

type LookupState = { status:'idle'|'loading'|'failed' } | { status:'loaded', allowed:boolean };

class SharedPermissionLookup {
  private state:LookupState = { status: 'idle' };

  private pending:Promise<void> = Promise.resolve();

  private subscription?:Subscription;

  constructor(private readonly destroyRef:DestroyRef) {}

  get known():boolean|undefined {
    return this.state.status === 'loaded' ? this.state.allowed : undefined;
  }

  settle(lookup:() => Observable<boolean>):Promise<void> {
    if (this.state.status === 'idle' || this.state.status === 'failed') {
      this.pending = this.start(lookup);
    }
    return this.pending;
  }

  private start(lookup:() => Observable<boolean>):Promise<void> {
    this.state = { status: 'loading' };
    this.subscription?.unsubscribe();
    return new Promise((resolve) => {
      const fail = () => {
        if (this.state.status === 'loading') {
          this.state = { status: 'failed' };
        }
        resolve();
      };
      this.subscription = lookup()
        .pipe(takeUntilDestroyed(this.destroyRef))
        .subscribe({
          next: (allowed) => {
            this.state = { status: 'loaded', allowed };
            resolve();
          },
          error: () => {
            this.state = { status: 'failed' };
            resolve();
          },
          complete: fail,
        });
    });
  }
}

/**
 * The Add card permissions of a board, looked up once for all its lists.
 * Every list waits on the same lookup, sees its failure, and may start it
 * again when it fails.
 */
@Injectable()
export class AddCardPermissionsService {
  private readonly destroyRef = inject(DestroyRef);

  private readonly lookups = new Map<AddCardPermissionKey, SharedPermissionLookup>();

  permission(key:AddCardPermissionKey, lookup:() => Observable<boolean>):AddCardPermission {
    const shared = this.shared(key);
    return {
      get known() {
        return shared.known;
      },
      get current() {
        return shared.known ?? false;
      },
      settle: () => shared.settle(lookup),
    };
  }

  private shared(key:AddCardPermissionKey):SharedPermissionLookup {
    let shared = this.lookups.get(key);
    if (!shared) {
      shared = new SharedPermissionLookup(this.destroyRef);
      this.lookups.set(key, shared);
    }
    return shared;
  }
}
