import {Injectable} from "@angular/core";
import {TableState} from "core-components/wp-table/table-state/table-state";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";

@Injectable()
export class ReorderQueryService {

  constructor(readonly pathHelper:PathHelperService) {
  }

  /**
   * Move an item in the list
   */
  public move(tableState:TableState, wpId:string, toIndex:number):Promise<QueryResource|void> {
    const order = this.getCurrentOrder(tableState);

    // Find index of the work package
    let fromIndex = order.findIndex((id) => id === wpId);

    order.splice(fromIndex, 1);
    order.splice(toIndex, 0, wpId);

    return this.updateQuery(tableState.query.value, order);
  }

  /**
   * Pull an item from the rendered list
   */
  public remove(tableState:TableState, wpId:string):Promise<QueryResource|void> {
    const order = this.getCurrentOrder(tableState);
    _.remove(order, id => id === wpId);

    return this.updateQuery(tableState.query.value, order);
  }

  /**
   * Add an item to the list
   * @param tableState
   * @param toIndex index to add to or -1 to push to the end.
   */
  public add(tableState:TableState, wpId:string, toIndex:number = -1) {
    const order = this.getCurrentOrder(tableState);

    if (toIndex === -1) {
      order.push(wpId);
    } else {
      order.splice(toIndex, 0, wpId);
    }

    return this.updateQuery(tableState.query.value, order);
  }

  protected getCurrentOrder(tableState:TableState):string[] {
    return tableState
      .renderedWorkPackages
      .mapOr((rows) => rows.map(row => row.workPackageId!.toString()), []);
  }

  private updateQuery(query:QueryResource|undefined, orderedIds:string[]):Promise<QueryResource|void> {
    if (query && !!query.updateImmediately) {
      const orderedWorkPackages = orderedIds
        .map(id => this.pathHelper.api.v3.work_packages.id(id).toString());

      return query.updateImmediately({orderedWorkPackages: orderedWorkPackages});
    } else {
      return Promise.reject("Query not writable");
    }
  }
}
