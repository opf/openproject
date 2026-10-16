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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { reindexAriaRowsAfter } from './aria-row-indices';
import { anchorRow, renderList } from './rendered-list';

export interface RowPlacement {
  row:HTMLElement;
  parent:HTMLElement|null;
  nextElementSibling:Element|null;
}

// Snapshot each row's current location so an optimistic move can be undone if
// the server rejects it. Captured before the move; restored in reverse so the
// stored nextElementSibling references are still valid when reinserting.
export function captureRowPositions(rows:HTMLElement[]):RowPlacement[] {
  return rows.map((row) => ({
    row,
    parent: row.parentElement,
    nextElementSibling: row.nextElementSibling,
  }));
}

export function restoreRowPositions(positions:RowPlacement[]):void {
  const containers = [
    ...rowContainers(positions.map(({ row }) => row)),
    ...positions.flatMap(({ parent }) => (parent ? [parent] : [])),
  ];

  reindexAriaRowsAfter(containers, () => {
    for (let i = positions.length - 1; i >= 0; i -= 1) {
      const { row, parent, nextElementSibling } = positions[i];
      // A list-refresh morph can replace the captured parent mid-request; restoring
      // into a detached node would drop the row out of the live DOM until the next
      // reload. Skip it and let the pending refresh reconcile the position.
      if (!parent?.isConnected) {
        continue;
      }

      const insertionPoint = nextElementSibling?.parentNode === parent ? nextElementSibling : null;
      parent.insertBefore(row, insertionPoint);
    }
  });
}

// A rollback may only reinsert rows it still owns: if a concurrent morph
// removed or repositioned a row after the optimistic move, the morph reflects
// fresher server state and the rollback must yield. The comparison is
// element-level placement only — a changed parent or element sibling counts
// as foreign ownership; text and comment nodes are deliberately ignored.
export function rowsRemainAt(positions:RowPlacement[]):boolean {
  return positions.every(({ row, parent, nextElementSibling }) => (
    row.parentElement === parent && row.nextElementSibling === nextElementSibling
  ));
}

// Optimistically move rows on the client without waiting for the server.
// `rows` are the moved rows in order; `previousItemId` of null means top of
// list.
export function reorderRows({
  rows,
  rowsContainer,
  previousItemId,
}:{
  rows:HTMLElement[];
  rowsContainer:HTMLElement;
  previousItemId:string|null;
}):void {
  reindexAriaRowsAfter([...rowContainers(rows), rowsContainer], () => {
    let anchor:Element|null = previousItemId ? anchorRow(renderList(rowsContainer), previousItemId)?.element ?? null : null;

    for (const row of rows) {
      if (anchor) {
        anchor.after(row);
      } else {
        insertAtListTop(rowsContainer, row);
      }

      anchor = row;
    }
  });
}

function rowContainers(rows:HTMLElement[]):Element[] {
  return rows.flatMap((row) => (row.parentElement ? [row.parentElement] : []));
}

// Insert before the first existing row, keeping the moved row among its
// siblings. An empty rows container simply receives the row.
function insertAtListTop(rowsContainer:HTMLElement, row:HTMLElement):void {
  const firstRow = rowsContainer.firstElementChild;

  if (firstRow && firstRow !== row) {
    firstRow.before(row);
  } else if (!firstRow) {
    rowsContainer.prepend(row);
  }
}
