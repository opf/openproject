import {States} from '../../states.service';
import {opServicesModule} from '../../../angular-modules';
import {State} from '../../../helpers/reactive-fassade';
import {WPTableRowSelectionState, WorkPackageTableRow} from '../wp-table.interfaces';

export class WorkPackageTableSelection {

  public selectionState:State<WPTableRowSelectionState>;

  constructor(public states: States) {
    this.selectionState = states.table.selection;

    if (this.selectionState.isPristine()) {
      this.reset();
    }
  }

  /**
   * Select all work packages
   */
  public selectAll(rows: WorkPackageTableRow[]) {
    const state = this._emptyState;

    rows.forEach((row) => {
      state.selected[row.workPackageId] = true;
    });

    this.selectionState.put(state);
  }


  /**
   * Reset the selection state to an empty selection
   */
  public reset() {
    this.selectionState.put(this._emptyState);
  }

  /**
   * Get current selection state.
   * @returns {WPTableRowSelectionState}
   */
  public get currentState():WPTableRowSelectionState {
    return this.selectionState.getCurrentValue();
  }

  /**
   * Return the number of selected rows.
   */
  public get selectionCount():number {
    return _.size(this.currentState.selected);
  }

  /**
   * Toggle a single row selection state and update the state.
   * @param workPackageId
   */
  public toggleRow(workPackageId:number) {
    let isSelected = this.currentState.selected[workPackageId];
    this.setRowState(workPackageId, !isSelected);
  }

  /**
   * Force the given work package's selection state. Does not modify other states.
   * @param workPackageId
   * @param newState
   */
  public setRowState(workPackageId:number, newState:boolean) {
    let state = this.currentState;
    state.selected[workPackageId] = newState;
    this.selectionState.put(state);
  }

  /**
   * Override current selection with the given work package id.
   */
  public setSelection(row:WorkPackageTableRow) {
    let state = {
      selected: {},
      activeRowIndex: row.position
    };
    state.selected[row.workPackageId] = true;

    this.selectionState.put(state);
  }

  /**
   * Select a number of rows from the current `activeRowIndex`
   * to the selected target.
   * (aka shift click expansion)
   * @param rows Current visible rows
   * @param selected Selection target
   */
  public setMultiSelectionFrom(rows:WorkPackageTableRow[], selected:WorkPackageTableRow) {
    let state = this.currentState;

    if (this.selectionCount === 0) {
      state.selected[selected.workPackageId] = true;
      state.activeRowIndex = selected.position;
    } else {
      let start = Math.min(selected.position, state.activeRowIndex);
      let end = Math.max(selected.position, state.activeRowIndex);

      rows.forEach((row, i) => {
        state.selected[row.object.id] = i >= start && i <= end;
      });
    }

    this.selectionState.put(state);
  }


  private get _emptyState() {
    return {
      selected: {},
      activeRowIndex: null
    };
  }
}

opServicesModule.service('wpTableSelection', WorkPackageTableSelection);








