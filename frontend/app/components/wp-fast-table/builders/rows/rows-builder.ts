import {RowRefreshBuilder} from "./row-refresh-builder";
import {WorkPackageTableMetadata} from "../../wp-table-metadata";
import {States} from "../../../states.service";
import {SingleRowBuilder} from "./single-row-builder";
import {WorkPackageTable} from "../../wp-fast-table";
import {WorkPackageTableRow} from "../../wp-table.interfaces";
import {Subject} from "rxjs";

export abstract class RowsBuilder {
  public states:States;

  protected rowBuilder:SingleRowBuilder;
  protected refreshBuilder:RowRefreshBuilder;

  private stopExisting$ = new Subject();

  constructor(public workPackageTable: WorkPackageTable) {
    this.rowBuilder = new SingleRowBuilder(this.stopExisting$, workPackageTable);
    this.refreshBuilder = new RowRefreshBuilder(this.stopExisting$, workPackageTable);
  }

  /**
   * Build all rows of the table.
   */
  public buildRows(table: WorkPackageTable): DocumentFragment {
    this.stopExisting$.next();
    return this.internalBuildRows(table);
  }

  public abstract internalBuildRows(table: WorkPackageTable): DocumentFragment;


  /**
   * Determine if this builder applies to the current view mode.
   */
  public isApplicable(table:WorkPackageTable, metaData:WorkPackageTableMetadata) {
    return true;
  }

  /**
   * Refresh a single row after structural changes.
   * Will perform dirty checking for when a work package is currently being edited.
   */
  public refreshRow(row:WorkPackageTableRow, table:WorkPackageTable):HTMLElement|null {
    let editing = this.states.editing.get(row.workPackageId).getCurrentValue();
    return this.refreshBuilder.refreshRow(row, editing);
  }

  /**
   * Build an empty row for the given work package.
   */
  protected abstract buildEmptyRow(row:WorkPackageTableRow, table:WorkPackageTable):HTMLElement;
}

RowsBuilder.$inject = ['states'];
