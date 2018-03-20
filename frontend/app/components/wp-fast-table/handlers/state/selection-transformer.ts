import {Injector} from '@angular/core';
import {FocusHelperToken} from 'core-app/angular4-transition-utils';
import {WorkPackageTableFocusService} from 'core-components/wp-fast-table/state/wp-table-focus.service';
import {States} from '../../../states.service';
import {tableRowClassName} from '../../builders/rows/single-row-builder';
import {checkedClassName} from '../../builders/ui-state-link-builder';
import {locateTableRow, scrollTableRowIntoView} from '../../helpers/wp-table-row-helpers';
import {WorkPackageTableSelection} from '../../state/wp-table-selection.service';
import {WorkPackageTable} from '../../wp-fast-table';
import {WPTableRowSelectionState} from '../../wp-table.interfaces';
import {OPContextMenuService} from "core-components/op-context-menu/op-context-menu.service";

export class SelectionTransformer {

  public wpTableSelection:WorkPackageTableSelection = this.injector.get(WorkPackageTableSelection);
  public wpTableFocus:WorkPackageTableFocusService = this.injector.get(WorkPackageTableFocusService);
  public states:States = this.injector.get(States);
  public FocusHelper:any = this.injector.get(FocusHelperToken);
  public opContextMenu:OPContextMenuService = this.injector.get(OPContextMenuService);

  constructor(public readonly injector:Injector,
              table:WorkPackageTable) {

    // Focus a single selection when active
    this.states.globalTable.rendered.values$()
      .takeUntil(this.states.globalTable.stopAllSubscriptions)
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
      .takeUntil(this.states.globalTable.stopAllSubscriptions)
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
    jQuery(`.${tableRowClassName}.${checkedClassName}`).removeClass(checkedClassName);

    _.each(state.selected, (selected:boolean, workPackageId:any) => {
      jQuery(`.${tableRowClassName}[data-work-package-id="${workPackageId}"]`).toggleClass(checkedClassName, selected);
    });
  }
}

