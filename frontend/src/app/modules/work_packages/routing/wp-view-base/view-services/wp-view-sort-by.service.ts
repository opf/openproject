//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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

import { States } from 'core-components/states.service';
import { combine } from 'reactivestates';
import { mapTo } from 'rxjs/operators';
import { QueryResource } from 'core-app/modules/hal/resources/query-resource';
import { IsolatedQuerySpace } from "core-app/modules/work_packages/query-space/isolated-query-space";
import { Injectable } from '@angular/core';
import { WorkPackageQueryStateService } from './wp-view-base.service';
import { Observable } from 'rxjs';
import { QuerySortByResource } from 'core-app/modules/hal/resources/query-sort-by-resource';
import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";
import { QueryColumn } from "core-components/wp-query/query-column";

@Injectable()
export class WorkPackageViewSortByService extends WorkPackageQueryStateService<QuerySortByResource[]> {

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
    const wasManuallySorted = this.isManuallySorted(query.sortBy);

    query.sortBy = [...this.current];

    // Reload every time unless we stayed in manual sort mode
    return !(wasManuallySorted && this.isManualSortingMode);
  }

  public isSortable(column:QueryColumn):boolean {
    return !!_.find(
      this.available,
      (candidate) => candidate.column.$href === column.$href
    );
  }

  public addSortCriteria(column:QueryColumn, criteria:string) {
    const available = this.findAvailableDirection(column, criteria);

    if (available) {
      this.add(available);
    }
  }

  public setAsSingleSortCriteria(column:QueryColumn, criteria:string) {
    const available:QuerySortByResource = this.findAvailableDirection(column, criteria)!;

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
    const newValue = _
      .uniqBy([sortBy, ...this.current], sortBy => sortBy.column.$href)
      .slice(0, 3);

    this.update(newValue);
  }

  public get isManualSortingMode():boolean {
    return this.isManuallySorted(this.current);
  }

  public switchToManualSorting(query:QueryResource):boolean {
    const manualSortObject =  this.manualSortObject;
    if (manualSortObject && !this.isManualSortingMode) {

      if (query && query.persisted) {
        // Save the query if it is persisted
        query.sortBy = [manualSortObject];
        return true;
      } else {
        // Query cannot be saved, just update the props for now
        this.update([manualSortObject]);
      }
    }

    return false;
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

  private isManuallySorted(sortBy:QuerySortByResource[]):boolean {
    if (sortBy && sortBy.length > 0) {
      return sortBy[0].column.href!.endsWith('/manualSorting');
    }

    return false;
  }

  private get manualSortObject() {
    return _.find(this.available, sort => {
      return sort.column.$href!.endsWith('/manualSorting');
    });
  }
}
