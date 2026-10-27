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

export type RowKind = 'header'|'workPackage'|'groupHeader'|'sums'|'totals';

export interface NavigableRow {
  key:string;
  kind:RowKind;
  hidden:boolean;
  cellCount:number;
  expanded:boolean|null;
  groupIdentifier?:string;
}

export interface FocusPosition {
  key:string;
  cell:number|null;
  desiredColumn:number|null;
  groupIdentifier?:string;
}

export type NavKey = 'ArrowUp'|'ArrowDown'|'ArrowLeft'|'ArrowRight'|'Home'|'End'|'PageUp'|'PageDown'|'CtrlHome'|'CtrlEnd';

export type NavResult =
  | { type:'move', position:FocusPosition }
  | { type:'expand', key:string }
  | { type:'collapse', key:string }
  | { type:'none' };

const NONE:NavResult = { type: 'none' };

function positionOn(row:NavigableRow, cell:number|null, desiredColumn:number|null):FocusPosition {
  const position:FocusPosition = { key: row.key, cell, desiredColumn };
  return row.groupIdentifier === undefined ? position : { ...position, groupIdentifier: row.groupIdentifier };
}

function visibleIndexes(rows:readonly NavigableRow[], requireCells:boolean):number[] {
  return rows.flatMap((row, index) => (row.hidden || (requireCells && row.cellCount === 0) ? [] : [index]));
}

function landOn(row:NavigableRow, cellFocus:boolean, desiredColumn:number|null):FocusPosition {
  if (!cellFocus) {
    return positionOn(row, null, null);
  }

  const column = desiredColumn ?? 0;
  return positionOn(row, Math.min(column, row.cellCount - 1), column);
}

function toResult(position:FocusPosition, current:FocusPosition):NavResult {
  const unchanged = position.key === current.key
    && position.cell === current.cell
    && position.desiredColumn === current.desiredColumn;
  return unchanged ? NONE : { type: 'move', position };
}

function moveRows(
  rows:readonly NavigableRow[],
  position:FocusPosition,
  currentIndex:number,
  delta:number,
):NavResult {
  const cellFocus = position.cell !== null;
  const visible = visibleIndexes(rows, cellFocus);
  const at = visible.indexOf(currentIndex);
  const target = visible[Math.min(Math.max(at + delta, 0), visible.length - 1)];

  if (at === -1 || target === currentIndex) {
    return NONE;
  }

  return toResult(landOn(rows[target], cellFocus, position.desiredColumn), position);
}

function moveToEdge(
  rows:readonly NavigableRow[],
  position:FocusPosition,
  edge:'first'|'last',
  column:'desired'|'edge',
):NavResult {
  const cellFocus = position.cell !== null;
  const visible = visibleIndexes(rows, cellFocus);
  const target = rows[edge === 'first' ? visible[0] : visible[visible.length - 1]];

  if (!target) {
    return NONE;
  }

  if (!cellFocus || column === 'desired') {
    return toResult(landOn(target, cellFocus, position.desiredColumn), position);
  }

  const cell = edge === 'first' ? 0 : target.cellCount - 1;
  return toResult(positionOn(target, cell, cell), position);
}

function navigateHorizontally(row:NavigableRow, position:FocusPosition, direction:'Home'|'End'|'ArrowLeft'|'ArrowRight'):NavResult {
  const cell = position.cell ?? 0;
  const last = row.cellCount - 1;
  const landing = { Home: 0, End: last, ArrowLeft: cell - 1, ArrowRight: cell + 1 }[direction];

  if (landing < 0) {
    return toResult(positionOn(row, null, position.desiredColumn), position);
  }

  if (landing > last) {
    return NONE;
  }

  return toResult(positionOn(row, landing, landing), position);
}

function navigateFromRow(rows:readonly NavigableRow[], row:NavigableRow, position:FocusPosition, key:NavKey, index:number, pageSize:number):NavResult {
  switch (key) {
    case 'ArrowRight':
      if (row.expanded === false) {
        return { type: 'expand', key: row.key };
      }
      return row.cellCount > 0 ? { type: 'move', position: positionOn(row, 0, 0) } : NONE;
    case 'ArrowLeft':
      return row.expanded === true ? { type: 'collapse', key: row.key } : NONE;
    default:
      return navigateVertically(rows, position, key, index, pageSize);
  }
}

function navigateVertically(rows:readonly NavigableRow[], position:FocusPosition, key:NavKey, index:number, pageSize:number):NavResult {
  switch (key) {
    case 'ArrowUp':
      return moveRows(rows, position, index, -1);
    case 'ArrowDown':
      return moveRows(rows, position, index, 1);
    case 'PageUp':
      return moveRows(rows, position, index, -pageSize);
    case 'PageDown':
      return moveRows(rows, position, index, pageSize);
    case 'Home':
      return moveToEdge(rows, position, 'first', 'desired');
    case 'End':
      return moveToEdge(rows, position, 'last', 'desired');
    case 'CtrlHome':
      return moveToEdge(rows, position, 'first', 'edge');
    case 'CtrlEnd':
      return moveToEdge(rows, position, 'last', 'edge');
    default:
      return NONE;
  }
}

/** Computes what a navigation key does at the given position. */
export function computeNextPosition(
  rows:readonly NavigableRow[],
  position:FocusPosition,
  key:NavKey,
  pageSize:number,
):NavResult {
  const index = rows.findIndex((row) => row.key === position.key);
  if (index === -1) {
    return NONE;
  }

  const row = rows[index];
  if (row.hidden) {
    return NONE;
  }

  if (position.cell === null) {
    return navigateFromRow(rows, row, position, key, index, pageSize);
  }

  switch (key) {
    case 'ArrowLeft':
    case 'ArrowRight':
    case 'Home':
    case 'End':
      return navigateHorizontally(row, position, key);
    default:
      return navigateVertically(rows, position, key, index, pageSize);
  }
}

/** Returns the position focus starts on after a render, or null when no row is visible. */
export function initialPosition(rows:readonly NavigableRow[]):FocusPosition|null {
  const visible = rows.filter((row) => !row.hidden);
  const first = visible.find((row) => row.kind === 'workPackage') ?? visible[0];
  return first ? positionOn(first, null, null) : null;
}

function keyPart(key:string):string {
  return key.slice(key.lastIndexOf(':') + 1);
}

function isSameRow(row:NavigableRow, previous:FocusPosition):boolean {
  const { groupIdentifier } = previous;

  if (groupIdentifier !== undefined) {
    return row.groupIdentifier === groupIdentifier && keyPart(row.key) === keyPart(previous.key);
  }

  return row.key === previous.key;
}

/** Returns row focus on the visible row closest to the index, the lower one on a tie, or null when none is visible. */
export function nearestPosition(rows:readonly NavigableRow[], index:number):FocusPosition|null {
  const nearest = visibleIndexes(rows, false).reduce<number|null>(
    (best, candidate) => (best === null || Math.abs(candidate - index) < Math.abs(best - index) ? candidate : best),
    null,
  );

  return nearest === null ? null : positionOn(rows[nearest], null, null);
}

/** Keeps focus on the same row after a re-render, on the row that hides it when it is hidden, else on the nearest visible row. */
export function reconcilePosition(
  rows:readonly NavigableRow[],
  previous:FocusPosition,
  previousIndex:number,
):FocusPosition|null {
  const index = rows.findIndex((row) => isSameRow(row, previous));
  const kept = rows[index];

  if (kept && !kept.hidden) {
    const cell = previous.cell === null || kept.cellCount === 0 ? null : Math.min(previous.cell, kept.cellCount - 1);
    return positionOn(kept, cell, previous.desiredColumn);
  }

  const owner = kept && rows.slice(0, index).reverse().find((row) => !row.hidden);
  return owner ? positionOn(owner, null, null) : nearestPosition(rows, previousIndex);
}
