import { WorkPackageCacheService } from '../work-packages/work-package-cache.service';
import {DisplayField} from './../wp-display/wp-display-field/wp-display-field.module';
import {WorkPackageDisplayFieldService} from './../wp-display/wp-display-field/wp-display-field.service';
import {State, MultiState} from './../../helpers/reactive-fassade';
import {WorkPackageResource} from './../api/api-v3/hal-resources/work-package-resource.service';

import {cellClassName} from './builders/cell-builder';
import {RowBuilder} from './builders/row-builder';
import {RowEditHandler} from './handler/row-edit-handler';

interface WorkPackageRow {
  workPackage:WorkPackageResource;
  position:number;

  // States
  checked: false;
  editing: false;
}

export class WorkPackageTable {

  public rows: WorkPackageResource[];
  public rowIndex:{[id: number]: number};

  public columns: string[];

  private text:any;

  // Row builder instance
  private rowBuilder:RowBuilder;

  constructor(public tbody:HTMLElement,
              public wpCacheService:WorkPackageCacheService,
              public wpState:MultiState<WorkPackageResource>,
              public wpDisplayField:WorkPackageDisplayFieldService,
              private I18n:op.I18n) {
  }

  private registerClickListener() {
    jQuery(this.tbody).on('click', '.' + cellClassName, (evt) => {
      let row = jQuery(evt.target).closest('tr');
      this.handleCellClick(row, evt);
    });
  }

  private handleCellClick(row:JQuery, evt:JQueryEventObject) {
    const cell:Element = evt.target;

    // Ignore clicks on non-editable fields
    if (!cell.classList.contains('-editable')) {
       return;
    }

    new RowEditHandler(row, cell, evt);
  }

  public initialize(rows, columns) {
    this.rows = rows;
    this.rowIndex = {};
    this.columns = columns;
    this.tbody.innerHTML = '';

    this.rowBuilder = new RowBuilder(this.wpDisplayField, this.I18n, columns);
    this.registerClickListener();

    rows.forEach((row, i) => {
      let workPackage = row.object;
      this.rowIndex[workPackage.id] = i;

      let state = this.wpState.get(workPackage.id);
      let tr = this.createEmptyRow(workPackage);

      this.tbody.appendChild(tr);

      state.observe(null).subscribe(() => {
        this.refreshWorkPackage(workPackage, tr);
      });
    });
  }

  public refreshWorkPackage(workPackage, oldRow:HTMLTableRowElement) {
    // Get the row for the WP if refreshing existing
    if (oldRow === undefined) {
      oldRow = document.getElementById('wp-row-' + workPackage.id);
    }

    let newRow = this.createEmptyRow(workPackage);
    this.rowBuilder.build(workPackage, newRow);
    oldRow.replaceWith(newRow);
  }

  public createEmptyRow(workPackage) {
    let tr = document.createElement('tr');
    tr.id = 'wp-row-' + workPackage.id;

    return tr;
  }

  public insertAllRows() {
    this.rows.forEach((row:any) => {
      let workPackage = row.object;
      let tr = this.createEmptyRow(workPackage);

      this.rowBuilder.build(workPackage, tr);
      this.tbody.appendChild(tr);
    });
  }
}
