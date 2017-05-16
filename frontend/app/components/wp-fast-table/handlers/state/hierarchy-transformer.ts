import {injectorBridge} from "../../../angular/angular-injector-bridge.functions";
import {States} from "../../../states.service";
import {collapsedGroupClass, hierarchyGroupClass, hierarchyRootClass} from "../../helpers/wp-table-hierarchy-helpers";
import {WorkPackageTable} from "../../wp-fast-table";
import {WorkPackageTableHierarchiesService} from './../../state/wp-table-hierarchy.service';
import {WorkPackageTableHierarchies} from "../../wp-table-hierarchies";
import {indicatorCollapsedClass} from "../../builders/modes/hierarchy/single-hierarchy-row-builder";
import {rowClassName} from '../../builders/rows/single-row-builder';
import {debugLog} from '../../../../helpers/debug_output';

export class HierarchyTransformer {
  public wpTableHierarchies:WorkPackageTableHierarchiesService;
  public states:States;

  constructor(table:WorkPackageTable) {
    injectorBridge(this);
    let enabled = false;

    this.wpTableHierarchies
      .observeUntil(this.states.table.stopAllSubscriptions)
      .subscribe((state: WorkPackageTableHierarchies) => {
        if (enabled !== state.isEnabled) {
          table.refreshBody();
        } else if (enabled) {
          // No change in hierarchy mode
          // Refresh groups
          this.renderHierarchyState(state);
        }

        enabled = state.isEnabled;
    });
  }

  /**
   * Update all currently visible rows to match the selection state.
   */
  private renderHierarchyState(state:WorkPackageTableHierarchies) {
    const rendered = this.states.table.rendered.value!;

   // Show all hierarchies
   jQuery('[class^="__hierarchy-group-"]').removeClass((i:number, classNames:string):string => {
    return (classNames.match(/__collapsed-group-\d+/g) || []).join(' ');
   });

   // Hide all collapsed hierarchies
   _.each(state.collapsed, (isCollapsed:boolean, wpId:string) => {
     // Toggle the root style
     jQuery(`.${hierarchyRootClass(wpId)} .wp-table--hierarchy-indicator`).toggleClass(indicatorCollapsedClass, isCollapsed);

     // Get all affected rows
     const affected = jQuery(`.${hierarchyGroupClass(wpId)}`);

     // Hide/Show the descendants.
     affected.toggleClass(collapsedGroupClass(wpId), isCollapsed);

     // Update the hidden section of the rendered state
     affected.filter(`.${rowClassName}`).each((i, el) => {
       // Get the index of this row
       const index = jQuery(el).index();

       // Update the hidden state
       rendered.renderedOrder[index].hidden = isCollapsed;
     });
   });

   this.states.table.rendered.putValue(rendered, 'Updated hidden state of rows after hierarchy change.');
  }
}

HierarchyTransformer.$inject = ['wpTableHierarchies', 'states'];
