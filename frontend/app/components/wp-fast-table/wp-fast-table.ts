import { WorkPackageCacheService } from '../work-packages/work-package-cache.service';
import {WorkPackageResource} from '../api/api-v3/hal-resources/work-package-resource.service';

import {RowBuilder, rowClassName} from './builders/row-builder';
import {States} from '../states.service';
import {injectorBridge} from '../angular/angular-injector-bridge.functions';
import {TableEventsRegistry} from './handlers/table-events-registry';

import {Observable} from 'rxjs';
import {WorkPackageTableRow, WPTableRowSelectionState} from './wp-table.interfaces';

interface WorkPackageRow {
  workPackage:WorkPackageResource;
  position:number;

  // States
  checked: false;
  editing: false;
}

export class WorkPackageTable {
  public wpCacheService:WorkPackageCacheService;
  public states:States;
  public I18n:op.I18n;

  public rows: WorkPackageTableRow[];
  public rowIndex:{[id: number]: WorkPackageTableRow};

  // Row builder instance
  private rowBuilder = new RowBuilder();

  constructor(public tbody:HTMLElement) {
    injectorBridge(this);
    TableEventsRegistry.attachTo(this);
  }

  public rowObject(workPackageId):WorkPackageTableRow {
    return this.rowIndex[workPackageId];
  }

  public initialize(rows) {
    this.rows = rows;
    this.rowIndex = {};

    this.initializeStates();

    // Draw work packages and watch for changes
    this.refreshAllWorkPackages((row, index) => {
      let state = this.states.workPackages.get(row.object.id);
      row.observer = state.observe(null).subscribe((wp) => {
        row.object = wp;
        this.rows[index] = row;
        this.refreshWorkPackage(wp);
      });
    });
  }

  public refreshAllWorkPackages(rowCallback?:Function) {
    let tbodyContent = document.createDocumentFragment();
    this.rows.forEach((row:WorkPackageTableRow, i) => {
      let workPackage = row.object;
      this.rowIndex[workPackage.id] = { object: workPackage, workPackageId: workPackage.id, position: i };

      let tr = this.rowBuilder.createEmptyRow(workPackage);
      this.rowBuilder.build(workPackage, tr);

      tbodyContent.appendChild(tr);
      rowCallback && rowCallback(row, tr, i);
    });

    this.tbody.innerHTML = '';
    this.tbody.appendChild(tbodyContent);
  }

  public refreshWorkPackage(workPackage) {
    // If the work package is dirty, we're working on it
    if (workPackage.dirty) {
      console.log("Skipping row " + workPackage.id + " since its dirty");
      return;
    }

    // Get the row for the WP if refreshing existing
    let oldRow = <HTMLElement> document.getElementById('wp-row-' + workPackage.id);
    let newRow = this.rowBuilder.createEmptyRow(workPackage);
    this.rowBuilder.build(workPackage, newRow);
    oldRow.parentNode.replaceChild(newRow, oldRow);
  }

  private renderSelectionState(state:WPTableRowSelectionState) {
    jQuery(`.${rowClassName}.-checked`).removeClass('-checked');

    _.each(state.selected, (selected: boolean, workPackageId:any) => {
      jQuery('#wp-row-' + workPackageId).toggleClass('-checked', selected);
    });
  }

  private initializeStates() {
    this.states.table.columns.observe(null).subscribe(() => {
      this.refreshAllWorkPackages();
    });

    this.states.table.selection.observe(null).subscribe((state:WPTableRowSelectionState) => {
      this.renderSelectionState(state);
    });
  }
}

WorkPackageTable.$inject = ['wpCacheService', 'states', 'I18n'];
