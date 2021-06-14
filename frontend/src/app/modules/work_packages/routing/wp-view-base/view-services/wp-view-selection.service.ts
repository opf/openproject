import { IsolatedQuerySpace } from "core-app/modules/work_packages/query-space/isolated-query-space";
import { Injectable, OnDestroy } from '@angular/core';
import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';
import { States } from 'core-components/states.service';
import { OPContextMenuService } from "core-components/op-context-menu/op-context-menu.service";
import { RenderedWorkPackage } from "core-app/modules/work_packages/render-info/rendered-work-package.type";
import { WorkPackageViewBaseService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-base.service";
import { QueryResource } from "core-app/modules/hal/resources/query-resource";
import { WorkPackageCollectionResource } from "core-app/modules/hal/resources/wp-collection-resource";

export interface WorkPackageViewSelectionState {
  // Map of selected rows
  selected:{ [workPackageId:string]:boolean };
  // Index of current selection
  // required for shift-offsets
  activeRowIndex:number|null;
}

@Injectable()
export class WorkPackageViewSelectionService extends WorkPackageViewBaseService<WorkPackageViewSelectionState> implements OnDestroy {

  public constructor(readonly querySpace:IsolatedQuerySpace,
                     readonly states:States,
                     readonly opContextMenu:OPContextMenuService) {
    super(querySpace);
    this.reset();
  }

  ngOnDestroy():void {
    Mousetrap.unbind(['command+d', 'ctrl+d']);
    Mousetrap.unbind(['command+a', 'ctrl+a']);
  }

  public initializeSelection(selectedWorkPackageIds:string[]) {
    const state:WorkPackageViewSelectionState = {
      selected: {},
      activeRowIndex: null
    };

    selectedWorkPackageIds.forEach(id => state.selected[id] = true);

    this.updatesState.clear();
    this.pristineState.putValue(state);
  }

  public isSelected(workPackageId:string):boolean {
    return !!this.current?.selected[workPackageId];
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

    this.update(state);
  }

  /**
   * Get the current work package resource form the selection state.
   */
  public getSelectedWorkPackages():WorkPackageResource[] {
    const wpState = this.states.workPackages;
    return this.getSelectedWorkPackageIds().map(id => wpState.get(id).value!);
  }

  public getSelectedWorkPackageIds():string[] {
    const selected:string[] = [];

    _.each(this.current?.selected, (isSelected:boolean, wpId:string) => {
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
    this.update(this._emptyState);
  }

  public get isEmpty() {
    return this.selectionCount === 0;
  }

  /**
   * Return the number of selected rows.
   */
  public get selectionCount():number {
    return _.size(this.current?.selected);
  }

  /**
   * Toggle a single row selection state and update the state.
   * @param workPackageId
   */
  public toggleRow(workPackageId:string) {
    const isSelected = this.current?.selected[workPackageId];
    this.setRowState(workPackageId, !isSelected);
  }

  /**
   * Force the given work package's selection state. Does not modify other states.
   * @param workPackageId
   * @param newState
   */
  public setRowState(workPackageId:string, newState:boolean) {
    const state = this.current || this._emptyState;
    state.selected[workPackageId] = newState;
    this.update(state);
  }

  /**
   * Override current selection with the given work package id.
   */
  public setSelection(wpId:string, position:number) {
    const current = this._emptyState;
    current.selected[wpId] = true;
    current.activeRowIndex = position;

    this.update(current);
  }

  /**
   * Select a number of rows from the current `activeRowIndex`
   * to the selected target.
   * (aka shift click expansion)
   */
  public setMultiSelectionFrom(rows:RenderedWorkPackage[], wpId:string, position:number) {
    const state = this.current || this._emptyState;

    // If there are no other selections, it does not matter what the index is
    if (this.selectionCount === 0 || state.activeRowIndex === null) {
      state.selected[wpId] = true;
      state.activeRowIndex = position;
    } else {
      const start = Math.min(position, state.activeRowIndex);
      const end = Math.max(position, state.activeRowIndex);

      rows.forEach((row, i) => {
        if (row.workPackageId) {
          state.selected[row.workPackageId] = i >= start && i <= end;
        }
      });
    }

    this.update(state);
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

  valueFromQuery(query:QueryResource, results:WorkPackageCollectionResource):WorkPackageViewSelectionState|undefined {
    return undefined;
  }
}

