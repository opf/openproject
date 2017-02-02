
import {WorkPackageTableSelection} from '../../state/wp-table-selection.service';
import {injectorBridge} from '../../../angular/angular-injector-bridge.functions';
import {WPTableRowSelectionState} from '../../wp-table.interfaces';
import {WorkPackageTable} from '../../wp-fast-table';
import {rowId} from '../../helpers/wp-table-row-helpers';
import {checkedClassName} from '../../builders/ui-state-link-builder';
import {rowClassName} from '../../builders/rows/single-row-builder';
export class SelectionTransformer {
  public wpTableSelection:WorkPackageTableSelection;

  constructor(table:WorkPackageTable) {
    injectorBridge(this);

    this.wpTableSelection.selectionState
      .observe(null).subscribe((state:WPTableRowSelectionState) => {
      this.renderSelectionState(state);
    });

    // Bind CTRL+A to select all work packages
    Mousetrap.bind(['command+a', 'ctrl+a'], (e) => {
      this.wpTableSelection.selectAll(table.rows);

      e.preventDefault();
      return false;
    });

    // Bind CTRL+D to deselect all work packages
    Mousetrap.bind(['command+d', 'ctrl+d'], (e) => {
      this.wpTableSelection.reset();
      e.preventDefault();
      return false;
    });
  }

  /**
   * Update all currently visible rows to match the selection state.
   */
  private renderSelectionState(state) {
    jQuery(`.${rowClassName}.${checkedClassName}`).removeClass(checkedClassName);

    _.each(state.selected, (selected: boolean, workPackageId:any) => {
      jQuery(`#${rowId(workPackageId)}`).toggleClass(checkedClassName, selected);
    });
  }
}

SelectionTransformer.$inject = ['wpTableSelection'];
