import {wpCellTdClassName} from '../cell-builder';
import {timelineCellClassName} from '../timeline-cell-builder';
import {WorkPackageEditForm} from '../../../wp-edit-form/work-package-edit-form';
import {locateRow} from '../../helpers/wp-table-row-helpers';
import {WorkPackageTable} from '../../wp-fast-table';
import {WorkPackageTableRow} from '../../wp-table.interfaces';
import {SingleRowBuilder} from './single-row-builder';

import {detailsLinkClassName} from '../details-link-builder';

export class RowRefreshBuilder extends SingleRowBuilder {

  /**
   * Refresh a row that is currently being edited, that is, some edit fields may be open
   */
  public refreshRow(row:WorkPackageTableRow, editForm:WorkPackageEditForm|null):HTMLElement|null {
    // Get the row for the WP if refreshing existing
    const rowElement = row.element || locateRow(row.workPackageId);
    if (!rowElement) {
      return null;
    }

    // Iterate all columns, reattaching or rendering new columns
    const jRow = jQuery(rowElement);

    // Detach all current edit cells
    const cells = jRow.find(`.${wpCellTdClassName}`).detach();

    // Remember the order of all new edit cells
    const newCells:HTMLElement[] = [];

    this.columns.forEach((column:string) => {
      const oldTd = jRow.find(`td.${column}`);

      // Skip the replacement of the column if this is being edited.
      if (this.isColumnBeingEdited(editForm, column)) {
        newCells.push(oldTd[0]);
        return;
      }

      // Otherwise, refresh that cell and append it
      const cell = this.cellBuilder.build(row.object, column);
      newCells.push(cell);
    });

    jRow.prepend(newCells);
    return rowElement;
  }

  private isColumnBeingEdited(editForm:WorkPackageEditForm|null, column:string) {
    return editForm && editForm.activeFields[column];
  }
}
