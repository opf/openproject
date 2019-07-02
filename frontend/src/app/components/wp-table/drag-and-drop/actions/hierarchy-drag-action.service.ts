import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {TableDragActionService} from "core-components/wp-table/drag-and-drop/actions/table-drag-action.service";
import {WorkPackageTableHierarchiesService} from "core-components/wp-fast-table/state/wp-table-hierarchy.service";
import {WorkPackageRelationsHierarchyService} from "core-components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service";
import {
  hierarchyGroupClass,
  hierarchyRootClass
} from "core-components/wp-fast-table/helpers/wp-table-hierarchy-helpers";

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
    const parentObject = this.determineParent(el);
    const newParent = parentObject ? parentObject.id : null;
    return this.relationHierarchyService.changeParent(workPackage, newParent);
  }

  /**
   * Indent the shadow element according to the hierarchy level it would be dropped
   * @param shadowElement
   * @param backToDefault
   */
  public changeShadowElement(shadowElement:HTMLElement, backToDefault:boolean = false) {
    if (backToDefault) {
      // Overwrite the indentation back to the original value
      let hierarchyElement = jQuery(shadowElement).find('.wp-table--hierarchy-span')[0];
      hierarchyElement.style.width = hierarchyElement.dataset.indentation!;
      return true;
    }

    let parent = this.determineParent(shadowElement);
    let shadowElementHierarchySpan =  jQuery(shadowElement).find('.wp-table--hierarchy-span')[0];
    let shadowElementIndent:string;

    if (parent) {
      // When there is a parent, the shadow element is indented accordingly
      let parentHierarchySpan = jQuery(parent.el).find('.wp-table--hierarchy-span')[0] as HTMLElement;
      shadowElementIndent = parentHierarchySpan.offsetWidth + 20 + 'px';
    } else {
      // Otherwise the original indentation is applied
      shadowElementIndent = '25px';
    }

    shadowElementHierarchySpan.style.width = shadowElementIndent;
    return true;
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
