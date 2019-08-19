import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {TableDragActionService} from "core-components/wp-table/drag-and-drop/actions/table-drag-action.service";
import {WorkPackageViewHierarchiesService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-hierarchy.service";
import {WorkPackageRelationsHierarchyService} from "core-components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service";
import {
  hierarchyGroupClass,
  hierarchyRootClass
} from "core-components/wp-fast-table/helpers/wp-table-hierarchy-helpers";

export class HierarchyDragActionService extends TableDragActionService {

  private wpTableHierarchies = this.injector.get(WorkPackageViewHierarchiesService);
  private relationHierarchyService = this.injector.get(WorkPackageRelationsHierarchyService);

  public get applies() {
    return this.wpTableHierarchies.isEnabled;
  }

  /**
   * Returns whether the given work package is movable
   */
  public canPickup(workPackage:WorkPackageResource):boolean {
    return !!workPackage.changeParent;
  }

  public handleDrop(workPackage:WorkPackageResource, el:HTMLElement):Promise<unknown> {
    const parentObject = this.determineParent(el);
    const newParent = parentObject ? parentObject.id : null;
    return this.relationHierarchyService.changeParent(workPackage, newParent);
  }

  /**
   * Find an applicable parent element from the hierarchy information in the table.
   * @param el
   */
  private determineParent(el:HTMLElement):{el:Element, id:string}|null {
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
