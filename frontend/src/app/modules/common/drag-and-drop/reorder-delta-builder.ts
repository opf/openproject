import {QueryOrder} from "core-app/modules/hal/dm-services/query-order-dm.service";
import {debugLog, timeOutput} from "core-app/helpers/debug_output";

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
    timeOutput("Building delta", () => this.buildInsertPosition());

    debugLog("Order DELTA was built as %O", this.delta);

    return this.delta;
  }

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

    // Get the actual successor position, it might vary wildly from the optimal position
    const successorPosition = this.positionFor(this.index + 1);

    if (successorPosition === undefined) {
      // Successor does not have a position yet (is NULL), any position will work
      // so let's use the optimal one.
      this.delta[this.wpId] = predecessorPosition + (ORDER_DISTANCE / 2);
      return;
    }

    // successor exists and has a position
    // We will want to insert at the half way from predecessorPosition ... successorPosition
    const distance = Math.floor((successorPosition - predecessorPosition) / 2);

    // If there is no space to insert, we're going to optimize the available space
    if (distance < 1) {
      debugLog("Cannot insert at optimal position, no space left. Need to reorder");
      return this.reorderedInsert();
    }

    const optimal = predecessorPosition + distance;
    this.delta[this.wpId] = optimal;
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
    return this.delta[wpId] || this.positions[wpId];
  }

  /**
   * There was no space left at the desired insert position,
   * we're going to evenly distribute all items again
   */
  private reorderedInsert() {
    const itemsToDistribute = this.order.length;

    // Get the current distance between orders
    // Both must be set by now due to +buildUpPredecessorPosition+ having run.
    let min = this.minPosition!;
    let max = this.maxPosition!;

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
    for (let i = 1; i < itemsToDistribute; i++) {
      const wpId = this.order[i];

      // If we reached a point where the position is undefined
      // and larger than our point of insertion, we can keep them this way
      if (i > this.index && this.livePosition(wpId) === undefined) {
        return;
      }

      this.delta[wpId] = min + (i * space);
    }
  }

  /**
   * Returns the minimal position assigned currently
   */
  private get minPosition():number|undefined {
    const wpId = this.order[0]!;
    return this.livePosition(wpId);
  }

  /**
   * Returns the maximum position assigned currently.
   * Note that a list can be unpositioned at the beginning, so this may return undefined
   */
  private get maxPosition():number|undefined {
    for (let i = this.order.length - 1; i >= 0; i--) {
      let position = this.livePosition(this.order[i]);

      // Return the first set position.
      if (position !== undefined) {
        return position;
      }
    }

    return;
  }
}
