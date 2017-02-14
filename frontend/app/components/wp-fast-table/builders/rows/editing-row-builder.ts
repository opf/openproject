import {WorkPackageEditForm} from '../../../wp-edit-form/work-package-edit-form';
import {locateRow} from '../../helpers/wp-table-row-helpers';
import {WorkPackageTable} from '../../wp-fast-table';
import {WorkPackageTableRow} from '../../wp-table.interfaces';
import {SingleRowBuilder} from './single-row-builder';

export class EditingRowBuilder extends SingleRowBuilder {

  /**
   * Refresh a row that is currently being edited, that is, some edit fields may be open
   */
  public refreshEditing(row:WorkPackageTableRow, editForm:WorkPackageEditForm):HTMLElement {
    // Get the row for the WP if refreshing existing
    let rowElement = row.element || locateRow(row.workPackageId);

    // Detach all existing columns
    let tds = jQuery(rowElement).find('td').detach();

    // Iterate all columns, reattaching or rendering new columns
    this.columns.forEach((column:string) => {
      let oldTd = tds.filter(`td.${column}`);

      // Reattach the column if its currently being edited
      if (editForm.activeFields[column] && oldTd.length) {
        rowElement.appendChild(oldTd[0]);
      } else {
        let cell = this.cellBuilder.build(row.object, column);
        rowElement.appendChild(cell);
      }
    });

    // Last column: details link
    this.detailsLinkBuilder.build(row.object, rowElement);

    return rowElement;
  }
}
