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

import type { RowKey } from './row-keys';

/** `'all'`, `'positions'` when rows moved but none changed, or the keys of the rows whose own attributes changed; keyed rows keep their positions, anything else repaints them for the whole table. */
export type PaintScope = 'all'|'positions'|ReadonlySet<RowKey>;

export interface MutationExit {
  readonly scope:PaintScope;
  /** True when a render committed inside this mutation. */
  readonly rendered:boolean;
}

export interface MutationHooks {
  /** Called on every entry; `accumulate` is true while an outer mutation or a pending render is open. */
  enter(accumulate:boolean):void;
  /** Called once, at the outermost exit, after the change ran or threw. */
  exit(exit:MutationExit):void;
}

/** Keyed rows keep their positions, so joining them with a positions-only scope must repaint everything. */
function widen(scope:PaintScope, addition:PaintScope):PaintScope {
  if (scope === 'all' || addition === 'all') return 'all';
  if (scope === 'positions' || addition === 'positions') {
    const rows = scope === 'positions' ? addition : scope;
    return rows === 'positions' || rows.size === 0 ? 'positions' : 'all';
  }
  return new Set([...scope, ...addition]);
}

export class RowMutations {
  private level = 0;

  private scope:PaintScope = new Set();

  private rendered = false;

  constructor(
    private readonly hooks:MutationHooks,
    private readonly renderPending:() => boolean,
  ) {}

  public get depth():number {
    return this.level;
  }

  public run(scope:PaintScope, change:() => void, { rendered = false }:{ rendered?:boolean } = {}):void {
    this.hooks.enter(this.level > 0 || this.renderPending());
    this.level += 1;
    this.scope = widen(this.scope, scope);
    this.rendered ||= rendered;
    try {
      change();
    } finally {
      this.level -= 1;
      if (this.level === 0) {
        const exit:MutationExit = { scope: this.scope, rendered: this.rendered };
        this.scope = new Set();
        this.rendered = false;
        this.hooks.exit(exit);
      }
    }
  }
}
