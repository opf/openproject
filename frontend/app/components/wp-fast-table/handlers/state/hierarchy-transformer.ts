import {indicatorCollapsedClass} from '../../builders/rows/hierarchy-rows-builder';
import {WorkPackageTableHierarchyService} from '../../state/wp-table-hierarchy.service';
import {injectorBridge} from '../../../angular/angular-injector-bridge.functions';
import {WorkPackageTable} from '../../wp-fast-table';
import {WPTableHierarchyState} from '../../wp-table.interfaces';
import {States} from '../../../states.service';

export class HierarchyTransformer {
  public wpTableHierarchy:WorkPackageTableHierarchyService;
  public states:States;

  constructor(table:WorkPackageTable) {
    injectorBridge(this);
    let enabled = false;

    this.wpTableHierarchy.hierarchyState
      .observeUntil(this.states.table.stopAllSubscriptions).subscribe((state:WPTableHierarchyState) => {

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
     jQuery(`.__hierarchy-group-${wpId}`).toggleClass(`__collapsed-group-${wpId}`, isCollapsed);
     // Toggle the root style
     jQuery(`.__hierarchy-root-${wpId} .wp-table--hierarchy-indicator`).toggleClass(indicatorCollapsedClass, isCollapsed);
   });
  }
}

HierarchyTransformer.$inject = ['wpTableHierarchy', 'states'];
