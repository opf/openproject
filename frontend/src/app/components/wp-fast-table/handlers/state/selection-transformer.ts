import {Injector} from '@angular/core';
import {WorkPackageTableFocusService} from 'core-components/wp-fast-table/state/wp-table-focus.service';
import {takeUntil} from 'rxjs/operators';
import {tableRowClassName} from '../../builders/rows/single-row-builder';
import {checkedClassName} from '../../builders/ui-state-link-builder';
import {locateTableRow, scrollTableRowIntoView} from '../../helpers/wp-table-row-helpers';
import {WorkPackageTableSelection} from '../../state/wp-table-selection.service';
import {WorkPackageTable} from '../../wp-fast-table';
import {WPTableRowSelectionState} from '../../wp-table.interfaces';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {FocusHelperService} from 'core-app/modules/common/focus/focus-helper';

export class SelectionTransformer {

  public wpTableSelection:WorkPackageTableSelection = this.injector.get(WorkPackageTableSelection);
  public wpTableFocus:WorkPackageTableFocusService = this.injector.get(WorkPackageTableFocusService);
  public querySpace:IsolatedQuerySpace = this.injector.get(IsolatedQuerySpace);
  public FocusHelper:FocusHelperService = this.injector.get(FocusHelperService);

  constructor(public readonly injector:Injector,
              public readonly table:WorkPackageTable) {

    // Focus a single selection when active
    this.querySpace.rendered.values$()
      .pipe(
        takeUntil(this.querySpace.stopAllSubscriptions)
      )
      .subscribe(() => {

        this.wpTableFocus.ifShouldFocus((wpId:string) => {
          const element = locateTableRow(wpId);
          if (element.length) {
            scrollTableRowIntoView(wpId);
            this.FocusHelper.focusElement(element, true);
          }
        });
      });


    // Update selection state
    this.wpTableSelection.selectionState.values$()
      .pipe(
        takeUntil(this.querySpace.stopAllSubscriptions)
      )
      .subscribe((state:WPTableRowSelectionState) => {
        this.renderSelectionState(state);
      });


    this.wpTableSelection.registerSelectAllListener(() => { return table.renderedRows; });
    this.wpTableSelection.registerDeselectAllListener();
  }

  /**
   * Update all currently visible rows to match the selection state.
   */
  private renderSelectionState(state:WPTableRowSelectionState) {
    const context = jQuery(this.table.container);

    context.find(`.${tableRowClassName}.${checkedClassName}`).removeClass(checkedClassName);

    _.each(state.selected, (selected:boolean, workPackageId:any) => {
      context.find(`.${tableRowClassName}[data-work-package-id="${workPackageId}"]`).toggleClass(checkedClassName, selected);
    });
  }
}

