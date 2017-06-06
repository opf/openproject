import {QueryResource} from '../../api/api-v3/hal-resources/query-resource.service';
import {InputState} from "reactivestates";
import {opServicesModule} from "../../../angular-modules";
import {States} from "../../states.service";
import {
  TableStateStates, WorkPackageQueryStateService,
  WorkPackageTableBaseService
} from './wp-table-base.service';
import { WorkPackageTableHierarchies } from "../wp-table-hierarchies";

export class WorkPackageTableHierarchiesService extends WorkPackageTableBaseService implements WorkPackageQueryStateService {
  protected stateName = 'hierarchies' as TableStateStates;

  constructor(public states:States) {
    super(states);
  }

  public initialize(query:QueryResource) {
    let current = new WorkPackageTableHierarchies(query.showHierarchies);
    this.state.putValue(current);
  }

  public hasChanged(query:QueryResource) {
    return query.showHierarchies !== this.isEnabled;
  }

  public applyToQuery(query:QueryResource) {
    query.showHierarchies = this.isEnabled;
    return false;
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

opServicesModule.service('wpTableHierarchies', WorkPackageTableHierarchiesService);
