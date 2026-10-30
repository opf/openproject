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

import { BehaviorSubject, Observable, Subject } from 'rxjs';
import { EntityReference } from 'core-app/shared/types/entity-reference';

export interface SelectionIssue {
  code:'wrong-cardinality'|'invalid-shape'|'unsupported-selection';
  index?:number;
}

export type SelectionState<S> =
  | { kind:'ready'; value:S }
  | { kind:'invalid'; issue:SelectionIssue; lastAccepted?:S };

export type EntitySelection<T> =
  | { kind:'option'; option:T }
  | { kind:'reference'; reference:EntityReference };

export type DecodeResult<S> = { ok:true; value:S } | { ok:false; issue:SelectionIssue };

export type Decoder<S> = (raw:unknown, phase:'load'|'change') => DecodeResult<S>;

export interface SelectionBridge {
  readonly model:unknown;
  load(raw:unknown):void;
  accept(raw:unknown):void;
  readonly compareWith:(a:unknown, b:unknown) => boolean;
  readonly trackBy:(v:unknown) => string|number|undefined;
}

export function decodeAll<T>(
  raw:readonly unknown[],
  decodeOne:(v:unknown, index:number) => DecodeResult<T>,
):DecodeResult<T[]> {
  const values:T[] = [];

  for (const [index, item] of raw.entries()) {
    const result = decodeOne(item, index);
    if (!result.ok) {
      return { ok: false, issue: result.issue };
    }
    values.push(result.value);
  }

  return { ok: true, value: values };
}

export class SelectionAdapter<S> {
  readonly bridge:SelectionBridge;

  readonly changes$:Observable<S>;

  readonly stateChanges$:Observable<SelectionState<S>>;

  private model:unknown;

  private readonly stateSubject:BehaviorSubject<SelectionState<S>>;

  private readonly changesSubject = new Subject<S>();

  constructor(
    private readonly decode:Decoder<S>,
    private readonly emptyModel:unknown,
    private readonly toModel:(value:S) => unknown,
    compareWith:(a:unknown, b:unknown) => boolean,
    trackBy:(v:unknown) => string|number|undefined,
  ) {
    this.model = emptyModel;
    this.stateSubject = new BehaviorSubject<SelectionState<S>>(this.stateFor(this.decode(emptyModel, 'load')));
    this.changes$ = this.changesSubject.asObservable();
    this.stateChanges$ = this.stateSubject.asObservable();

    const readModel = ():unknown => this.model;
    this.bridge = {
      get model() { return readModel(); },
      load: (raw) => this.load(raw),
      accept: (raw) => this.accept(raw),
      compareWith,
      trackBy,
    };
  }

  get state():SelectionState<S> {
    return this.stateSubject.value;
  }

  setValue(value:S):void {
    this.model = this.toModel(value);
    this.stateSubject.next({ kind: 'ready', value });
  }

  private load(raw:unknown):void {
    const result = this.decode(raw, 'load');
    this.model = result.ok ? raw : this.emptyModel;
    this.stateSubject.next(this.stateFor(result));
  }

  private accept(raw:unknown):void {
    const result = this.decode(raw, 'change');
    this.model = raw;

    if (result.ok) {
      this.stateSubject.next({ kind: 'ready', value: result.value });
      this.changesSubject.next(result.value);
    } else {
      this.stateSubject.next({ kind: 'invalid', issue: result.issue, lastAccepted: this.lastAccepted() });
    }
  }

  private stateFor(result:DecodeResult<S>):SelectionState<S> {
    return result.ok ? { kind: 'ready', value: result.value } : { kind: 'invalid', issue: result.issue };
  }

  private lastAccepted():S|undefined {
    const current = this.state;
    return current.kind === 'ready' ? current.value : current.lastAccepted;
  }
}
