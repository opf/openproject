//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import {Injectable} from '@angular/core';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {Observable} from 'rxjs';
import {distinctUntilChanged, map} from 'rxjs/operators';
import {WorkPackageViewSelectionService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-selection.service";
import {WorkPackageViewBaseService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-base.service";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {WorkPackageCollectionResource} from "core-app/modules/hal/resources/wp-collection-resource";

export interface WPFocusState {
  workPackageId:string;
  focusAfterRender:boolean;
}

@Injectable()
export class WorkPackageViewFocusService extends WorkPackageViewBaseService<WPFocusState> {

  constructor(public querySpace:IsolatedQuerySpace,
              public wpTableSelection:WorkPackageViewSelectionService) {
    super(querySpace);
  }

  public isFocused(workPackageId:string) {
    return this.focusedWorkPackage === workPackageId;
  }

  public ifShouldFocus(callback:(workPackageId:string) => void) {
    const value = this.current;

    if (value && value.focusAfterRender) {
      callback(value.workPackageId);
      value.focusAfterRender = false;
      this.update(value);
    }
  }

  public get focusedWorkPackage():string|null {
    const value = this.current;

    if (value) {
      return value.workPackageId;
    }

    // Return the first result if none selected
    const results = this.querySpace.results.value;
    if (results && results.elements.length > 0) {
      return results.elements[0].id!.toString();
    }

    return null;
  }

  public whenChanged():Observable<string> {
    return this.live$()
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
    this.update({ workPackageId: workPackageId, focusAfterRender: setFocusAfterRender });
  }

  valueFromQuery(query:QueryResource, results:WorkPackageCollectionResource):WPFocusState|undefined {
    return undefined;
  }
}
