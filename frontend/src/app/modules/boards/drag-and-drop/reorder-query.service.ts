import {Injectable} from "@angular/core";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {debugLog} from "core-app/helpers/debug_output";
import {States} from "core-components/states.service";
import {WorkPackageNotificationService} from "core-components/wp-edit/wp-notification.service";
import {Observable, throwError} from "rxjs";
import {QueryDmService} from "core-app/modules/hal/dm-services/query-dm.service";

@Injectable()
export class ReorderQueryService {

  constructor(readonly states:States,
              readonly pathHelper:PathHelperService,
              readonly queryDm:QueryDmService,
              readonly wpNotifications:WorkPackageNotificationService) {
  }

  /**
   * Move an item in the list
   */
  public move(order:string[], wpId:string, toIndex:number):string[] {
    // Find index of the work package
    let fromIndex = order.findIndex((id) => id === wpId);

    order.splice(fromIndex, 1);
    order.splice(toIndex, 0, wpId);

    return order;
  }

  /**
   * Pull an item from the rendered list
   */
  public remove(order:string[], wpId:string):string[] {
    _.remove(order, id => id === wpId);
    return order;
  }

  /**
   * Add an item to the list
   * @param querySpace
   * @param toIndex index to add to or -1 to push to the end.
   */
  public add(order:string[], wpId:string, toIndex:number = -1):string[] {
    if (toIndex === -1) {
      order.push(wpId);
    } else {
      order.splice(toIndex, 0, wpId);
    }

    return order;
  }

  public saveOrderInQuery(query:QueryResource|undefined, orderedIds:string[]):Observable<unknown> {
    if (query && !!query.updateImmediately) {
      const orderedWorkPackages = orderedIds
        .map(id => this.pathHelper.api.v3.work_packages.id(id).toString());

      debugLog("New order: " + orderedIds.join(", "));

      return this.queryDm.patch(query.id!, {orderedWorkPackages: orderedWorkPackages});
    } else {
      return throwError("Query not writable");
    }
  }
}
