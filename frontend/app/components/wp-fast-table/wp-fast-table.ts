import { WorkPackageCacheService } from '../work-packages/work-package-cache.service';
import {WorkPackageResource} from '../api/api-v3/hal-resources/work-package-resource.service';

import {SingleRowBuilder} from './builders/single-row-builder';
import {States} from '../states.service';
import {injectorBridge} from '../angular/angular-injector-bridge.functions';

import {RowsBuilderInterface, WorkPackageTableRow} from './wp-table.interfaces';
import {TableHandlerRegistry} from './handlers/table-handler-registry';
import {locateRow} from './helpers/wp-table-row-helpers';
import {GroupedRowsBuilder} from './builders/grouped-rows-builder';
import {PlainRowsBuilder} from './builders/plain-rows-builder';



export class WorkPackageTable {
  public wpCacheService:WorkPackageCacheService;
  public states:States;
  public I18n:op.I18n;

  public rows: string[] = [];
  public rowIndex:{[id: string]: WorkPackageTableRow} = {};


  private groupedRowsBuilder = new GroupedRowsBuilder();
  private plainRowsBuilder = new PlainRowsBuilder();

  constructor(public metaData:any, public tbody:HTMLElement) {
    injectorBridge(this);
    TableHandlerRegistry.attachTo(this);
  }

  public rowObject(workPackageId):WorkPackageTableRow {
    return this.rowIndex[workPackageId];
  }

  public get rowBuilder():RowsBuilderInterface {
    if (this.metaData.groupBy) {
      return this.groupedRowsBuilder;
    } else {
      return this.plainRowsBuilder;
    }
  }

  /**
   * Build the row index and positions from the given set of ordered work packages.
   * @param rows
   */
  private buildIndex(rows) {
    this.rowIndex = {};
    this.rows = rows.map((wp:WorkPackageResource, i:number) => {
      let id = wp.id;
      this.rowIndex[id] = <WorkPackageTableRow> { object: wp, workPackageId: id, position: i };
      return id;
    });
  }
  /**
   *
   * @param rows
   */
  public initialSetup(rows:WorkPackageResource[]) {
    // Build the row representation
    this.buildIndex(rows);

    // Draw work packages
    this.refreshBody();

    // Preselect first work package as focused
    if (this.rows.length) {
      this.states.focusedWorkPackage.put(this.rows[0]);
    }
  }

  /**
   * Removes the contents of this table's tbody and redraws
   * all elements.
   */
  public refreshBody() {
    let newBody = this.rowBuilder.buildRows(this);

    this.tbody.innerHTML = '';
    this.tbody.appendChild(newBody);
  }

  /**
   * Refreshes a single entity.
   */
  public refreshWorkPackage(row:WorkPackageTableRow) {
    // If the work package is dirty, we're working on it
    if (row.object.dirty) {
      console.log("Skipping row " + row.workPackageId + " since its dirty");
      return;
    }

    // Get the row for the WP if refreshing existing
    let oldRow = row.element || locateRow(row.workPackageId);

    if (oldRow.dataset['lockVersion'] === row.object.lockVersion.toString()) {
      console.log("Skipping row " + row.workPackageId + " since its fresh");
      return;
    }

    let newRow = this.rowBuilder.redrawRow(row, this);
    oldRow.parentNode.replaceChild(newRow, oldRow);
    row.element = newRow;
  }

}

WorkPackageTable.$inject = ['wpCacheService', 'states', 'I18n'];
