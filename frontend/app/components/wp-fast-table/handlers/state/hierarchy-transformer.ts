import {Injector} from '@angular/core';
import {scrollTableRowIntoView} from 'core-components/wp-fast-table/helpers/wp-table-row-helpers';
import {States} from '../../../states.service';
import {indicatorCollapsedClass} from '../../builders/modes/hierarchy/single-hierarchy-row-builder';
import {tableRowClassName} from '../../builders/rows/single-row-builder';
import {collapsedGroupClass, hierarchyGroupClass, hierarchyRootClass} from '../../helpers/wp-table-hierarchy-helpers';
import {WorkPackageTable} from '../../wp-fast-table';
import {WorkPackageTableHierarchies} from '../../wp-table-hierarchies';
import {WorkPackageTableHierarchiesService} from './../../state/wp-table-hierarchy.service';

export class HierarchyTransformer {

  public wpTableHierarchies = this.injector.get(WorkPackageTableHierarchiesService);
  public states:States = this.injector.get(States);

  constructor(public readonly injector:Injector,
              table:WorkPackageTable) {
    // injectorBridge(this);

    this.states.updates.hierarchyUpdates
      .values$('Refreshing hierarchies on user request')
      .takeUntil(this.states.table.stopAllSubscriptions)
      .map((state) => state.isEnabled)
      .distinctUntilChanged()
      .subscribe(() => {
        // We don't have to reload all results when _disabling_ the hierarchy mode.
        if (!this.wpTableHierarchies.isEnabled) {
          table.redrawTableAndTimeline();
        }
      });

    let lastValue = this.wpTableHierarchies.isEnabled;

    this.wpTableHierarchies
      .observeUntil(this.states.table.stopAllSubscriptions)
      .subscribe((state) => {

        if (state.isEnabled === lastValue) {
          this.renderHierarchyState(state);
        }

        lastValue = state.isEnabled;
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

    // Mark which rows were hidden by some other hierarchy group
    // (e.g., by a collapsed parent)
    const collapsed:{ [index:number]:boolean } = {};


    // Hide all collapsed hierarchies
    _.each(state.collapsed, (isCollapsed:boolean, wpId:string) => {
      // Toggle the root style
      jQuery(`.${hierarchyRootClass(wpId)} .wp-table--hierarchy-indicator`).toggleClass(indicatorCollapsedClass, isCollapsed);

      // Get all affected rows
      const affected = jQuery(`.${hierarchyGroupClass(wpId)}`);

      // Hide/Show the descendants.
      affected.toggleClass(collapsedGroupClass(wpId), isCollapsed);

      // Update the hidden section of the rendered state
      affected.filter(`.${tableRowClassName}`).each((i, el) => {
        // Get the index of this row
        const index = jQuery(el).index();

        // Update the hidden state
        if (collapsed[index] !== true) {
          rendered[index].hidden = isCollapsed;
          collapsed[index] = isCollapsed;
        }
      });
    });

    // Keep focused on the last element, if any.
    // Based on https://stackoverflow.com/a/3782959
    if (state.last) {
      scrollTableRowIntoView(state.last);
    }


    this.states.table.rendered.putValue(rendered, 'Updated hidden state of rows after hierarchy change.');
  }
}

// HierarchyTransformer.$inject = ['wpTableHierarchies', 'states'];
