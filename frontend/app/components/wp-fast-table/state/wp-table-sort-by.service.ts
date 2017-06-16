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
import {QuerySchemaResourceInterface} from '../../api/api-v3/hal-resources/query-schema-resource.service';
import {
  QUERY_SORT_BY_ASC,
  QUERY_SORT_BY_DESC,
  QuerySortByResource
} from '../../api/api-v3/hal-resources/query-sort-by-resource.service';
import {opServicesModule} from '../../../angular-modules';
import {States} from '../../states.service';
import {WorkPackageTableSortBy} from '../wp-table-sort-by';
import {QueryColumn} from '../../wp-query/query-column';
import {combine} from 'reactivestates';
import {Observable} from 'rxjs';

export class WorkPackageTableSortByService extends WorkPackageTableBaseService implements WorkPackageQueryStateService {
  protected stateName = 'sortBy' as TableStateStates;

  constructor(public states: States) {
    super(states);
  }

  public initialize(query:QueryResource) {
    let sortBy = new WorkPackageTableSortBy(query);

    this.state.putValue(sortBy);
  }

  public onReadyWithAvailable():Observable<null> {
    return combine(this.state, this.states.query.available.sortBy)
      .values$()
      .mapTo(null);
  }

  public hasChanged(query:QueryResource) {
    const comparer = (sortBy:QuerySortByResource[]) => sortBy.map(el => el.href);

    return !_.isEqual(
      comparer(query.sortBy),
      comparer(this.current.current)
    );
  }

  public applyToQuery(query:QueryResource) {
    query.sortBy = _.cloneDeep(this.current.current);
    return true;
  }

  public isSortable(column:QueryColumn):boolean {
    return !!_.find(
      this.available,
      (candidate) => candidate.column.$href === column.$href
    );
  }

  public addAscending(column:QueryColumn) {
    let available = this.findAvailableDirection(column, QUERY_SORT_BY_ASC);

    if (available) {
      this.add(available);
    }
  }

  public addDescending(column:QueryColumn) {
    let available = this.findAvailableDirection(column, QUERY_SORT_BY_DESC);

    if (available) {
      this.add(available);
    }
  }

  public findAvailableDirection(column:QueryColumn, direction:string):QuerySortByResource|undefined {
    return _.find(
      this.available,
      (candidate) => (candidate.column.$href === column.$href &&
      candidate.direction.$href === direction)
    );
  }

  public add(sortBy:QuerySortByResource) {
    let currentState = this.current;

    currentState.addCurrent(sortBy);

    this.state.putValue(currentState);
  }

  public set(sortBys:QuerySortByResource[]) {
    let currentState = this.current;

    currentState.setCurrent(sortBys);

    this.state.putValue(currentState);
  }

  private get current():WorkPackageTableSortBy {
    return this.state.value as WorkPackageTableSortBy;
  }

  private get availableState() {
    return this.states.query.available.sortBy;
  }

  public get currentSortBys():QuerySortByResource[] {
    return this.current.current;
  }

  public get available():QuerySortByResource[] {
    return this.availableState.getValueOr([]);
  }
}

opServicesModule.service('wpTableSortBy', WorkPackageTableSortByService);
