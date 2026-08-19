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
 * @param fromIndex If moved within the order, the previous index used for movement optimzation
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
