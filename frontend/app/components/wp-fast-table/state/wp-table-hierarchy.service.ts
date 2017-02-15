import {WorkPackageTableMetadata} from '../wp-table-metadata';
import {States} from '../../states.service';
import {opServicesModule} from '../../../angular-modules';
import {State} from '../../../helpers/reactive-fassade';
import {WPTableHierarchyCollapsedState} from '../wp-table.interfaces';

export class WorkPackageTableHierarchyService {

  // The selected columns state of the current table instance
  public hierarchyState:State<WPTableHierarchyCollapsedState>;

  constructor(public states: States, public QueryService:any) {
    this.hierarchyState = states.table.collapsedHierarchies;
  }

  /**
   * Return whether the given wp ID is collapsed.
   */
  public collapsed(wpId:string):boolean {
    return this.currentState[wpId] === true;
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
    state[wpId] = isCollapsed;
    this.hierarchyState.put(state);
  }

  /**
   * Get current selection state.
   */
  public get currentState():WPTableHierarchyCollapsedState {
    const state = this.hierarchyState.getCurrentValue();

    if (state == null) {
      return this.initialState;
    }

    return state;
  }

  private get initialState():WPTableHierarchyCollapsedState {
    return {} as WPTableHierarchyCollapsedState;
  }

}

opServicesModule.service('wpTableHierarchy', WorkPackageTableHierarchyService);