import {QueryColumn} from "../../../api/api-v3/hal-resources/query-resource.service";
import {WorkPackageEditForm} from "../../../wp-edit-form/work-package-edit-form";
import {locateRow} from "../../helpers/wp-table-row-helpers";
import {WorkPackageTableRow} from "../../wp-table.interfaces";
import {wpCellTdClassName} from "../cell-builder";
import {SingleRowBuilder} from "./single-row-builder";
import {debugLog} from '../../../../helpers/debug_output';

export class RowRefreshBuilder extends SingleRowBuilder {

  /**
   * Refresh a row that is currently being edited, that is, some edit fields may be open
   */
  public refreshRow(row: WorkPackageTableRow, editForm: WorkPackageEditForm | undefined):[HTMLElement, boolean] | null {
    // Get the row for the WP if refreshing existing
    const rowElement = row.element || locateRow(row.workPackageId);

    if (!rowElement) {
      debugLog(`Trying to refresh row for ${row.workPackageId} that is not in the table`);
      return null;
    }

    // Iterate all columns, reattaching or rendering new columns
    const jRow = jQuery(rowElement);

    // Detach all current edit cells
    const cells = jRow.find(`.${wpCellTdClassName}`).detach();

    // Remember the order of all new edit cells
    const newCells:HTMLElement[] = [];

    this.columns.forEach((column:QueryColumn) => {
      const oldTd = cells.filter(`td.${column.id}`);

      // Skip the replacement of the column if this is being edited.
      if (this.isColumnBeingEdited(editForm, column)) {
        newCells.push(oldTd[0]);
        return;
      }

      // Otherwise, refresh that cell and append it
      const cell = this.buildCell(row.object, column);
      newCells.push(cell);
    });

    jRow.prepend(newCells);
    return [rowElement!, false];
  }

  private isColumnBeingEdited(editForm: WorkPackageEditForm | undefined, column: QueryColumn) {
    return editForm && editForm.activeFields[column.id];
  }
}
