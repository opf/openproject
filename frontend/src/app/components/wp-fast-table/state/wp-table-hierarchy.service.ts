import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {InputState} from 'reactivestates';
import {WorkPackageQueryStateService} from './wp-table-base.service';
import {WorkPackageTableHierarchies} from '../wp-table-hierarchies';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {Injectable} from '@angular/core';
import {WorkPackageTableSortByService} from "core-components/wp-fast-table/state/wp-table-sort-by.service";
import {WorkPackageTableGroupByService} from "core-components/wp-fast-table/state/wp-table-group-by.service";

@Injectable()
export class WorkPackageTableHierarchiesService extends WorkPackageQueryStateService<WorkPackageTableHierarchies> {
  public constructor(protected readonly querySpace:IsolatedQuerySpace,
                     protected wpTableGroupBy:WorkPackageTableGroupByService,
                     protected wpTableSortBy:WorkPackageTableSortByService) {
    super(querySpace);
  }

  public get state():InputState<WorkPackageTableHierarchies> {
    return this.querySpace.hierarchies;
  }

  public valueFromQuery(query:QueryResource):WorkPackageTableHierarchies {
    const value =  new WorkPackageTableHierarchies(query.showHierarchies);
    const current = this.current;

    // Take over current collapsed values
    // which are not yet saved
    if (current) {
      value.collapsed = current.collapsed;
    }

    return value;
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
    return !!(this.current && this.current.isVisible);
  }

  public setEnabled(active:boolean = true) {
    const state = { collapsed: {}, ...this.current, isVisible: active, last: null };

    if (active) {
      // hierarchies and group by are mutually exclusive
      this.wpTableGroupBy.update(null);
    }

    this.update(state);
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
    return this.currentState.collapsed[wpId];
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

    if (state === undefined) {
      return this.initialState;
    }

    return state;
  }

  private get initialState():WorkPackageTableHierarchies {
    return new WorkPackageTableHierarchies(false);
  }
}
