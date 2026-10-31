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

import type { RenderDraft } from '../rendered-occurrence-ledger';
import type { WorkPackageTable } from '../wp-fast-table';
import { TableRowPositions, type CapturedRowPositions } from './table-row-positions';
import { TreegridSemantics } from './treegrid-semantics';

/** `'all'` or the keys of the rows whose own attributes changed; row positions are always repainted for the whole table. */
export type PaintScope = 'all'|ReadonlySet<string>;

export interface RowReplacement {
  readonly key:string;
  readonly previous:HTMLTableRowElement|null;
  readonly replacement:HTMLTableRowElement;
}

export interface PaintResult {
  /** Why row positions were withdrawn or not offered, or null when they are painted. */
  readonly positionsWithdrawn:string|null;
}

export class RowStatePainter {
  private readonly semantics = new TreegridSemantics(this.table);

  private readonly positions = new TableRowPositions(this.table);

  constructor(private readonly table:WorkPackageTable) {}

  public paint(scope:PaintScope = 'all'):PaintResult {
    if (scope === 'all') {
      this.semantics.paint();
    } else {
      this.semantics.paintKeys(scope);
    }
    return { positionsWithdrawn: this.positions.paint() };
  }

  /** The keys of every rendered occurrence of a work package. */
  public keysOf(workPackageId:string):ReadonlySet<string> {
    return new Set(this.table.ledger.byWorkPackageId(workPackageId).map((occurrence) => occurrence.key));
  }

  public capturePositions(draft:RenderDraft):CapturedRowPositions|null {
    return this.positions.capture(draft);
  }

  public commitPositions(snapshot:CapturedRowPositions|null):void {
    this.positions.commit(snapshot);
  }

  /** Refreshed rows replace their predecessors in place under the same keys, so they inherit those rows' indices instead of repainting positions. */
  public paintRefreshed(replacements:readonly RowReplacement[]):void {
    replacements.forEach(({ previous, replacement }) => {
      if (previous) this.positions.carry(previous, replacement);
    });
    this.semantics.paintKeys(new Set(replacements.map(({ key }) => key)));
  }
}
