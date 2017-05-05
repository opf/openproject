import {Subject} from "rxjs";
import {States} from "../../../states.service";
import {WorkPackageTable} from "../../wp-fast-table";
import {WorkPackageTableRow} from "../../wp-table.interfaces";
import {SingleRowBuilder} from "../rows/single-row-builder";
import {RowRefreshBuilder} from "../rows/row-refresh-builder";
import {WorkPackageResourceInterface} from "../../../api/api-v3/hal-resources/work-package-resource.service";
import {TimelineRowBuilder} from "../timeline/timeline-row-builder";

export abstract class RowsBuilder {
  public states:States;

  protected timelinebuilder:TimelineRowBuilder;
  protected rowBuilder:SingleRowBuilder;
  protected refreshBuilder:RowRefreshBuilder;

  protected stopExisting$ = new Subject();

  constructor(public workPackageTable: WorkPackageTable) {
    this.setupRowBuilders();
  }

  /**
   * Build all rows of the table.
   */
  public buildRows(table: WorkPackageTable): [DocumentFragment,DocumentFragment] {
    this.stopExisting$.next();
    return this.internalBuildRows(table);
  }

  public abstract internalBuildRows(table: WorkPackageTable): [DocumentFragment,DocumentFragment];

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
  public refreshRow(row:WorkPackageTableRow):HTMLElement|null {
    let editing = this.states.editing.get(row.workPackageId).value;
    return this.refreshBuilder.refreshRow(row, editing);
  }

  /**
   * Construct the single and refresh row builders for this instance
   */
  protected setupRowBuilders() {
    this.rowBuilder = new SingleRowBuilder(this.stopExisting$, this.workPackageTable);
    this.refreshBuilder = new RowRefreshBuilder(this.stopExisting$, this.workPackageTable);
    this.timelinebuilder = new TimelineRowBuilder(this.stopExisting$, this.workPackageTable);
  }

  /**
   * Append a new row a work package (or a virtual row) to both containers
   * @param workPackage The work package, if the row belongs to one
   * @param row HTMLElement to append
   * @param tableBody DocumentFragement to replace the table body
   * @param timelineBody DocumentFragment to replace the timeline
   */
  protected appendRow(workPackage: WorkPackageResourceInterface|null,
                      row:HTMLElement,
                      tableBody:DocumentFragment,
                      timelineBody:DocumentFragment) {

    tableBody.appendChild(row);

    // Append row into timeline
    this.timelinebuilder.build(workPackage, timelineBody);
  }

  /**
   * Build an empty row for the given work package.
   */
  protected abstract buildEmptyRow(row:WorkPackageTableRow, table:WorkPackageTable):HTMLElement;
}

RowsBuilder.$inject = ['states'];
