import { IsolatedQuerySpace } from "core-app/modules/work_packages/query-space/isolated-query-space";
import { WorkPackageResource } from "core-app/modules/hal/resources/work-package-resource";
import { Injector } from "@angular/core";

export class TableDragActionService {

  /**
   * Initialize an action service in the given isolated query space
   * @param querySpace The isolated query space for this table
   * @param injector The hierarchical injector for this table
   */
  constructor(readonly querySpace:IsolatedQuerySpace,
              readonly injector:Injector) {
  }

  /**
   * Determine whether the service applies for the given
   * query spaces.
   */
  public get applies():boolean {
    return true;
  }

  /**
   * Perform a post-order update
   */
  public onNewOrder(newOrder:string[]):void {
  }

  /**
   * Returns whether the given work package is movable
   */
  public canPickup(workPackage:WorkPackageResource):boolean {
    return true;
  }

  /**
   * Perform the respective action for the drop that just happened
   *
   * @param workPackage
   * @param target
   * @param source
   * @param sibling
   */
  public handleDrop(workPackage:WorkPackageResource, el:HTMLElement):Promise<unknown> {
    return Promise.resolve(undefined);
  }

  /**
   * Manipulate the shadow element
   * @param shadowElement
   * @param backToDefault: Shall the modifications be made undone
   */
  public changeShadowElement(shadowElement:HTMLElement, backToDefault = false) {
    if (backToDefault) {
      shadowElement.classList.remove('-dragged');
    } else {
      shadowElement.classList.add('-dragged');
    }
    return true;
  }
}
