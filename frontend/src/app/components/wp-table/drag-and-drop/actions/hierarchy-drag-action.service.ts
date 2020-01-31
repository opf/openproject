import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {TableDragActionService} from "core-components/wp-table/drag-and-drop/actions/table-drag-action.service";
import {WorkPackageViewHierarchiesService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-hierarchy.service";
import {WorkPackageRelationsHierarchyService} from "core-components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service";
import {
  hierarchyGroupClass,
  hierarchyRootClass
} from "core-components/wp-fast-table/helpers/wp-table-hierarchy-helpers";
import {WorkPackageCacheService} from "core-components/work-packages/work-package-cache.service";
import {relationRowClass} from "core-components/wp-fast-table/helpers/wp-table-row-helpers";

export class HierarchyDragActionService extends TableDragActionService {

  private wpTableHierarchies = this.injector.get(WorkPackageViewHierarchiesService);
  private relationHierarchyService = this.injector.get(WorkPackageRelationsHierarchyService);
  private wpCacheService = this.injector.get(WorkPackageCacheService);

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
    return this.determineParent(el).then((parentId:string|null) => {
      return this.relationHierarchyService.changeParent(workPackage, parentId);
    });
  }

  /**
   * Find an applicable parent element from the hierarchy information in the table.
   * @param el
   */
  private determineParent(el:HTMLElement):Promise<string|null> {
    let previous = el.previousElementSibling;

    if (previous === null) {
      return Promise.resolve(null);
    }

    // If the previous element is a relation row,
    // skip it until we find the real previous sibling
    const isRelationRow = previous.className.indexOf(relationRowClass()) >= 0;
    if (isRelationRow) {
      let relationRoot = this.findRelationRowRoot(previous);
      if (relationRoot == null) {
        return Promise.resolve(null);
      }
      previous = relationRoot;
    }

    // When there is no hierarchy group at all, we're at a flat list
    const inGroup = previous.className.indexOf(hierarchyGroupClass('')) >= 0;
    const isRoot = previous.className.indexOf(hierarchyRootClass('')) >= 0;
    if (!(inGroup || isRoot)) {
      return Promise.resolve(null);
    }

    // If the sibling is a hierarchy root, return this one as new parent
    let previousWpId = (previous as HTMLElement).dataset.workPackageId!;
    if (previous.classList.contains(hierarchyRootClass(previousWpId))) {
      return Promise.resolve(previousWpId);
    }

    // If the sibling is no hierarchy root, return it's parent.
    // Thus, the dropped element will get the same hierarchy level as the sibling
    return this.loadParentOfWP(previousWpId);
  }

  private findRelationRowRoot(el:Element):Element|null {
    let previous = el.previousElementSibling;
    while (previous !== null) {
      if (previous.className.indexOf(relationRowClass()) < 0) {
        return previous;
      }
      previous = previous.previousElementSibling;
    }

    return null;
  }

  private loadParentOfWP(wpId:string):Promise<string|null> {
    return this.wpCacheService.require(wpId)
      .then((wp:WorkPackageResource) => {
        return Promise.resolve(wp.parent.id);
      });
  }
}
