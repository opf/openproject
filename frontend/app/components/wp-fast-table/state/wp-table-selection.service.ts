import {States} from '../../states.service';
import {opServicesModule} from '../../../angular-modules';
import {State} from '../../../helpers/reactive-fassade';
import {WPTableRowSelectionState, WorkPackageTableRow} from '../wp-table.interfaces';

export class WorkPackageTableSelection {

  private selectionState:State<WPTableRowSelectionState>;

  constructor(public states: States) {
    this.selectionState = states.table.selection;

    if (this.selectionState.isPristine()) {
      this.reset();
    }
  }

  /**
   * Select all work packages
   */
  public selectAll() {
    const value = this.currentState;
    value.all = true;
    this.selectionState.put(value);
  }


  /**
   * Reset the selection state to an empty selection
   */
  public reset() {
    this.selectionState.put({
      activeRowIndex: null,
      all: false,
      selected: {}
    });
  }

  /**
   * Get current selection state.
   * @returns {WPTableRowSelectionState}
   */
  public get currentState():WPTableRowSelectionState {
    return this.selectionState.getCurrentValue();
  }

  /**
   * Return the number of selected rows
   * (does not correctly reflect count when `all` is set.
   */
  public get selectionCount():number {
    return _.size(this.currentState.selected);
  }

  /**
   * Toggle a single row selection state and update the state.
   * @param workPackageId
   */
  public toggleRow(workPackageId:number) {
    this.setRowState(workPackageId, !this.currentState.selected[workPackageId]);
  }

  /**
   * Force the given work package's selection state.
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
    let state = this.currentState;
    state.selected = {};
    state.selected[row.workPackageId] = true;
    state.activeRowIndex = row.position;

    this.selectionState.put(state);
  }

  /**
   * Select a number of rows from the current `activeRowIndex`
   * to the selected target.
   * (aka shift click expansion)
   * @param rows Current visible rows
   * @param selected Selection target
   */
  public setMultiSelectionFrom(rows:WorkPackageTableRow[], selected) {
    let state = this.currentState;

    if (this.selectionCount === 0) {
      state.selected[selected.workPackageId] = true;
      state.activeRowIndex = selected.index;
    } else {
      let start = Math.min(selected.index, state.activeRowIndex);
      let end = Math.max(selected.index, state.activeRowIndex);

      rows.forEach((row, i) => {
        state.selected[row.workPackageId] = i >= start && i <= end;
      });
    }

    this.selectionState.put(state);
  }
}

opServicesModule.service('wpTableSelection', WorkPackageTableSelection);








