//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++

import { isEqual } from 'lodash-es';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { States } from 'core-app/core/states/states.service';
import { Injectable, inject } from '@angular/core';
import { QueryColumn } from 'core-app/features/work-packages/components/wp-query/query-column';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { QueryGroupByResource } from 'core-app/features/hal/resources/query-group-by-resource';
import { WorkPackageQueryStateService } from './wp-view-base.service';

@Injectable()
export class WorkPackageViewGroupByService extends WorkPackageQueryStateService<QueryGroupByResource|null> {
  readonly states = inject(States);

  valueFromQuery(query:QueryResource) {
    return query.groupBy || null;
  }

  public hasChanged(query:QueryResource) {
    const comparer = (groupBy:QueryColumn|HalResource|null|undefined) => (groupBy ? groupBy.href : null);

    return !isEqual(
      comparer(query.groupBy),
      comparer(this.current),
    );
  }

  public applyToQuery(query:QueryResource) {
    const { current } = this;
    query.groupBy = current === null ? undefined : current;
    return true;
  }

  public isGroupable(column:QueryColumn):boolean {
    return this.available.some((candidate) => candidate.id === column.id);
  }

  public disable() {
    this.update(null);
  }

  public setBy(column:QueryColumn) {
    const groupBy = this.available.find((candidate) => candidate.id === column.id);

    if (groupBy) {
      this.update(groupBy);
    }
  }

  public get current():QueryGroupByResource|null {
    return this.lastUpdatedState.getValueOr(null);
  }

  protected get availableState() {
    return this.querySpace.available.groupBy;
  }

  public get isEnabled():boolean {
    return !!this.current;
  }

  public get available():QueryGroupByResource[] {
    return this.availableState.getValueOr([]);
  }

  public isCurrentlyGroupedBy(column:QueryColumn):boolean {
    const cur = this.current;
    return cur?.id === column.id;
  }
}
