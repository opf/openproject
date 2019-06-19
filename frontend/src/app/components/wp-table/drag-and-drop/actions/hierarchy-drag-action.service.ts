import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {TableDragActionService} from "core-components/wp-table/drag-and-drop/actions/table-drag-action.service";
import {WorkPackageTableHierarchiesService} from "core-components/wp-fast-table/state/wp-table-hierarchy.service";
import {WorkPackageRelationsHierarchyService} from "core-components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service";

export class HierarchyDragActionService extends TableDragActionService {

  private wpTableHierarchies = this.injector.get(WorkPackageTableHierarchiesService);
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
    const newParent = this.determineParent(el)!.id;
    return this.relationHierarchyService.changeParent(workPackage, newParent);
  }
}
