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

import {QueryResource} from '../../api/api-v3/hal-resources/query-resource.service';
import {QuerySchemaResourceInterface} from '../../api/api-v3/hal-resources/query-schema-resource.service';
import {QueryGroupByResource} from '../../api/api-v3/hal-resources/query-group-by-resource.service';
import {opServicesModule} from '../../../angular-modules';
import {States} from '../../states.service';
import {WorkPackageTableGroupBy} from '../wp-table-group-by';
import {
  TableStateStates,
  WorkPackageQueryStateService,
  WorkPackageTableBaseService
} from './wp-table-base.service';
import {QueryColumn} from '../../wp-query/query-column';

export class WorkPackageTableGroupByService extends WorkPackageTableBaseService implements WorkPackageQueryStateService {
  protected stateName = 'groupBy' as TableStateStates;

  constructor(protected states:States) {
    super(states);
  }

  public initialize(query:QueryResource) {
    this.state.putValue(new WorkPackageTableGroupBy(query));
  }

  public update(query:QueryResource) {
    let currentState = this.currentState;

    if (currentState) {
      currentState.update(query);
      this.state.putValue(currentState);
    } else {
      this.initialize(query);
    }
  }

  public hasChanged(query:QueryResource) {
    const comparer = (groupBy:QueryColumn|undefined) => groupBy ? groupBy.href : null;

    return !_.isEqual(
      comparer(query.groupBy),
      comparer(this.current)
    );
  }

  public applyToQuery(query:QueryResource) {
    query.groupBy = _.cloneDeep(this.current);
    return true;
  }

  public isGroupable(column:QueryColumn):boolean {
    return !!_.find(this.available, candidate => candidate.id === column.id);
  }

  public set(groupBy:QueryGroupByResource|undefined) {
    let currentState = this.currentState;

    currentState.current = groupBy;

    // hierarchies and group by are mutually exclusive
    if (groupBy) {
      var hierarchy = this.states.table.hierarchies.value!;
      hierarchy.current = false;
      this.states.table.hierarchies.putValue(hierarchy);
    }

    this.state.putValue(currentState);
  }

  public setBy(column:QueryColumn) {
    let currentState = this.currentState;
    let groupBy = _.find(this.available, candidate => candidate.id === column.id);

    if (groupBy) {
      this.set(groupBy);
    }
  }

  protected get currentState():WorkPackageTableGroupBy {
    return this.state.value as WorkPackageTableGroupBy;
  }

  protected get availableState() {
    return this.states.query.available.groupBy;
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
    return this.availableState.getValueOr([]);
  }

  public isCurrentlyGroupedBy(column:QueryColumn):boolean {
    return !!(this.current && this.current.id === column.id);
  }
}

opServicesModule.service('wpTableGroupBy', WorkPackageTableGroupByService);
