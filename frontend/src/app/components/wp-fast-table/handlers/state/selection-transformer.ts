import {Injector} from '@angular/core';
import {WorkPackageViewFocusService} from 'core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-focus.service';
import {takeUntil} from 'rxjs/operators';
import {tableRowClassName} from '../../builders/rows/single-row-builder';
import {checkedClassName} from '../../builders/ui-state-link-builder';
import {locateTableRow, scrollTableRowIntoView} from '../../helpers/wp-table-row-helpers';
import {WorkPackageTable} from '../../wp-fast-table';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {FocusHelperService} from 'core-app/modules/common/focus/focus-helper';
import {
  WorkPackageViewSelectionService,
  WorkPackageViewSelectionState
} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-selection.service";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";

export class SelectionTransformer {

  @InjectField() public wpTableSelection:WorkPackageViewSelectionService;
  @InjectField() public wpTableFocus:WorkPackageViewFocusService;
  @InjectField() public querySpace:IsolatedQuerySpace;
  @InjectField() public FocusHelper:FocusHelperService;

  constructor(public readonly injector:Injector,
              public readonly table:WorkPackageTable) {

    // Focus a single selection when active
    this.querySpace.tableRendered.values$()
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
    this.wpTableSelection.live$()
      .pipe(
        takeUntil(this.querySpace.stopAllSubscriptions)
      )
      .subscribe((state:WorkPackageViewSelectionState) => {
        this.renderSelectionState(state);
      });


    this.wpTableSelection.registerSelectAllListener(() => {
      return table.renderedRows;
    });
    this.wpTableSelection.registerDeselectAllListener();
  }

  /**
   * Update all currently visible rows to match the selection state.
   */
  private renderSelectionState(state:WorkPackageViewSelectionState) {
    const context = jQuery(this.table.tableAndTimelineContainer);

    context.find(`.${tableRowClassName}.${checkedClassName}`).removeClass(checkedClassName);

    _.each(state.selected, (selected:boolean, workPackageId:any) => {
      context.find(`.${tableRowClassName}[data-work-package-id="${workPackageId}"]`).toggleClass(checkedClassName, selected);
    });
  }
}

