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

import { Injectable } from '@angular/core';
import { take } from 'rxjs/operators';
import { InputState } from '@openproject/reactivestates';
import { States } from 'core-app/core/states/states.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { QuerySchemaResource } from 'core-app/features/hal/resources/query-schema-resource';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import isPersistedResource from 'core-app/features/hal/helpers/is-persisted-resource';
import { MAX_ORDER, buildDelta } from 'core-app/shared/helpers/drag-and-drop/reorder-delta-builder';
import { WorkPackageViewSortByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sort-by.service';
import { CausedUpdatesService } from 'core-app/features/boards/board/caused-updates/caused-updates.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { QueryOrder } from 'core-app/core/apiv3/endpoints/queries/apiv3-query-order';
import { WorkPackageQueryStateService } from './wp-view-base.service';
import { firstValueFrom } from 'rxjs';

@Injectable()
export class WorkPackageViewOrderService extends WorkPackageQueryStateService<QueryOrder> {
  constructor(protected readonly querySpace:IsolatedQuerySpace,
    protected readonly apiV3Service:ApiV3Service,
    protected readonly states:States,
    protected readonly causedUpdates:CausedUpdatesService,
    protected readonly wpTableSortBy:WorkPackageViewSortByService,
    protected readonly pathHelper:PathHelperService) {
    super(querySpace);
  }

  public initialize(query:QueryResource, results:WorkPackageCollectionResource, schema?:QuerySchemaResource):Promise<unknown> {
    // Take over our current value if the query is not saved
    if (!isPersistedResource(query) && this.positions.hasValue()) {
      this.applyToQuery(query);
    }

    if (this.wpTableSortBy.isManualSortingMode) {
      return this.withLoadedPositions();
    }

    return Promise.resolve();
  }

  /**
   * Move an item in the list
   */
  public async move(order:string[], wpId:string, toIndex:number):Promise<string[]> {
    // Find index of the work package
    const fromIndex:number = order.findIndex((id) => id === wpId);

    order.splice(fromIndex, 1);
    order.splice(toIndex, 0, wpId);

    await this.assignPosition(order, wpId, toIndex, fromIndex);

    return order;
  }

  /**
   * Pull an item from the rendered list
   */
  public remove(order:string[], wpId:string):string[] {
    _.remove(order, (id) => id === wpId);
    this.update({ [wpId]: -1 });
    return order;
  }

  /**
   * Add an item to the list
   */
  public async add(order:string[], wpId:string, toIndex = -1):Promise<string[]> {
    if (toIndex === -1) {
      order.push(wpId);
      toIndex = order.length - 1;
    } else {
      order.splice(toIndex, 0, wpId);
    }

    await this.assignPosition(order, wpId, toIndex);

    return order;
  }

  public get applicable() {
    return isPersistedResource(this.currentQuery);
  }

  protected get currentQuery():QueryResource {
    return this.querySpace.query.value!;
  }

  /**
   * Assign a position for the given work package and its index given the current order
   * @param order Current order the work package was inserted to
   * @param wpId The work package ID that was moved
   * @param toIndex The id of the work package in order
   */
  protected async assignPosition(order:string[], wpId:string, toIndex:number, fromIndex:number|null = null) {
    const positions = await this.withLoadedPositions();
    const delta = buildDelta(order, positions, wpId, toIndex, fromIndex);

    await this.update(delta);
  }

  protected get positions():InputState<QueryOrder> {
    return this.updatesState;
  }

  /**
   * Update the order state
   */
  public async update(delta:QueryOrder) {
    const current = this.positions.getValueOr({});
    this.positions.putValue({ ...current, ...delta });

    // Push the update if the query is saved
    if (isPersistedResource(this.currentQuery)) {
      const updatedAt = await this
        .apiV3Service
        .queries.id(this.currentQuery)
        .order
        .update(delta);

      this.currentQuery.updatedAt = updatedAt;

      // Remember that we caused this update
      this.causedUpdates.add(this.currentQuery);
    }

    // Push into the query object
    this.applyToQuery(this.currentQuery);

    // Update the query
    this.querySpace.query.putValue(this.currentQuery);
  }

  /**
   * Initialize (or load if persisted) the order for the query space
   */
  public withLoadedPositions():Promise<QueryOrder> {
    if (isPersistedResource(this.currentQuery)) {
      const { value } = this.positions;

      // Remove empty or stale values given we can reload them
      if ((_.isEmpty(value) || this.positions.isValueOlderThan(60000))) {
        this.positions.clear('Clearing old positions value');
      }

      // Load the current order from backend
      this.positions.putFromPromiseIfPristine(
        () => this
          .apiV3Service
          .queries.id(this.currentQuery)
          .order
          .get(),
      );
    } else if (this.positions.isPristine()) {
      // Insert an empty fallback in case we have no data yet
      this.positions.putValue({});
    }

    return firstValueFrom(this.positions.values$());
  }

  public valueFromQuery(query:QueryResource) {
    return undefined;
  }

  /**
   * Return ordered work packages
   */
  orderedWorkPackages():WorkPackageResource[] {
    const upstreamOrder = this.querySpace
      .results
      .value!
      .elements
      .map((wp) => this.states.workPackages.get(wp.id!).getValueOr(wp));

    if (isPersistedResource(this.currentQuery) || this.positions.isPristine()) {
      return upstreamOrder;
    }
    const positions = this.positions.value!;
    return _.sortBy(upstreamOrder, (wp) => {
      const pos = positions[wp.id!];
      return pos !== undefined ? pos : MAX_ORDER;
    });
  }

  applyToQuery(query:QueryResource):boolean {
    query.orderedWorkPackages = this.positions.getValueOr({});
    return false;
  }

  hasChanged(query:QueryResource):boolean {
    return false;
  }
}
