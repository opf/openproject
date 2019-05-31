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

import {States} from 'core-components/states.service';
import {combine, InputState} from 'reactivestates';
import {mapTo} from 'rxjs/operators';
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {QueryColumn} from '../../wp-query/query-column';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {Injectable} from '@angular/core';
import {WorkPackageQueryStateService} from './wp-table-base.service';
import {Observable} from 'rxjs';
import {
  QUERY_SORT_BY_ASC,
  QUERY_SORT_BY_DESC,
  QuerySortByResource
} from 'core-app/modules/hal/resources/query-sort-by-resource';

@Injectable()
export class WorkPackageTableSortByService extends WorkPackageQueryStateService<QuerySortByResource[]> {

  constructor(protected readonly states:States,
              protected readonly querySpace:IsolatedQuerySpace) {
    super(querySpace);
  }


  public get state():InputState<QuerySortByResource[]> {
    return this.querySpace.sortBy;
  }

  public valueFromQuery(query:QueryResource) {
    return [...query.sortBy];
  }

  public onReadyWithAvailable():Observable<null> {
    return combine(this.state, this.states.queries.sortBy)
      .values$()
      .pipe(
        mapTo(null)
      );
  }

  public hasChanged(query:QueryResource) {
    const comparer = (sortBy:QuerySortByResource[]) => sortBy.map(el => el.href);

    return !_.isEqual(
      comparer(query.sortBy),
      comparer(this.current)
    );
  }

  public applyToQuery(query:QueryResource) {
    query.sortBy = [...this.current];
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

  public findAvailableDirection(column:QueryColumn, direction:string):QuerySortByResource | undefined {
    return _.find(
      this.available,
      (candidate) => (candidate.column.$href === column.$href &&
        candidate.direction.$href === direction)
    );
  }

  public add(sortBy:QuerySortByResource) {
    this.state.doModify((current:QuerySortByResource[]) => {
      let newValue = [sortBy, ...current];
      return _
        .uniqBy(newValue, sortBy => sortBy.column.$href)
        .slice(0, 3);

      return current.concat(sortBy);
    });
  }

  public get current():QuerySortByResource[] {
    return this.state.getValueOr([]);
  }

  private get availableState() {
    return this.states.queries.sortBy;
  }

  public get available():QuerySortByResource[] {
    return this.availableState.getValueOr([]);
  }
}
