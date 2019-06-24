import {Injector} from '@angular/core';
import {scrollTableRowIntoView} from 'core-components/wp-fast-table/helpers/wp-table-row-helpers';
import {distinctUntilChanged, filter, map, takeUntil} from 'rxjs/operators';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {WorkPackageTableHierarchiesService} from "core-components/wp-fast-table/state/wp-table-hierarchy.service";
import {WorkPackageTable} from "core-components/wp-fast-table/wp-fast-table";
import {WorkPackageTableHierarchies} from "core-components/wp-fast-table/wp-table-hierarchies";
import {
  collapsedGroupClass,
  hierarchyGroupClass,
  hierarchyRootClass
} from "core-components/wp-fast-table/helpers/wp-table-hierarchy-helpers";
import {indicatorCollapsedClass} from "core-components/wp-fast-table/builders/modes/hierarchy/single-hierarchy-row-builder";
import {tableRowClassName} from "core-components/wp-fast-table/builders/rows/single-row-builder";

export class HierarchyTransformer {

  public wpTableHierarchies = this.injector.get(WorkPackageTableHierarchiesService);
  public querySpace:IsolatedQuerySpace = this.injector.get(IsolatedQuerySpace);

  constructor(public readonly injector:Injector,
              table:WorkPackageTable) {

    this.wpTableHierarchies
      .updates$()
      .pipe(
        takeUntil(this.querySpace.stopAllSubscriptions),
        map((state) => state.isVisible),
        distinctUntilChanged()
      )
      .subscribe(() => {
        // We don't have to reload all results when _disabling_ the hierarchy mode.
        if (!this.wpTableHierarchies.isEnabled) {
          table.redrawTableAndTimeline();
        }
      });

    let lastValue = this.wpTableHierarchies.isEnabled;

    this.wpTableHierarchies
      .updates$()
      .pipe(
        takeUntil(this.querySpace.stopAllSubscriptions),
        filter(() => this.querySpace.rendered.hasValue())
      )
      .subscribe((state:WorkPackageTableHierarchies) => {

        if (state.isVisible === lastValue) {
          this.renderHierarchyState(state);
        }

        lastValue = state.isVisible;
      });
  }

  /**
   * Update all currently visible rows to match the selection state.
   */
  private renderHierarchyState(state:WorkPackageTableHierarchies) {
    const rendered = this.querySpace.rendered.value!;

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
        if (!collapsed[index]) {
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


    this.querySpace.rendered.putValue(rendered, 'Updated hidden state of rows after hierarchy change.');
  }
}
