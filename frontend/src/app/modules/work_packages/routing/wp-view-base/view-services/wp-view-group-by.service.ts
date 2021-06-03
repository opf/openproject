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

import { QueryResource } from 'core-app/modules/hal/resources/query-resource';
import { QueryGroupByResource } from 'core-app/modules/hal/resources/query-group-by-resource';
import { WorkPackageQueryStateService } from './wp-view-base.service';
import { States } from 'core-components/states.service';
import { IsolatedQuerySpace } from "core-app/modules/work_packages/query-space/isolated-query-space";
import { Injectable } from '@angular/core';
import { QueryColumn } from "core-components/wp-query/query-column";
import { HalResource } from "core-app/modules/hal/resources/hal-resource";

@Injectable()
export class WorkPackageViewGroupByService extends WorkPackageQueryStateService<QueryGroupByResource|null> {
  public constructor(readonly states:States,
                     readonly querySpace:IsolatedQuerySpace) {
    super(querySpace);
  }

  valueFromQuery(query:QueryResource) {
    return query.groupBy || null;
  }

  public hasChanged(query:QueryResource) {
    const comparer = (groupBy:QueryColumn|HalResource|null|undefined) => groupBy ? groupBy.href : null;

    return !_.isEqual(
      comparer(query.groupBy),
      comparer(this.current)
    );
  }

  public applyToQuery(query:QueryResource) {
    const current = this.current;
    query.groupBy = current === null ? undefined : current;
    return true;
  }

  public isGroupable(column:QueryColumn):boolean {
    return !!_.find(this.available, candidate => candidate.id === column.id);
  }

  public disable() {
    this.update(null);
  }

  public setBy(column:QueryColumn) {
    const groupBy = _.find(this.available, candidate => candidate.id === column.id);

    if (groupBy) {
      this.update(groupBy);
    }
  }

  public get current():QueryGroupByResource|null {
    return this.lastUpdatedState.getValueOr(null);
  }

  protected get availableState() {
    return this.states.queries.groupBy;
  }

  public get isEnabled():boolean {
    return !!this.current;
  }

  public get available():QueryGroupByResource[] {
    return this.availableState.getValueOr([]);
  }

  public isCurrentlyGroupedBy(column:QueryColumn):boolean {
    const cur = this.current;
    return !!(cur && cur.id === column.id);
  }
}
