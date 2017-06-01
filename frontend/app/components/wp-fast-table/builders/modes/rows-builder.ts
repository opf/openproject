import {States} from '../../../states.service';
import {WorkPackageTable} from '../../wp-fast-table';
import {WorkPackageTableRow} from '../../wp-table.interfaces';
import {RowRefreshBuilder} from '../rows/row-refresh-builder';
import {TableRenderPass} from './table-render-pass';
import {Subject} from 'rxjs';

export abstract class RowsBuilder {
  public states:States;

  protected refreshBuilder:RowRefreshBuilder;

  constructor(public workPackageTable:WorkPackageTable) {
    this.refreshBuilder = new RowRefreshBuilder(this.workPackageTable);
  }

  /**
   * Build all rows of the table.
   */
  public abstract buildRows():TableRenderPass;

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
  public refreshRow(row:WorkPackageTableRow):[HTMLElement, boolean]|null {
    let editing = this.states.editing.get(row.workPackageId).value;
    return this.refreshBuilder.refreshRow(row, editing);
  }
}

RowsBuilder.$inject = ['states'];
