import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {Injector} from "@angular/core";
import {
  hierarchyGroupClass,
  hierarchyRootClass
} from "core-components/wp-fast-table/helpers/wp-table-hierarchy-helpers";

export class TableDragActionService {

  /**
   * Initialize an action service in the given isolated query space
   * @param querySpace The isolated query space for this table
   * @param injector The hierarchical injector for this table
   */
  constructor(protected querySpace:IsolatedQuerySpace,
              protected injector:Injector) {
  }

  /**
   * Determine whether the service applies for the given
   * query spaces.
   */
  public get applies():boolean {
    return true;
  }

  /**
   * Returns whether the given work package is movable
   */
  public canPickup(workPackage:WorkPackageResource):boolean {
    return true;
  }

  /**
   *
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
   * Find an applicable parent element from the hierarchy information in the table.
   * @param el
   */
  public determineParent(el:HTMLElement):{el:Element, id:string}|null {
    let previous = el.previousElementSibling;

    while (previous !== null) {
      // When there is no hierarchy group at all, we're at a flat list
      const inGroup = previous.className.indexOf(hierarchyGroupClass('')) >= 0;
      const isRoot = previous.className.indexOf(hierarchyRootClass('')) >= 0;
      if (!(inGroup || isRoot)) {
        return null;
      }

      // If the sibling is a hierarchy root, return this one
      let wpId = (previous as HTMLElement).dataset.workPackageId!;
      if (previous.classList.contains(hierarchyRootClass(wpId))) {
        return {el: previous, id: wpId};
      }

      previous = previous.previousElementSibling;
    }

    return null;
  }
}
