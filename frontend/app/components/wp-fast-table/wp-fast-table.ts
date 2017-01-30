import { WorkPackageCacheService } from '../work-packages/work-package-cache.service';
import {WorkPackageResource} from '../api/api-v3/hal-resources/work-package-resource.service';

import {RowBuilder} from './builders/row-builder';
import {States} from '../states.service';
import {injectorBridge} from '../angular/angular-injector-bridge.functions';

import {WorkPackageTableRow} from './wp-table.interfaces';
import {TableHandlerRegistry} from './handlers/table-handler-registry';
import {locateRow} from './helpers/wp-table-row-helpers';

export class WorkPackageTable {
  public wpCacheService:WorkPackageCacheService;
  public states:States;
  public I18n:op.I18n;

  public rows: string[] = [];
  public rowIndex:{[id: string]: WorkPackageTableRow} = {};

  // Row builder instance
  private rowBuilder = new RowBuilder();

  constructor(public tbody:HTMLElement) {
    injectorBridge(this);
    TableHandlerRegistry.attachTo(this);
  }

  public rowObject(workPackageId):WorkPackageTableRow {
    return this.rowIndex[workPackageId];
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
    let tbodyContent = document.createDocumentFragment();

    this.rows.forEach((wpId:string) => {
      let row = this.rowIndex[wpId];
      let tr = this.rowBuilder.buildEmpty(row.object);
      row.element = tr;

      tbodyContent.appendChild(tr);
    });

    this.tbody.innerHTML = '';
    this.tbody.appendChild(tbodyContent);
  }

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

    let newRow = this.rowBuilder.buildEmpty(row.object);
    oldRow.parentNode.replaceChild(newRow, oldRow);
    row.element = newRow;
  }

}

WorkPackageTable.$inject = ['wpCacheService', 'states', 'I18n'];
