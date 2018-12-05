//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
//++

import {Injectable} from '@angular/core';
import {WorkPackageTableSelection} from 'core-components/wp-fast-table/state/wp-table-selection.service';
import {TableState} from 'core-components/wp-table/table-state/table-state';
import {InputState} from 'reactivestates';
import {Observable} from 'rxjs';
import {distinctUntilChanged, filter, map} from 'rxjs/operators';
import {States} from '../../states.service';

export interface WPFocusState {
  workPackageId:string;
  focusAfterRender:boolean;
}

@Injectable()
export class WorkPackageTableFocusService {

  public state:InputState<WPFocusState>;

  constructor(public states:States,
              public tableState:TableState,
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

  public get focusedWorkPackage():string | null {
    const value = this.state.value;

    if (value) {
      return value.workPackageId;
    }

    return null;
  }

  public clear() {
    this.state.clear();
  }

  public whenChanged():Observable<string> {
    return this.state.values$()
      .pipe(
        map((val:WPFocusState) => val.workPackageId),
        distinctUntilChanged()
      );
  }

  public updateFocus(workPackageId:string, setFocusAfterRender:boolean = false) {
    // Set the selection to this row, if nothing else is selected.
    if (this.wpTableSelection.isEmpty) {
      this.wpTableSelection.setRowState(workPackageId, true);
    }
    this.state.putValue({workPackageId: workPackageId, focusAfterRender: setFocusAfterRender});
  }

  /**
   * Put the first row that is eligible to be displayed in the details view into
   * the focused state if no manual selection has been made yet.
   */
  private observeToUpdateFocused() {
    this
      .tableState.rendered
      .values$()
      .pipe(
        map(state => _.find(state, (row:any) => row.workPackageId)),
        filter(fullRow => !!fullRow && this.wpTableSelection.isEmpty)
      )
      .subscribe((fullRow:any) => {
        this.updateFocus(fullRow!.workPackageId);
      });
  }
}
