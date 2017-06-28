import {States} from '../../states.service';
import {opServicesModule} from '../../../angular-modules';
import {WPTableRowSelectionState} from '../wp-table.interfaces';
import {WorkPackageResource} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {RenderedRow} from '../builders/primary-render-pass';
import {InputState} from 'reactivestates';

export class WorkPackageTableSelection {

  public selectionState:InputState<WPTableRowSelectionState>;

  constructor(public states:States) {
    this.selectionState = states.table.selection;

    if (this.selectionState.isPristine()) {
      this.reset();
    }

    this.observeToUpdateFocused();
  }

  public isSelected(workPackageId:string) {
    return this.currentState.selected[workPackageId];
  }

  /**
   * Select all work packages
   */
  public selectAll(rows: RenderedRow[]) {
    const state:WPTableRowSelectionState = this._emptyState;

    rows.forEach((row) => {
      if (row.workPackageId) {
        state.selected[row.workPackageId] = true;
      }
    });

    this.selectionState.putValue(state);
  }

  /**
   * Get the current work package resource form the selection state.
   */
  public getSelectedWorkPackages():WorkPackageResource[] {
    let wpState = this.states.workPackages;
    return this.getSelectedWorkPackageIds().map(id => wpState.get(id).value as WorkPackageResource);
  }

  public getSelectedWorkPackageIds():string[] {
    let selected:string[] = [];

    _.each(this.currentState.selected, (isSelected:boolean, wpId:string) => {
      if (isSelected) {
        selected.push(wpId);
      }
    });

    return selected;
  }

  /**
   * Reset the selection state to an empty selection
   */
  public reset() {
    this.selectionState.putValue(this._emptyState);
  }

  /**
   * Get current selection state.
   * @returns {WPTableRowSelectionState}
   */
  public get currentState():WPTableRowSelectionState {
    return this.selectionState.value as WPTableRowSelectionState;
  }

  /**
   * Return the number of selected rows.
   */
  public get selectionCount():number {
    return _.size(this.currentState.selected);
  }

  /**
   * Switch the current focused work package to the given id,
   * setting selection and focus on this WP.
   */
  public focusOn(workPackgeId:string) {
    let newState = this._emptyState;
    newState.selected[workPackgeId] = true;
    this.selectionState.putValue(newState);
    this.states.focusedWorkPackage.putValue(workPackgeId);
  }

  /**
   * Toggle a single row selection state and update the state.
   * @param workPackageId
   */
  public toggleRow(workPackageId:string) {
    let isSelected = this.currentState.selected[workPackageId];
    this.setRowState(workPackageId, !isSelected);
  }

  /**
   * Force the given work package's selection state. Does not modify other states.
   * @param workPackageId
   * @param newState
   */
  public setRowState(workPackageId:string, newState:boolean) {
    let state = this.currentState;
    state.selected[workPackageId] = newState;
    this.selectionState.putValue(state);
  }

  /**
   * Override current selection with the given work package id.
   */
  public setSelection(wpId:string, position:number) {
    let state:WPTableRowSelectionState = {
      selected: {},
      activeRowIndex: position
    };
    state.selected[wpId] = true;

    this.selectionState.putValue(state);
  }

  /**
   * Select a number of rows from the current `activeRowIndex`
   * to the selected target.
   * (aka shift click expansion)
   */
  public setMultiSelectionFrom(rows:RenderedRow[], wpId:string, position:number) {
    let state = this.currentState;

    if (this.selectionCount === 0) {
      state.selected[wpId] = true;
      state.activeRowIndex = position;
    } else if (state.activeRowIndex !== null) {
      let start = Math.min(position, state.activeRowIndex);
      let end = Math.max(position, state.activeRowIndex);

      rows.forEach((row, i) => {
        if (row.workPackageId) {
          state.selected[row.workPackageId] = i >= start && i <= end;
        }
      });
    }

    this.selectionState.putValue(state);
  }


  private get _emptyState():WPTableRowSelectionState {
    return {
      selected: {},
      activeRowIndex: null
    };
  }

  /**
   * Put the first row that is eligible to be displayed in the details view into
   * the focused state if no manual selection has been made yet.
   */
  private observeToUpdateFocused() {
    this
      .states.table.rendered
      .values$()
      .map(state => _.find(state, row => row.workPackageId))
      .filter(fullRow => !!fullRow && _.isEmpty(this.currentState.selected))
      .subscribe(fullRow => {
        this.states.focusedWorkPackage.putValue(fullRow!.workPackageId!);
      });
  }
}

opServicesModule.service('wpTableSelection', WorkPackageTableSelection);
