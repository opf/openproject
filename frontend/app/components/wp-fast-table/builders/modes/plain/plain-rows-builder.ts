import {RowsBuilder} from "../rows-builder";
import {WorkPackageTable} from "../../../wp-fast-table";
import {injectorBridge} from "../../../../angular/angular-injector-bridge.functions";
import {WorkPackageTableRow} from "../../../wp-table.interfaces";

export class PlainRowsBuilder extends RowsBuilder {
  // Injections
  public I18n:op.I18n;

  // The group expansion state
  constructor(workPackageTable: WorkPackageTable) {
    super(workPackageTable);
    injectorBridge(this);
  }

  /**
   * Rebuild the entire grouped tbody from the given table
   * @param table
   */
  public internalBuildRows(table:WorkPackageTable):[DocumentFragment,DocumentFragment] {
    let tableBody = document.createDocumentFragment();
    let timelineBody = document.createDocumentFragment();

    table.rows.forEach((wpId:string) => {
      let row = table.rowIndex[wpId];
      let tr = this.buildEmptyRow(row);
      row.element = tr;
      this.appendRow(row.object, tr, tableBody, timelineBody);
      tableBody.appendChild(tr);
    });

    return [tableBody, timelineBody];
  }

  public buildEmptyRow(row:WorkPackageTableRow, table?:WorkPackageTable) {
    return this.rowBuilder.buildEmpty(row.object);
  }
}

PlainRowsBuilder.$inject = ['states', 'I18n'];
