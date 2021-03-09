import { debugLog, timeOutput } from "core-app/helpers/debug_output";
import { QueryOrder } from "core-app/modules/apiv3/endpoints/queries/apiv3-query-order";

// min allowed position
export const MIN_ORDER = -2147483647;
// max postgres 4-byte integer position
export const MAX_ORDER = 2147483647;
// default position to insert
export const DEFAULT_ORDER = 0;
// The distance to keep between each element
export const ORDER_DISTANCE = 16384;

/**
 * Computes the delta of positions for a given
 * operation and order
 */
export class ReorderDeltaBuilder {

  // We are building a delta of positions we need to update
  // ideally this will only be one, but more may need to be set (initially)
  // or shifted in case of spacing issues
  private delta:QueryOrder = {};

  /**
   * Create a delta builder
   *
   * @param order The current order of work packages that contains the user movement
   * @param positions The current positions as loaded from backend / persisted from previous calls
   * @param wpId The work package that got moved
   * @param index The index a work package got moved into
   * @param fromIndex If moved within the order, the previous index used for movement optimzation
   */
  constructor(readonly order:string[],
              readonly positions:QueryOrder,
              readonly wpId:string,
              readonly index:number,
              readonly fromIndex:number|null) {
  }

  public buildDelta():QueryOrder {
    timeOutput(`Building delta for ${this.wpId}@${this.index}`, () => {

      // Ensure positions are strictly ascending. There may be cases were this does not happen
      // e.g., having a flat sorted list and turning on hierarchy mode
      if (!this.isAscendingOrder()) {
        this.rebuildPositions();
      } else {
        // Insert only the new element
        this.buildInsertPosition();
      }
    });

    debugLog("Order DELTA was built as %O", this.delta);

    return this.delta;
  }


  /**
   * Ensure +order+ is already ascending with the exception of +index+,
   * or otherwise reorder the positions starting from the first element.
   */
  private isAscendingOrder() {
    let current:number|undefined;

    for (let i = 0, l = this.order.length; i < l; i++) {
      const id = this.order[i];
      const position = this.positions[id];

      // Skip our insertion point
      if (i === this.index) {
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
   * Reassign mixed positions so that they are strictly ascending again,
   * but try to keep relative positions alive
   */
  private rebuildPositions() {
    const [min, max] = this.minMaxPositions;
    this.redistribute(min, max);
  }

  /**
   * Insert +wpId+ at +index+ in a position that is determined either
   * by its neighbors, one of them in case both do not yet have a position
   */
  private buildInsertPosition() {
    // Special case, order is empty or only contains wpId
    // Then simply insert as the default position unless it already has a position
    if (this.order.length <= 1 && this.positions[this.wpId] === undefined) {
      this.delta[this.wpId] = DEFAULT_ORDER;
      return;
    }

    // Special case, shifted movement by one
    if (this.fromIndex !== null && Math.abs(this.fromIndex - this.index) === 1 && this.positionSwap()) {
      return;
    }

    // Special case, index is 0
    if (this.index === 0) {
      return this.insertAsFirst();
    }

    // Ensure previous positions exist so we can insert wpId @ index
    const predecessorPosition = this.buildUpPredecessorPosition();

    // Ensure we reorder when predecessor is at max already
    if (predecessorPosition >= MAX_ORDER) {
      debugLog(`Predecessor position is at max order, need to reorder`);
      return this.reorderedInsert();
    }

    // Get the actual successor position, it might vary wildly from the optimal position
    const successorPosition = this.positionFor(this.index + 1);

    if (successorPosition === undefined) {
      // Successor does not have a position yet (is NULL), any position will work
      // so let's use the optimal one which is halfway to a potential successor
      this.delta[this.wpId] = predecessorPosition + (ORDER_DISTANCE / 2);
      return;
    }

    // Ensure we reorder when successor is at max already
    if (successorPosition >= MAX_ORDER) {
      debugLog(`Successor position is at max order, need to reorder`);
      return this.reorderedInsert();
    }

    // successor exists and has a position
    // We will want to insert at the half way from predecessorPosition ... successorPosition
    const distance = Math.floor((successorPosition - predecessorPosition) / 2);

    // If there is no space to insert, we're going to optimize the available space
    if (distance < 1) {
      debugLog("Cannot insert at optimal position, no space left. Need to reorder");
      return this.reorderedInsert();
    }

    this.delta[this.wpId] = predecessorPosition + distance;
  }

  /**
   * Insert wpId as the first element
   */
  private insertAsFirst() {
    // Get the actual successor position, it might vary wildly from the optimal position
    const successorPosition = this.positionFor(this.index + 1);

    // If the successor also has no position yet, simply assign the default
    if (successorPosition === undefined) {
      this.delta[this.wpId] = DEFAULT_ORDER;
    } else {
      this.delta[this.wpId] = successorPosition - (ORDER_DISTANCE / 2);
    }
  }

  /**
   * Since from and to index or only one apart,
   * we can swap the positions.
   */
  private positionSwap():boolean {
    const myPosition = this.positionFor(this.index!);
    const neighbor = this.order[this.fromIndex!];
    const neighborPosition = this.positionFor(this.fromIndex!);

    // If either the neighbor or wpid have no position yet,
    // go through the regular update flow
    if (myPosition === undefined || neighborPosition === undefined) {
      return false;
    }

    // Simply swap the two positions
    this.delta[this.wpId] = neighborPosition;
    this.delta[neighbor] = myPosition;

    return true;
  }


  /**
   * Builds any previous unset position from 0 .. index
   * so we can properly insert the wpId @ index.
   */
  private buildUpPredecessorPosition() {
    let predecessorPosition:number = DEFAULT_ORDER - ORDER_DISTANCE;

    for (let i = 0; i < this.index; i++) {
      const id = this.order[i];
      const position = this.positions[id];

      // If this current ID has no position yet, assign the current one
      if (position === undefined) {
        predecessorPosition = this.delta[id] = predecessorPosition + ORDER_DISTANCE;
      } else {
        predecessorPosition = position;
      }
    }

    return predecessorPosition;
  }

  /**
   * Return the position number for the given index
   */
  private positionFor(index:number):number|undefined {
    const wpId = this.order[index];
    return this.livePosition(wpId);
  }

  /**
   * Return either the delta position or the previous persisted position,
   * in that order.
   *
   * @param wpId
   */
  private livePosition(wpId:string):number|undefined {
    // Explicitly check for undefined here as the delta might be 0 which is falsey.
    return this.delta[wpId] === undefined ? this.positions[wpId] : this.delta[wpId];
  }

  /**
   * There was no space left at the desired insert position,
   * we're going to evenly distribute all items again
   */
  private reorderedInsert() {
    // Get the current distance between orders
    // Both must be set by now due to +buildUpPredecessorPosition+ having run.
    const min = this.firstPosition!;
    const max = this.lastPosition!;

    this.redistribute(min, max);
  }

  /**
   * Distribute the items over a given min/max
   */
  private redistribute(min:number, max:number) {
    const itemsToDistribute = this.order.length;

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
        throw "Elements cannot be moved further and no space is left. Too many elements";
      }

      // Rebuild space
      space = Math.floor((max - min) / (itemsToDistribute - 1));
    }

    // Assign positions for all values in between min/max
    for (let i = 0; i < itemsToDistribute; i++) {
      const wpId = this.order[i];
      this.delta[wpId] = min + (i * space);
    }
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
  private get minMaxPositions():[number, number] {
    let min:number = MAX_ORDER;
    let max:number = MIN_ORDER;
    let any = false;

    for (let i = this.order.length - 1; i >= 0; i--) {
      const wpId = this.order[i];
      const position = this.livePosition(wpId);

      if (position !== undefined) {
        min = Math.min(position, min);
        max = Math.max(position, max);
        any = true;
      }
    }

    if (any && min !== max) {
      return [min, max];
    } else {
      return [DEFAULT_ORDER, this.order.length * ORDER_DISTANCE];
    }
  }


  /**
   * Returns the minimal position assigned currently
   */
  private get firstPosition():number {
    const wpId = this.order[0]!;
    return this.livePosition(wpId)!;
  }

  /**
   * Returns the maximum position assigned currently.
   * Note that a list can be unpositioned at the beginning, so this may return undefined
   */
  private get lastPosition():number|undefined {
    for (let i = this.order.length - 1; i >= 0; i--) {
      const wpId = this.order[i];
      const position = this.livePosition(wpId);

      // Return the first set position.
      if (position !== undefined) {
        return position;
      }
    }

    return;
  }
}
