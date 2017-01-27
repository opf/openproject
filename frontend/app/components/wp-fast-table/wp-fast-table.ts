import { WorkPackageCacheService } from '../work-packages/work-package-cache.service';
import {WorkPackageResource} from '../api/api-v3/hal-resources/work-package-resource.service';

import {RowBuilder, rowClassName} from './builders/row-builder';
import {States} from '../states.service';
import {injectorBridge} from '../angular/angular-injector-bridge.functions';
import {TableEventsRegistry} from './handlers/table-events-registry';

import {Observable} from 'rxjs';
import {WorkPackageTableRow, WPTableRowSelectionState} from './wp-table.interfaces';
import {WorkPackageTableSelection} from './state/wp-table-selection.service';

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

  public rows: string[];
  public rowIndex:{[id: string]: WorkPackageTableRow};

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
   * Observe the WP multi state for _any_ change on the known work packages.
   * If a visible row is affected, refresh it immediately.
   */
  private observeRowChanges() {
    this.states.workPackages.observe(null)
      .subscribe(([changedId, wp]: [string, WorkPackageResource]) => {
      let row = this.rowIndex[changedId];

      if (row !== undefined) {
        row.object = wp;
        this.refreshWorkPackage(row);
        this.rowIndex[changedId] = row;
      }
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
    this.refreshAllWorkPackages();

    // Observe changes on the work packages multistate
    this.observeRowChanges();

    // Preselect first work package as focused
    if (this.rows.length) {
      this.states.focusedWorkPackage.put(this.rows[0]);
    }
  }

  public refreshAllWorkPackages() {
    let tbodyContent = document.createDocumentFragment();

    this.rows.forEach((wpId:string) => {
      let row = this.rowIndex[wpId];

      let tr = this.rowBuilder.createEmptyRow(row.object);
      this.rowBuilder.build(row.object, tr);
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
    let oldRow = row.element || this.locateRow(row.workPackageId);

    if (oldRow.dataset['lockVersion'] === row.object.lockVersion.toString()) {
      console.log("Skipping row " + row.workPackageId + " since its fresh");
      return;
    }

    let newRow = this.rowBuilder.createEmptyRow(row.object);
    this.rowBuilder.build(row.object, newRow);
    oldRow.parentNode.replaceChild(newRow, oldRow);
    row.element = newRow;
  }

  private renderSelectionState(state:WPTableRowSelectionState) {
    jQuery(`.${rowClassName}.-checked`).removeClass('-checked');

    _.each(state.selected, (selected: boolean, workPackageId:any) => {
      jQuery('#wp-row-' + workPackageId).toggleClass('-checked', selected);
    });
  }

  private locateRow(id):HTMLElement {
    return document.getElementById('wp-row-' + id);
  }

  private initializeStates() {
    // Redraw table if rows changed
    this.states.table.rows.observe(null).subscribe((rows:WorkPackageResource[]) => {
      var t0 = performance.now();
      this.initialSetup(rows);
      var t1 = performance.now();
      console.log("Initialize took " + (t1 - t0) + " milliseconds.");
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
