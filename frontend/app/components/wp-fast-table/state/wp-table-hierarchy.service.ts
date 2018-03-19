import {QueryResource} from '../../api/api-v3/hal-resources/query-resource.service';
import {WorkPackageQueryStateService, WorkPackageTableBaseService} from './wp-table-base.service';
import {WorkPackageTableHierarchies} from '../wp-table-hierarchies';
import {TableState} from 'core-components/wp-table/table-state/table-state';
import {Injectable} from '@angular/core';

@Injectable()
export class WorkPackageTableHierarchiesService extends WorkPackageTableBaseService<WorkPackageTableHierarchies> implements WorkPackageQueryStateService {
  public constructor(tableState:TableState) {
    super(tableState);
  }

  public get state() {
    return this.tableState.hierarchies;
  }

  public valueFromQuery(query:QueryResource):WorkPackageTableHierarchies|undefined {
    return new WorkPackageTableHierarchies(query.showHierarchies);
  }

  public hasChanged(query:QueryResource) {
    return query.showHierarchies !== this.isEnabled;
  }

  public applyToQuery(query:QueryResource) {
    query.showHierarchies = this.isEnabled;

    // We need to visibly load the ancestors when the mode is activated.
    return this.isEnabled;
  }

  /**
   * Return whether the current hierarchy mode is active
   */
  public get isEnabled():boolean {
    return this.currentState.isEnabled;
  }

  public setEnabled(active:boolean = true) {
    const state = this.currentState;
    state.current = active;
    state.last = null;

    // hierarchies and group by are mutually exclusive
    if (active) {
      var groupBy = this.tableState.groupBy.value!;
      groupBy.current = undefined;
      this.tableState.groupBy.putValue(groupBy);
    }

    this.state.putValue(state);
  }

  /**
   * Toggle the hierarchy state
   */
  public toggleState() {
    this.setEnabled(!this.isEnabled);
  }

  /**
   * Return whether the given wp ID is collapsed.
   */
  public collapsed(wpId:string):boolean {
    return this.currentState.collapsed[wpId] === true;
  }

  /**
   * Collapse the hierarchy for this work package
   */
  public collapse(wpId:string):void {
    this.setState(wpId, true);
  }

  /**
   * Expand the hierarchy for this work package
   */
  public expand(wpId:string):void {
    this.setState(wpId, false);
  }

  /**
   * Toggle the hierarchy state
   */
  public toggle(wpId:string):void {
    this.setState(wpId, !this.collapsed(wpId));
  }

  /**
   * Set the collapse/expand state of the given work package id.
   */
  private setState(wpId:string, isCollapsed:boolean):void {
    const state = this.currentState;
    state.collapsed[wpId] = isCollapsed;
    state.last = wpId;
    this.state.putValue(state);
  }

  /**
   * Get current selection state.
   */
  public get currentState():WorkPackageTableHierarchies {
    const state = this.state.value;

    if (state == null) {
      return this.initialState;
    }

    return state as WorkPackageTableHierarchies;
  }

  private get initialState():WorkPackageTableHierarchies {
    return new WorkPackageTableHierarchies(false);
  }
}

