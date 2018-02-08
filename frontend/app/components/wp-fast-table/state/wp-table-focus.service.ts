import {States} from '../../states.service';
import {opServicesModule} from '../../../angular-modules';
import {WorkPackageResource} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {InputState} from 'reactivestates';
import {WorkPackageTableSelection} from 'core-components/wp-fast-table/state/wp-table-selection.service';

export interface WPFocusState {
  workPackageId:string;
  focusAfterRender:boolean;
}

export class WorkPackageTableFocusService {

  public state:InputState<WPFocusState>;

  constructor(public states:States,
              public wpTableSelection:WorkPackageTableSelection) {
    this.state = states.focusedWorkPackage;
    this.observeToUpdateFocused();
  }

  public isFocused(workPackageId:string) {
    return this.focusedWorkPackage === workPackageId;
  }

  public ifShouldFocus(callback:(workPackageId:string) => void) {
    const value = this.state.value;

    if (value && value.focusAfterRender) {
      callback(value.workPackageId);
      value.focusAfterRender = false;
      this.state.putValue(value, 'Setting focus to false after callback.');
    }
  }

  public get focusedWorkPackage():string|null {
    const value = this.state.value;

    if (value) {
      return value.workPackageId;
    }

    return null;
  }

  public clear() {
    this.state.clear();
  }

  public whenChanged() {
    return this.state.values$()
    .map((val:WPFocusState) => val.workPackageId)
    .distinctUntilChanged();
  }

  public updateFocus(workPackageId:string, setFocusAfterRender:boolean = false) {
    // Set the selection to this row, if nothing else is selected.
    if (this.wpTableSelection.isEmpty) {
      this.wpTableSelection.setRowState(workPackageId, true);
    }
    this.state.putValue({ workPackageId: workPackageId, focusAfterRender: setFocusAfterRender});
  }

  /**
   * Put the first row that is eligible to be displayed in the details view into
   * the focused state if no manual selection has been made yet.
   */
  private observeToUpdateFocused() {
    this
      .states.globalTable.rendered
      .values$()
      .map(state => _.find(state, (row:any) => row.workPackageId))
      .filter(fullRow => !!fullRow && this.wpTableSelection.isEmpty)
      .subscribe(fullRow => {
        this.updateFocus(fullRow!.workPackageId!);
      });
  }
}

opServicesModule.service('wpTableFocus', WorkPackageTableFocusService);
