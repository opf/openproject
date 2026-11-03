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
import { TableRowPositions, type RowPositionEvidence } from './table-row-positions';
import { paintRowRole, paintSectionExposure, setOrRemove, TreegridSemantics } from './treegrid-semantics';

import type { PaintScope } from '../row-mutations';

export type { PaintScope };

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
    } else if (scope !== 'positions') {
      this.semantics.paintKeys(scope);
    }
    this.paintEdgeRows();
    if (this.carriesPositions(scope)) return { positionsWithdrawn: this.positions.withdrawn };
    return { positionsWithdrawn: this.positions.paint() };
  }

  /** Rows named by occurrence keys changed in place and keep their indices; anything else (edge rows, moved rows, a full render) recomputes positions from the DOM order. */
  private carriesPositions(scope:PaintScope):boolean {
    return scope !== 'all' && scope !== 'positions' && Array.from(scope).every((key) => this.table.ledger.byKey(key) !== undefined);
  }

  /** The column header, totals, inline-create and empty-results rows live in their own sections, outside the results body. */
  private paintEdgeRows():void {
    if (this.table.destroyed) return;
    const tableElement = this.table.tbody.closest('table');
    if (tableElement?.tHead) {
      setOrRemove(tableElement.tHead, 'role', 'rowgroup');
      Array.from(tableElement.tHead.rows).forEach((row) => paintRowRole(row, 1, 'columnheader'));
    }
    const sections = Array.from(tableElement?.tBodies ?? []);
    sections
      .filter((section) => section !== this.table.tbody)
      .flatMap((section) => this.table.rows.rowsOf(section))
      .forEach(({ element, state: { kind, hidden } }) => {
        if (!['totals', 'inlineCreate', 'emptyResults'].includes(kind)) return;
        paintRowRole(element, 1);
        if (kind === 'totals') setOrRemove(element, 'aria-hidden', hidden ? 'true' : null);
      });
    sections.forEach(paintSectionExposure);
  }

  public capturePositions(draft:RenderDraft):RowPositionEvidence {
    return this.positions.capture(draft);
  }

  public commitPositions(evidence:RowPositionEvidence):void {
    this.positions.commit(evidence);
  }

  /** Refreshed rows replace their predecessors in place under the same keys, so they inherit those rows' indices instead of repainting positions. */
  public carryPositions(replacements:readonly RowReplacement[]):void {
    replacements.forEach(({ previous, replacement }) => {
      if (previous) this.positions.carry(previous, replacement);
    });
  }
}
