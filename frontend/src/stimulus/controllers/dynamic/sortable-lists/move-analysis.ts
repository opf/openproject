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

import type { MoveAvailability, MoveDirection } from './list-dom';

export interface MoveRow {
  element:HTMLElement;
  isItem:boolean;
  orderable:boolean;
  previousItemId:string|null;
}

export interface MoveAnalysis {
  rows:readonly MoveRow[];
  selectedRows:readonly MoveRow[];
  remainingRows:readonly MoveRow[];
  predecessors:Record<MoveDirection, string|null|undefined>;
}

export type BlockMoveResult = {
  available:true;
  rows:HTMLElement[];
  previousItemId:string|null;
}|{ available:false };

export function analyzeMoveRows(rows:readonly MoveRow[], selectedRows:readonly HTMLElement[]):MoveAnalysis|null {
  const selected = new Set(selectedRows);
  if (selected.size === 0 || selected.size !== selectedRows.length) return null;

  const block = rows.filter((row) => selected.has(row.element));
  if (block.length !== selected.size || block.some((row) => !row.isItem || !row.orderable || !row.previousItemId)) return null;

  const firstIndex = rows.indexOf(block[0]);
  const lastIndex = rows.indexOf(block[block.length - 1]);
  const remainingRows = rows.filter((row) => !selected.has(row.element));
  const bottomAnchor = [...remainingRows].reverse().find((row) => row.previousItemId);
  const bottom = bottomAnchor?.previousItemId ?? (remainingRows.length === 0 ? null : undefined);
  const interiorBarrier = rows.slice(firstIndex, lastIndex + 1).some((row) => !row.isItem);
  const above = rows[firstIndex - 1];
  const below = rows[lastIndex + 1];
  const upAnchor = rows[firstIndex - 2];

  return {
    rows,
    selectedRows: block,
    remainingRows,
    predecessors: {
      top: null,
      bottom,
      up: interiorBarrier || (above && !above.isItem)
        ? undefined
        : (upAnchor ? upAnchor.previousItemId ?? undefined : null),
      down: interiorBarrier || (below && !below.isItem)
        ? undefined
        : (below ? below.previousItemId ?? undefined : bottom),
    },
  };
}

export function resolveAnalyzedMove(analysis:MoveAnalysis, direction:MoveDirection):BlockMoveResult {
  const { rows, selectedRows, remainingRows, predecessors } = analysis;
  const previousItemId = predecessors[direction];
  if (previousItemId === undefined) return { available: false };

  const anchorIndex = previousItemId === null ? -1 : remainingRows.findIndex((row) => row.previousItemId === previousItemId);
  if (previousItemId !== null && anchorIndex === -1) return { available: false };

  const result = [
    ...remainingRows.slice(0, anchorIndex + 1),
    ...selectedRows,
    ...remainingRows.slice(anchorIndex + 1),
  ];
  if (result.every((row, index) => row === rows[index])) return { available: false };

  return { available: true, rows: selectedRows.map((row) => row.element), previousItemId };
}

export function analyzedMoveAvailability(analysis:MoveAnalysis):MoveAvailability {
  return {
    top: resolveAnalyzedMove(analysis, 'top').available,
    up: resolveAnalyzedMove(analysis, 'up').available,
    down: resolveAnalyzedMove(analysis, 'down').available,
    bottom: resolveAnalyzedMove(analysis, 'bottom').available,
  };
}
