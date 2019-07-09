import {QueryOrder} from "core-app/modules/hal/dm-services/query-order-dm.service";

// min allowed position
export const MIN_ORDER = -2147483647;
// max postgres 4-byte integer position
export const MAX_ORDER = 2147483647;
// default position to insert
export const DEFAULT_ORDER = 0;
// The distance to keep between each element
export const ORDER_DISTANCE = 1000;

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
    this.buildInsertPosition();
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
    if (this.fromIndex && Math.abs(this.fromIndex - this.index) === 1 && this.positionSwap()) {
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
      this.delta[this.wpId] = predecessorPosition + ORDER_DISTANCE;
      return;
    }

    // successor exists and has a position
    // We will want to insert at the half way from predecessorPosition ... successorPosition
    const distance = Math.floor((successorPosition - predecessorPosition) / 2);

    // TODO: shifting when optimal becomes too small
    if (distance < 1) {
      throw "Cannot insert at optimal position, no space left. Need to compress predecessors";
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
    const myPosition = this.positionFor(this.index!)
    const neighbor = this.order[this.fromIndex!];
    const neighborPosition = this.positionFor(this.fromIndex!)

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
    return this.positions[wpId];
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
}
