// -- copyright
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
// ++

import {
  TableStateStates,
  WorkPackageQueryStateService,
  WorkPackageTableBaseService
} from './wp-table-base.service';
import {QueryResource} from '../../api/api-v3/hal-resources/query-resource.service';
import {opServicesModule} from '../../../angular-modules';
import {States} from '../../states.service';
import {WorkPackageTableSum} from '../wp-table-sum';

export class WorkPackageTableSumService extends WorkPackageTableBaseService implements WorkPackageQueryStateService {
  protected stateName = 'sum' as TableStateStates;

  constructor(public states: States) {
    super(states);
  }

  public initialize(query:QueryResource) {
    let sum = new WorkPackageTableSum(query.sums);

    this.state.putValue(sum);
  }

  public hasChanged(query:QueryResource) {
    return query.sums !== this.isEnabled;
  }

  public applyToQuery(query:QueryResource) {
    query.sums = this.isEnabled;
    return true;
  }

  public toggle() {
    let currentState = this.current;

    currentState.toggle();

    this.state.putValue(currentState);
  }

  public get isEnabled() {
    return this.current.isEnabled;
  }

  private get current():WorkPackageTableSum {
    return this.state.value as WorkPackageTableSum;
  }

  public get currentSum():boolean|undefined {
    if (this.current) {
      return this.current.current;
    } else {
      return undefined;
    }
  }
}

opServicesModule.service('wpTableSum', WorkPackageTableSumService);
