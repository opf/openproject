import {Inject, Injectable, Injector} from "@angular/core";
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {debugLog} from "core-app/helpers/debug_output";
import {States} from "core-components/states.service";
import {WorkPackageFilterValues} from "core-components/wp-edit-form/work-package-filter-values";
import {IWorkPackageEditingServiceToken} from "core-components/wp-edit-form/work-package-editing.service.interface";
import {WorkPackageEditingService} from "core-components/wp-edit-form/work-package-editing-service";
import {WorkPackageNotificationService} from "core-components/wp-edit/wp-notification.service";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";

@Injectable()
export class ReorderQueryService {

  constructor(readonly states:States,
              readonly pathHelper:PathHelperService,
              readonly injector:Injector,
              @Inject(IWorkPackageEditingServiceToken) protected readonly wpEditing:WorkPackageEditingService,
              readonly wpNotifications:WorkPackageNotificationService) {
  }

  /**
   * Move an item in the list
   */
  public move(querySpace:IsolatedQuerySpace, wpId:string, toIndex:number):Promise<QueryResource|void> {
    const order = this.getCurrentOrder(querySpace);

    // Find index of the work package
    let fromIndex = order.findIndex((id) => id === wpId);

    order.splice(fromIndex, 1);
    order.splice(toIndex, 0, wpId);

    return this.updateQuery(querySpace.query.value, order);
  }

  /**
   * Pull an item from the rendered list
   */
  public remove(querySpace:IsolatedQuerySpace, wpId:string):Promise<QueryResource|void> {
    const order = this.getCurrentOrder(querySpace);
    _.remove(order, id => id === wpId);

    return this.updateQuery(querySpace.query.value, order);
  }

  /**
   * Add an item to the list
   * @param querySpace
   * @param toIndex index to add to or -1 to push to the end.
   */
  public async add(querySpace:IsolatedQuerySpace, wpId:string, toIndex:number = -1) {
    const order = this.getCurrentOrder(querySpace);

    if (toIndex === -1) {
      order.push(wpId);
    } else {
      order.splice(toIndex, 0, wpId);
    }

    return this.updateQuery(querySpace.query.value, order);
  }

  public updateWorkPackage(querySpace:IsolatedQuerySpace, workPackage:WorkPackageResource) {
    let query = querySpace.query.value;

    if (query) {
      const changeset = this.wpEditing.changesetFor(workPackage);
      const filter = new WorkPackageFilterValues(this.injector, changeset, query.filters);
      filter.applyDefaultsFromFilters();

      return changeset
        .save();
    }

    return Promise.resolve();
  }

  protected getCurrentOrder(querySpace:IsolatedQuerySpace):string[] {
    return querySpace
      .renderedWorkPackages
      .mapOr((rows) => rows.map(row => row.workPackageId!.toString()), []);
  }

  private updateQuery(query:QueryResource|undefined, orderedIds:string[]):Promise<QueryResource|void> {
    if (query && !!query.updateImmediately) {
      const orderedWorkPackages = orderedIds
        .map(id => this.pathHelper.api.v3.work_packages.id(id).toString());

      debugLog("New order: " + orderedIds.join(", "));

      return query.updateImmediately({orderedWorkPackages: orderedWorkPackages});
    } else {
      return Promise.reject("Query not writable");
    }
  }
}
