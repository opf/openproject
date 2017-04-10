import {injectorBridge} from "../../../angular/angular-injector-bridge.functions";
import {States} from "../../../states.service";
import {indicatorCollapsedClass} from "../../builders/rows/hierarchy-rows-builder";
import {collapsedGroupClass, hierarchyGroupClass, hierarchyRootClass} from "../../helpers/wp-table-hierarchy-helpers";
import {WorkPackageTableHierarchyService} from "../../state/wp-table-hierarchy.service";
import {WorkPackageTable} from "../../wp-fast-table";
import {WPTableHierarchyState} from "../../wp-table.interfaces";

export class HierarchyTransformer {
  public wpTableHierarchy:WorkPackageTableHierarchyService;
  public states:States;

  constructor(table:WorkPackageTable) {
    injectorBridge(this);
    let enabled = false;

    this.wpTableHierarchy.hierarchyState.values$()
      .takeUntil(this.states.table.stopAllSubscriptions)
      .subscribe((state: WPTableHierarchyState) => {
        if (enabled !== state.enabled) {
          table.refreshBody();
          table.postRender();
        } else if (enabled) {
          // No change in hierarchy mode
          // Refresh groups
          this.renderHierarchyState(state);
        }

        enabled = state.enabled;
      });
  }

  /**
   * Update all currently visible rows to match the selection state.
   */
  private renderHierarchyState(state:WPTableHierarchyState) {
   // Show all hierarchies
   jQuery('[class^="__hierarchy-group-"]').removeClass((i:number, classNames:string):string => {
    return (classNames.match(/__collapsed-group-\d+/g) || []).join(' ');
   });

   // Hide all collapsed hierarchies
   _.each(state.collapsed, (isCollapsed:boolean, wpId:string) => {
     // Hide/Show the descendants.
     jQuery(`.${hierarchyGroupClass(wpId)}`).toggleClass(collapsedGroupClass(wpId), isCollapsed);
     // Toggle the root style
     jQuery(`.${hierarchyRootClass(wpId)} .wp-table--hierarchy-indicator`).toggleClass(indicatorCollapsedClass, isCollapsed);
   });
  }
}

HierarchyTransformer.$inject = ['wpTableHierarchy', 'states'];
