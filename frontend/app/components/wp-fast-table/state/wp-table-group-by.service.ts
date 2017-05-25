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
  QueryResource,
  QueryColumn
} from '../../api/api-v3/hal-resources/query-resource.service';
import {QuerySchemaResourceInterface} from '../../api/api-v3/hal-resources/query-schema-resource.service';
import {QueryGroupByResource} from '../../api/api-v3/hal-resources/query-group-by-resource.service';
import {opServicesModule} from '../../../angular-modules';
import {
  States
} from '../../states.service';
import {WorkPackageTableGroupBy} from '../wp-table-group-by';
import {
  WorkPackageTableBaseService,
  TableStateStates
} from './wp-table-base.service';

export class WorkPackageTableGroupByService extends WorkPackageTableBaseService {
  protected stateName = 'groupBy' as TableStateStates;

  constructor(protected states: States) {
    super(states)
  }

  public initialize(query:QueryResource, schema?:QuerySchemaResourceInterface) {
    let state = this.create(query, schema);

    this.state.putValue(state);
  }

  public update(query:QueryResource, schema?:QuerySchemaResourceInterface) {
    let currentState = this.currentState;

    if (currentState) {
      currentState.update(query, schema);
      this.state.putValue(currentState);
    } else {
      this.initialize(query, schema);
    }
  }

  protected create(query:QueryResource, schema?:QuerySchemaResourceInterface) {
    return new WorkPackageTableGroupBy(query, schema)
  }

  public isGroupable(column:QueryColumn):boolean {
    return !!this.currentState.isGroupable(column);
  }

  public set(groupBy:QueryGroupByResource) {
    let currentState = this.currentState;

    currentState.current = groupBy;

    this.state.putValue(currentState);
  }

  public setBy(column:QueryColumn) {
    let currentState = this.currentState;

    currentState.setBy(column);

    this.state.putValue(currentState);
  }

  protected get currentState():WorkPackageTableGroupBy {
    return this.state.value as WorkPackageTableGroupBy;
  }

  public get current():QueryGroupByResource|undefined {
    if (this.currentState) {
      return this.currentState.current;
    } else {
      return undefined;
    }
  }

  public get isEnabled():boolean {
    return !!this.current;
  }

  public get available():QueryGroupByResource[] {
    return this.currentState.available;
  }

  public isCurrentlyGroupedBy(column:QueryColumn):boolean {
    return this.currentState.isCurrentlyGroupedBy(column);
  }
}

opServicesModule.service('wpTableGroupBy', WorkPackageTableGroupByService);
