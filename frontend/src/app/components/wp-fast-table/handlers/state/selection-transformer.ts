import {Injector} from '@angular/core';
import {WorkPackageTableFocusService} from 'core-components/wp-fast-table/state/wp-table-focus.service';
import {takeUntil} from 'rxjs/operators';
import {tableRowClassName} from '../../builders/rows/single-row-builder';
import {checkedClassName} from '../../builders/ui-state-link-builder';
import {locateTableRow, scrollTableRowIntoView} from '../../helpers/wp-table-row-helpers';
import {WorkPackageTableSelection} from '../../state/wp-table-selection.service';
import {WorkPackageTable} from '../../wp-fast-table';
import {WPTableRowSelectionState} from '../../wp-table.interfaces';
import {OPContextMenuService} from "core-components/op-context-menu/op-context-menu.service";
import {TableState} from 'core-components/wp-table/table-state/table-state';
import {FocusHelperService} from 'core-app/modules/common/focus/focus-helper';

export class SelectionTransformer {

  public wpTableSelection:WorkPackageTableSelection = this.injector.get(WorkPackageTableSelection);
  public wpTableFocus:WorkPackageTableFocusService = this.injector.get(WorkPackageTableFocusService);
  public tableState:TableState = this.injector.get(TableState);
  public FocusHelper:FocusHelperService = this.injector.get(FocusHelperService);
  public opContextMenu:OPContextMenuService = this.injector.get(OPContextMenuService);

  constructor(public readonly injector:Injector,
              public readonly table:WorkPackageTable) {

    // Focus a single selection when active
    this.tableState.rendered.values$()
      .pipe(
        takeUntil(this.tableState.stopAllSubscriptions)
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
        takeUntil(this.tableState.stopAllSubscriptions)
      )
      .subscribe((state:WPTableRowSelectionState) => {
        this.renderSelectionState(state);
      });

    // Bind CTRL+A to select all work packages
    Mousetrap.bind(['command+a', 'ctrl+a'], (e) => {
      this.wpTableSelection.selectAll(table.renderedRows);

      e.preventDefault();
      this.opContextMenu.close();
      return false;
    });

    // Bind CTRL+D to deselect all work packages
    Mousetrap.bind(['command+d', 'ctrl+d'], (e) => {
      this.wpTableSelection.reset();
      this.opContextMenu.close();
      e.preventDefault();
      return false;
    });
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

