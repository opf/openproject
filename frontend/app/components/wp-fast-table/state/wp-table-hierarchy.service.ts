import {States} from '../../states.service';
import {opServicesModule} from '../../../angular-modules';
import {State} from '../../../helpers/reactive-fassade';
import {WPTableHierarchyState} from '../wp-table.interfaces';

export class WorkPackageTableHierarchyService {

  // The selected columns state of the current table instance
  public hierarchyState:State<WPTableHierarchyState>;

  constructor(public states: States) {
    this.hierarchyState = states.table.hierarchies;
  }

  /**
   * Return whether the current hierarchy mode is active
   */
   public get isEnabled():boolean {
    return this.currentState.enabled;
   }

   public setEnabled(active:boolean = true) {
     const state = this.currentState;
     state.enabled = active;

     this.hierarchyState.put(state);
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
    this.hierarchyState.put(state);
  }

  /**
   * Get current selection state.
   */
  public get currentState():WPTableHierarchyState {
    const state = this.hierarchyState.getCurrentValue();

    if (state == null) {
      return this.initialState;
    }

    return state;
  }

  private get initialState():WPTableHierarchyState {
    return {
      enabled: false,
      collapsed: {}
    } as WPTableHierarchyState;
  }

}

opServicesModule.service('wpTableHierarchy', WorkPackageTableHierarchyService);
