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
import {QuerySortByResource} from 'core-app/modules/hal/resources/query-sort-by-resource';
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";

@Injectable()
export class WorkPackageTableSortByService extends WorkPackageQueryStateService<QuerySortByResource[]> {

  constructor(protected readonly states:States,
              protected readonly querySpace:IsolatedQuerySpace,
              protected readonly pathHelper:PathHelperService) {
    super(querySpace);
  }

  public valueFromQuery(query:QueryResource) {
    return [...query.sortBy];
  }

  public onReadyWithAvailable():Observable<null> {
    return combine(this.pristineState, this.states.queries.sortBy)
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
    return !this.isManualSortingMode;
  }

  public isSortable(column:QueryColumn):boolean {
    return !!_.find(
      this.available,
      (candidate) => candidate.column.$href === column.$href
    );
  }

  public addSortCriteria(column:QueryColumn, criteria:string) {
    let available = this.findAvailableDirection(column, criteria);

    if (available) {
      this.add(available);
    }
  }

  public setAsSingleSortCriteria(column:QueryColumn, criteria:string) {
    let available:QuerySortByResource = this.findAvailableDirection(column, criteria)!;

    if (available) {
      this.update([available]);
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
    let newValue = _
      .uniqBy([sortBy, ...this.current], sortBy => sortBy.column.$href)
      .slice(0, 3);

    this.update(newValue);
  }

  public get isManualSortingMode():boolean {
    let current = this.current;

    if (current && current.length > 0) {
      return current[0].column.href!.endsWith('/manualSorting');
    }

    return false;
  }

  public switchToManualSorting() {
    let manualSortObject =  this.manualSortObject;
    if (manualSortObject && !this.isManualSortingMode) {
      this.update([manualSortObject]);
    }
  }

  public get current():QuerySortByResource[] {
    return this.lastUpdatedState.getValueOr([]);
  }

  private get availableState() {
    return this.states.queries.sortBy;
  }

  public get available():QuerySortByResource[] {
    return this.availableState.getValueOr([]);
  }

  private get manualSortObject() {
    return _.find(this.available, sort => {
      return sort.column.$href!.endsWith('/manualSorting');
    });
  }
}
