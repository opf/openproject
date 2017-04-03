import {WorkPackageTableRow} from "../../wp-table.interfaces";
import {RowsBuilder} from "./rows-builder";
import {States} from "../../../states.service";
import {injectorBridge} from "../../../angular/angular-injector-bridge.functions";
import {WorkPackageTableColumnsService} from "../../state/wp-table-columns.service";
import {WorkPackageTable} from "../../wp-fast-table";

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
  public internalBuildRows(table:WorkPackageTable):DocumentFragment {
    let tbodyContent = document.createDocumentFragment();

    table.rows.forEach((wpId:string) => {
      let row = table.rowIndex[wpId];
      let tr = this.buildEmptyRow(row);
      row.element = tr;
      tbodyContent.appendChild(tr);
    });

    return tbodyContent;
  }

  public buildEmptyRow(row:WorkPackageTableRow, table?:WorkPackageTable) {
    return this.rowBuilder.buildEmpty(row.object);
  }
}

PlainRowsBuilder.$inject = ['states', 'I18n'];
