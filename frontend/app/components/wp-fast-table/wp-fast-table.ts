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
    this.initializeStates();
  }

  public rowObject(workPackageId):WorkPackageTableRow {
    return this.rowIndex[workPackageId];
  }

  public initialize(rows:WorkPackageResource[]) {
    this.rowIndex = {};
    this.rows = rows.map((wp:WorkPackageResource, i:number) => {
      let row = <WorkPackageTableRow> { object: wp, workPackageId: wp.id, position: i };
      this.rowIndex[wp.id] = row;

      return row;
    });

    // Draw work packages
    this.refreshAllWorkPackages();

    // Observe changes on the work packages multistate
    this.states.workPackages.observe(null).subscribe((changedId:string) => {
      let row = this.rowIndex[changedId];

      if (row !== undefined) {
        this.refreshWorkPackage(row.object);
      }
    });

    // Preselect first work package as focused
    if (this.rows.length) {
      this.states.focusedWorkPackage.put(this.rows[0].workPackageId);
    }
  }

  public refreshAllWorkPackages() {
    let tbodyContent = document.createDocumentFragment();
    let selection = this.states.table.selection.getCurrentValue();

    let times = 0;
    this.rows.forEach((row:WorkPackageTableRow) => {

      var t0 = performance.now();
      let tr = this.rowBuilder.createEmptyRow(row.object);
      this.rowBuilder.build(row.object, tr);
      var t1 = performance.now();
      times += (t1-t0);

      if (selection.selected[row.workPackageId]) {
        tr.classList.add('-checked');
      }

      tbodyContent.appendChild(tr);
    });

    console.log("Rows took " + (times / this.rows.length) + " ms on average.");
    console.log("Inner refresh " + times );
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

    if (oldRow.dataset['lockVersion'] === workPackage.lockVersion.toString()) {
      console.log("Skipping row " + workPackage.id + " since its fresh");
      return;
    }

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
    // Redraw table if rows changed
    this.states.table.rows.observe(null).subscribe((rows:WorkPackageResource[]) => {
      this.states.table.columns.get().then(() => {
        var t0 = performance.now();
        this.initialize(rows);
        var t1 = performance.now();
        console.log("Initialize took " + (t1 - t0) + " milliseconds.");
      });
    });

    this.states.table.columns.observe(null).subscribe(() => {
      if (this.rows) {
        var t0 = performance.now();
        this.refreshAllWorkPackages();
        var t1 = performance.now();
        console.log("column redraw took " + (t1 - t0) + " milliseconds.");
      }
    });

    this.states.table.selection.observe(null).subscribe((state:WPTableRowSelectionState) => {
      this.renderSelectionState(state);
    });
  }
}

WorkPackageTable.$inject = ['wpCacheService', 'states', 'I18n'];
