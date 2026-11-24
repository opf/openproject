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

import { debugLog } from 'core-app/shared/helpers/debug_output';
import { QueryOrder } from 'core-app/core/apiv3/endpoints/queries/apiv3-query-order';

// min allowed position
export const MIN_ORDER = -2147483647;
// max postgres 4-byte integer position
export const MAX_ORDER = 2147483647;
// default position to insert
export const DEFAULT_ORDER = 0;
// The distance to keep between each element
export const ORDER_DISTANCE = 16384;

/**
 * Return either the delta position or the previous persisted position,
 * in that order.
 *
 * @param wpId
 */
function livePosition(
  delta:QueryOrder,
  positions:QueryOrder,
  wpId:string,
):number|undefined {
  // Explicitly check for undefined here as the delta might be 0 which is falsey.
  return delta[wpId] === undefined ? positions[wpId] : delta[wpId];
}

/**
 * Return the position number for the given index
 */
function positionFor(
  delta:QueryOrder,
  order:string[],
  positions:QueryOrder,
  index:number,
):number|undefined {
  const wpId = order[index];
  return livePosition(delta, positions, wpId);
}

/**
 * Ensure +order+ is already ascending with the exception of +index+,
 * or otherwise reorder the positions starting from the first element.
 */
function isAscendingOrder(
  order:string[],
  positions:QueryOrder,
  index:number,
):boolean {
  let current:number|undefined;

  for (let i = 0, l = order.length; i < l; i += 1) {
    const id = order[i];
    const position = positions[id];

    // Skip our insertion point
    if (i === index) {
      continue;
    }

    // If neither position is set
    if (current === undefined || position === undefined) {
      current = position;
      continue;
    }

    // If the next position is not larger, rebuild positions
    if (position < current) {
      return false;
    }
  }

  return true;
}

/**
 * Since from and to index or only one apart,
 * we can swap the positions.
 *
 * TODO: This should not modify in-place and then return an unrelated value
 */
function positionSwap(
  delta:QueryOrder,
  order:string[],
  positions:QueryOrder,
  index:number,
  fromIndex:number|null,
  wpId:string,
):QueryOrder {
  if (fromIndex === null) {
    return delta;
  }

  const myPosition = positionFor(delta, order, positions, index);
  const neighbor = order[fromIndex];
  const neighborPosition = positionFor(delta, order, positions, fromIndex);

  // If either the neighbor or wpid have no position yet,
  // go through the regular update flow
  if (myPosition === undefined || neighborPosition === undefined) {
    return delta;
  }

  return {
    ...delta,
    [`${wpId}`]: neighborPosition,
    [`${neighbor}`]: myPosition,
  };
}

/**
 * Insert wpId as the first element
 */
function insertAsFirst(
  delta:QueryOrder,
  order:string[],
  positions:QueryOrder,
  index:number,
  wpId:string,
) {
  // Get the actual successor position, it might vary wildly from the optimal position
  const successorPosition = positionFor(delta, order, positions, index + 1);

  // If the successor also has no position yet, simply assign the default
  if (successorPosition === undefined) {
    return {
      ...delta,
      [wpId]: DEFAULT_ORDER,
    };
  }
  return {
    ...delta,
    [wpId]: successorPosition - (ORDER_DISTANCE / 2),
  };
}

/**
 * Builds any previous unset position from 0 .. index
 * so we can properly insert the wpId @ index.
 */
function buildUpPredecessorPosition(
  delta:QueryOrder,
  order:string[],
  positions:QueryOrder,
  index:number,
) {
  let predecessorPosition:number = DEFAULT_ORDER - ORDER_DISTANCE;
  const newDelta = { ...delta };
  for (let i = 0; i < index; i += 1) {
    const id = order[i];
    const position = positions[id];

    // If this current ID has no position yet, assign the current one
    if (position === undefined) {
      newDelta[id] = predecessorPosition + ORDER_DISTANCE;
      predecessorPosition = newDelta[id];
    } else {
      predecessorPosition = position;
    }
  }

  return {
    predecessorPosition,
    delta: newDelta,
  };
}

/**
 * Returns the minimal position assigned currently
 */
function firstPosition(
  delta:QueryOrder,
  order:string[],
  positions:QueryOrder,
):number {
  const wpId = order[0] || '';
  return livePosition(delta, positions, wpId) || 0;
}

/**
 * Returns the maximum position assigned currently.
 * Note that a list can be unpositioned at the beginning, so this may return undefined
 */
function lastPosition(
  delta:QueryOrder,
  order:string[],
  positions:QueryOrder,
):number {
  for (let i = order.length - 1; i >= 0; i -= 1) {
    const wpId = order[i];
    const position = livePosition(delta, positions, wpId);

    // Return the first set position.
    if (position !== undefined) {
      return position;
    }
  }

  return 0;
}

/**
 * Distribute the items over a given min/max
 */
function redistribute(
  delta:QueryOrder,
  order:string[],
  minIndex:number,
  maxIndex:number,
) {
  const itemsToDistribute = order.length;

  let min = minIndex;
  let max = maxIndex;

  // We can keep min and max orders if distance/(items to distribute) >= 1
  let space = Math.floor((max - min) / (itemsToDistribute - 1));

  // If no space is left, first try to add to the max item
  // Or subtract from the min item
  if (space < 1) {
    if ((max + itemsToDistribute) <= MAX_ORDER) {
      max += itemsToDistribute;
    } else if ((min - itemsToDistribute) >= MIN_ORDER) {
      min -= itemsToDistribute;
    } else {
      // This should not happen in a 4-byte integer with our frontend
      throw new Error('Elements cannot be moved further and no space is left. Too many elements');
    }

    // Rebuild space
    space = Math.floor((max - min) / (itemsToDistribute - 1));
  }

  // Assign positions for all values in between min/max
  const newDelta = { ...delta };
  for (let i = 0; i < itemsToDistribute; i += 1) {
    const wpId = order[i];
    newDelta[wpId] = min + (i * space);
  }

  return newDelta;
}

/**
 * There was no space left at the desired insert position,
 * we're going to evenly distribute all items again
 */
function reorderedInsert(
  delta:QueryOrder,
  order:string[],
  positions:QueryOrder,
) {
  // Get the current distance between orders
  // Both must be set by now due to +buildUpPredecessorPosition+ having run.
  const min = firstPosition(delta, order, positions);
  const max = lastPosition(delta, order, positions);

  return redistribute(delta, order, min, max);
}

/**
 * Insert +wpId+ at +index+ in a position that is determined either
 * by its neighbors, one of them in case both do not yet have a position
 */
function buildInsertPosition(
  order:string[],
  positions:QueryOrder,
  wpId:string,
  index:number,
  fromIndex:number|null,
):QueryOrder {
  const delta = {};
  // Special case, order is empty or only contains wpId
  // Then simply insert as the default position unless it already has a position
  if (order.length <= 1 && positions[wpId] === undefined) {
    return {
      ...delta,
      [wpId]: DEFAULT_ORDER,
    };
  }

  // Special case, shifted movement by one
  const newDelta = positionSwap(delta, order, positions, index, fromIndex, wpId);
  if (fromIndex !== null
    && Math.abs(fromIndex - index) === 1
    && delta !== newDelta
  ) {
    return newDelta;
  }

  // Special case, index is 0
  if (index === 0) {
    return insertAsFirst(newDelta, order, positions, index, wpId);
  }

  // Ensure previous positions exist so we can insert wpId @ index
  const { delta: rebuiltDelta, predecessorPosition } = buildUpPredecessorPosition(newDelta, order, positions, index);

  // Ensure we reorder when predecessor is at max already
  if (predecessorPosition >= MAX_ORDER) {
    debugLog('Predecessor position is at max order, need to reorder');
    return reorderedInsert(rebuiltDelta, order, positions);
  }

  // Get the actual successor position, it might vary wildly from the optimal position
  const successorPosition = positionFor(rebuiltDelta, order, positions, index + 1);

  if (successorPosition === undefined) {
    // Successor does not have a position yet (is NULL), any position will work
    // so let's use the optimal one which is halfway to a potential successor
    return {
      ...rebuiltDelta,
      [wpId]: predecessorPosition + (ORDER_DISTANCE / 2),
    };
  }

  // Ensure we reorder when successor is at max already
  if (successorPosition >= MAX_ORDER) {
    debugLog('Successor position is at max order, need to reorder');
    return reorderedInsert(rebuiltDelta, order, positions);
  }

  // successor exists and has a position
  // We will want to insert at the half way from predecessorPosition ... successorPosition
  const distance = Math.floor((successorPosition - predecessorPosition) / 2);

  // If there is no space to insert, we're going to optimize the available space
  if (distance < 1) {
    debugLog('Cannot insert at optimal position, no space left. Need to reorder');
    return reorderedInsert(rebuiltDelta, order, positions);
  }

  return {
    ...rebuiltDelta,
    [wpId]: predecessorPosition + distance,
  };
}

/**
 * Get the absolute minimum and maximum positions
 * currently assigned in the slot.
 *
 * If there is at least two positions assigned, returns the maximum
 * between them.
 *
 * Otherwise, returns the optimum min max for the given order length.
 */
function minMaxPositions(
  delta:QueryOrder,
  order:string[],
  positions:QueryOrder,
):[number, number] {
  let min:number = MAX_ORDER;
  let max:number = MIN_ORDER;
  let any = false;

  for (let i = order.length - 1; i >= 0; i -= 1) {
    const wpId = order[i];
    const position = livePosition(delta, positions, wpId);

    if (position !== undefined) {
      min = Math.min(position, min);
      max = Math.max(position, max);
      any = true;
    }
  }

  if (any && min !== max) {
    return [min, max];
  }
  return [DEFAULT_ORDER, order.length * ORDER_DISTANCE];
}

/**
 * Reassign mixed positions so that they are strictly ascending again,
 * but try to keep relative positions alive
 */
function rebuildPositions(
  order:string[],
  positions:QueryOrder,
) {
  const delta:QueryOrder = {};
  const [min, max] = minMaxPositions(delta, order, positions);
  return redistribute(delta, order, min, max);
}

/**
 * Build a delta
 * Computes the delta of positions for a given operation and order
 *
 * @param order The current order of work packages that contains the user movement
 * @param positions The current positions as loaded from backend / persisted from previous calls
 * @param wpId The work package that got moved
 * @param index The index a work package got moved into
 * @param fromIndex If moved within the order, the previous index used for movement optimization
 */
export function buildDelta(
  order:string[],
  positions:QueryOrder,
  wpId:string,
  index:number,
  fromIndex:number|null,
):QueryOrder {
  if (!isAscendingOrder(order, positions, index)) {
    return rebuildPositions(order, positions);
  }

  // Insert only the new element
  return buildInsertPosition(order, positions, wpId, index, fromIndex);
}

/**
 * Ranks the work packages in `order` so that sorting by position, then by
 * numeric ID, reproduces their order. Every other result keeps its rank.
 */
export function buildOrderDelta(order:readonly string[], cached:QueryOrder):QueryOrder {
  const positions = withoutDeletions(cached);
  const peers = new Set(order);
  const ranked = Object.keys(positions).sort((a, b) => positions[a] - positions[b] || Number(a) - Number(b));
  const lastPeer = ranked.reduce((last, id, index) => (peers.has(id) ? index : last), -1);
  const unrankedAt = lastPeer === -1 ? ranked.length : lastPeer + 1;
  const unranked = order.filter((id) => positions[id] === undefined);
  const ids = [...ranked.slice(0, unrankedAt), ...unranked, ...ranked.slice(unrankedAt)];

  let nextPeer = 0;
  let lastRank = DEFAULT_ORDER - ORDER_DISTANCE;
  const slots = ids.map((id) => {
    const rank = positions[id] ?? Math.min(lastRank + ORDER_DISTANCE, MAX_ORDER);
    lastRank = rank;
    return { id: peers.has(id) ? order[nextPeer++] : id, rank };
  });

  // Manual queries break position ties by numeric ID. Keep every other
  // result in its slot, including rows beyond the displayed page.
  for (let i = slots.length - 2; i >= 0; i--) {
    const slot = slots[i];
    const next = slots[i + 1];
    const limit = Number(slot.id) < Number(next.id) ? next.rank : next.rank - 1;
    slot.rank = Math.min(slot.rank, limit);
    if (slot.rank === -1) slot.rank--; // The API reserves -1 for deletion.
  }

  // A tied run at the minimum integer can only make room to its right.
  let floor = MIN_ORDER;
  const delta:QueryOrder = {};
  for (const [i, slot] of slots.entries()) {
    const rank = Math.max(floor, slot.rank);
    slot.rank = rank === -1 ? 0 : rank;
    if (positions[slot.id] !== slot.rank) delta[slot.id] = slot.rank;
    const next = slots[i + 1];
    if (next) floor = Number(slot.id) < Number(next.id) ? slot.rank : slot.rank + 1;
  }
  return delta;
}

// A cached -1 is a deletion still waiting for the next reload.
function withoutDeletions(positions:QueryOrder):QueryOrder {
  return Object.fromEntries(Object.entries(positions).filter(([, position]) => position !== -1));
}

function inRange(delta:QueryOrder):boolean {
  return Object.values(delta).every((position) => position >= MIN_ORDER && position <= MAX_ORDER);
}

function sortRank(positions:QueryOrder, id:string):number {
  return positions[id] ?? MAX_ORDER + 1;
}

function sortsBefore(positions:QueryOrder, a:string, b:string):boolean {
  const rankDifference = sortRank(positions, a) - sortRank(positions, b);
  return rankDifference < 0 || (rankDifference === 0 && Number(a) < Number(b));
}

function reloadsInOrder(order:readonly string[], positions:QueryOrder):boolean {
  return order.every((id, index) => {
    if (positions[id] === -1) return false;
    return index === 0 || sortsBefore(positions, order[index - 1], id);
  });
}

/**
 * Results beyond the displayed rows must stay on their side of them. Results
 * that sorted between the displayed rows, e.g. ones that no longer match the
 * filters, may land anywhere among them.
 */
function keepsOthersOutside(order:readonly string[], positions:QueryOrder, updated:QueryOrder):boolean {
  const peers = new Set(order);
  const span = [...peers]
    .filter((id) => positions[id] !== undefined)
    .sort((a, b) => (sortsBefore(positions, a, b) ? -1 : 1));
  const others = Object.keys(positions).filter((id) => !peers.has(id));
  if (!span.length) return others.every((id) => sortsBefore(updated, id, order[0]));
  const first = span[0];
  const last = span[span.length - 1];
  return others.every((id) => {
    if (sortsBefore(positions, id, first)) return sortsBefore(updated, id, order[0]);
    if (sortsBefore(positions, last, id)) return sortsBefore(updated, order[order.length - 1], id);
    return true;
  });
}

/**
 * Moves one work package with a single new position where its neighbors allow
 * it. Where tied positions would sort it back after a reload, past results
 * beyond the displayed rows, or out of the integer range, ranks the whole
 * order instead.
 */
export function buildMoveDelta(
  order:readonly string[],
  cached:QueryOrder,
  wpId:string,
  index:number,
  fromIndex:number|null,
):QueryOrder {
  const positions = withoutDeletions(cached);
  const delta = buildDelta([...order], positions, wpId, index, fromIndex);
  const updated = { ...positions, ...delta };
  return inRange(delta) && reloadsInOrder(order, updated) && keepsOthersOutside(order, positions, updated)
    ? delta
    : buildOrderDelta(order, positions);
}
