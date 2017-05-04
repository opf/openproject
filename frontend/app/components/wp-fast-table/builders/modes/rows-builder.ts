import {Subject} from "rxjs";
import {States} from "../../../states.service";
import {WorkPackageTable} from "../../wp-fast-table";
import {WorkPackageTableRow} from "../../wp-table.interfaces";
import {SingleRowBuilder} from "../rows/single-row-builder";
import {RowRefreshBuilder} from "../rows/row-refresh-builder";

export abstract class RowsBuilder {
  public states:States;

  protected rowBuilder:SingleRowBuilder;
  protected refreshBuilder:RowRefreshBuilder;

  protected stopExisting$ = new Subject();

  constructor(public workPackageTable: WorkPackageTable) {
    this.setupRowBuilders();
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
  public isApplicable(table:WorkPackageTable) {
    return true;
  }

  /**
   * Refresh a single row after structural changes.
   * Will perform dirty checking for when a work package is currently being edited.
   */
  public refreshRow(row:WorkPackageTableRow, table:WorkPackageTable):HTMLElement|null {
    let editing = this.states.editing.get(row.workPackageId).value;
    return this.refreshBuilder.refreshRow(row, editing);
  }

  /**
   * Construct the single and refresh row builders for this instance
   */
  protected setupRowBuilders() {
    this.rowBuilder = new SingleRowBuilder(this.stopExisting$, this.workPackageTable);
    this.refreshBuilder = new RowRefreshBuilder(this.stopExisting$, this.workPackageTable);
  }

  /**
   * Build an empty row for the given work package.
   */
  protected abstract buildEmptyRow(row:WorkPackageTableRow, table:WorkPackageTable):HTMLElement;
}

RowsBuilder.$inject = ['states'];
