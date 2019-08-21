import {input} from 'reactivestates';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {WorkPackageCacheService} from 'core-components/work-packages/work-package-cache.service';
import {Injectable, OnDestroy} from '@angular/core';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {States} from 'core-components/states.service';
import {OPContextMenuService} from "core-components/op-context-menu/op-context-menu.service";
import {RenderedWorkPackage} from "core-app/modules/work_packages/render-info/rendered-work-package.type";

export interface WorkPackageViewSelectionState {
  // Map of selected rows
  selected:{[workPackageId:string]:boolean};
  // Index of current selection
  // required for shift-offsets
  activeRowIndex:number | null;
}

@Injectable()
export class WorkPackageViewSelectionService implements OnDestroy {

  private selectionState = input<WorkPackageViewSelectionState>();

  public constructor(readonly querySpace:IsolatedQuerySpace,
                     readonly states:States,
                     readonly wpCacheService:WorkPackageCacheService,
                     readonly opContextMenu:OPContextMenuService) {
    this.reset();
  }

  ngOnDestroy():void {
    Mousetrap.unbind(['command+d', 'ctrl+d']);
    Mousetrap.unbind(['command+a', 'ctrl+a']);
  }

  public isSelected(workPackageId:string) {
    return this.currentState.selected[workPackageId];
  }

  /**
   * Select all work packages
   */
  public selectAll(rows:RenderedWorkPackage[]) {
    const state:WorkPackageViewSelectionState = this._emptyState;

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
   * Observe selection state
   */
  public selection$() {
    return this.selectionState.values$();
  }

  /**
   * Get current selection state.
   * @returns {WorkPackageViewSelectionState}
   */
  public get currentState():WorkPackageViewSelectionState {
    return this.selectionState.value as WorkPackageViewSelectionState;
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
    let state:WorkPackageViewSelectionState = {
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
  public setMultiSelectionFrom(rows:RenderedWorkPackage[], wpId:string, position:number) {
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

  public registerSelectAllListener(renderedElements:() => RenderedWorkPackage[]) {
    // Bind CTRL+A to select all work packages
    Mousetrap.bind(['command+a', 'ctrl+a'], (e) => {
      this.selectAll(renderedElements());
      e.preventDefault();

      this.opContextMenu.close();
      return false;
    });
  }

  public registerDeselectAllListener() {
    // Bind CTRL+D to deselect all work packages
    Mousetrap.bind(['command+d', 'ctrl+d'], (e) => {
      this.reset();
      e.preventDefault();

      this.opContextMenu.close();
      return false;
    });
  }

  private get _emptyState():WorkPackageViewSelectionState {
    return {
      selected: {},
      activeRowIndex: null
    };
  }
}
