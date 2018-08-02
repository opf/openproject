import {WPTableRowSelectionState} from '../wp-table.interfaces';
import {RenderedRow} from '../builders/primary-render-pass';
import {InputState} from 'reactivestates';
import {TableState} from 'core-components/wp-table/table-state/table-state';
import {WorkPackageCacheService} from 'core-components/work-packages/work-package-cache.service';
import {Injectable} from '@angular/core';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {States} from 'core-components/states.service';

@Injectable()
export class WorkPackageTableSelection {

  public selectionState:InputState<WPTableRowSelectionState>;

  public constructor(readonly tableState:TableState,
                     readonly states:States,
                     readonly wpCacheService:WorkPackageCacheService) {
    this.selectionState = tableState.selection;

    if (this.selectionState.isPristine()) {
      this.reset();
    }
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
    return this.getSelectedWorkPackageIds().map(id => wpState.get(id).value!);
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

  public get isEmpty() {
    return this.selectionCount === 0;
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

    // If there are no other selections, it does not matter what the index is
    if (this.selectionCount === 0 || state.activeRowIndex === null) {
      state.selected[wpId] = true;
      state.activeRowIndex = position;
    } else {
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
}
