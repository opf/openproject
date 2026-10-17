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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { sortBy } from 'lodash-es';
import { Injectable, inject } from '@angular/core';
import { InputState } from '@openproject/reactivestates';
import { States } from 'core-app/core/states/states.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import isPersistedResource from 'core-app/features/hal/helpers/is-persisted-resource';
import { MAX_ORDER, buildDelta } from 'core-app/shared/helpers/drag-and-drop/reorder-delta-builder';
import { WorkPackageViewSortByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sort-by.service';
import { CausedUpdatesService } from 'core-app/features/boards/board/caused-updates/caused-updates.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { QueryOrder } from 'core-app/core/apiv3/endpoints/queries/apiv3-query-order';
import { WorkPackageQueryStateService } from './wp-view-base.service';
import { firstValueFrom } from 'rxjs';

export interface PreparedQueryOrder {
  readonly order:readonly string[];
  persist():Promise<void>;
}

@Injectable()
export class WorkPackageViewOrderService extends WorkPackageQueryStateService<QueryOrder> {
  protected readonly apiV3Service = inject(ApiV3Service);
  protected readonly states = inject(States);
  protected readonly causedUpdates = inject(CausedUpdatesService);
  protected readonly wpTableSortBy = inject(WorkPackageViewSortByService);
  protected readonly pathHelper = inject(PathHelperService);

  private readonly pendingPositions = new WeakMap<QueryResource, Promise<QueryOrder>>();

  public initialize(query:QueryResource):void {
    // Take over our current value if the query is not saved
    if (!isPersistedResource(query) && this.positions.hasValue()) {
      this.applyToQuery(query);
    }

    if (this.wpTableSortBy.isManualSortingMode) {
      void this.withLoadedPositions().catch((error:unknown) => console.error('Query order initialization failed', error));
    }
  }

  /**
   * Move an item in the list
   *
   * Rejects an index it cannot honour before touching `order`: a negative
   * `fromIndex` or `toIndex` would splice from the END of the list, silently
   * displacing an unrelated work package and persisting a position for it.
   */
  public async move(order:string[], wpId:string, toIndex:number):Promise<string[]> {
    const fromIndex = this.validateMove(order, wpId, toIndex);

    order.splice(fromIndex, 1);
    order.splice(toIndex, 0, wpId);

    await this.assignPosition(order, wpId, toIndex, fromIndex);

    return order;
  }

  /**
   * Pull an item from the rendered list
   */
  public remove(order:string[], wpId:string):string[] {
    const filteredOrder = this.filterOrder(order, wpId);
    void this.update({ [wpId]: -1 });
    return filteredOrder;
  }

  /**
   * Pull an item from the rendered list and await the update
   */
  public async removePersisted(order:string[], wpId:string):Promise<string[]> {
    const filteredOrder = this.filterOrder(order, wpId);
    await this.update({ [wpId]: -1 });
    return filteredOrder;
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
    const query = this.currentQuery;
    if (isPersistedResource(query)) return this.positionsFor(query);
    if (this.positions.isPristine()) this.positions.putValue({});
    return firstValueFrom(this.positions.values$());
  }

  public positionsFor(query:QueryResource):Promise<QueryOrder> {
    const positionsState = this.positions;
    const isCurrent = this.querySpace.query.value === query;
    if (!isPersistedResource(query)) {
      return Promise.resolve({
        ...query.orderedWorkPackages as QueryOrder,
        ...(isCurrent ? positionsState.getValueOr({}) : {}),
      });
    }

    const { value } = positionsState;
    if (isCurrent && value && Object.keys(value).length > 0 && !positionsState.isValueOlderThan(60000)) {
      return Promise.resolve({ ...value });
    }

    const existing = this.pendingPositions.get(query);
    if (existing) return existing.then((positions) => ({ ...positions }));
    const endpoint = this.apiV3Service.queries.id(query);
    if (isCurrent) positionsState.clear('Clearing old positions value');
    const beforeLoad = positionsState.value;
    const loading = endpoint.order.get().then((positions) => {
      if (this.querySpace.query.value === query && positionsState.value === beforeLoad) {
        positionsState.putValue({ ...positions });
      }
      return positions;
    }).finally(() => this.pendingPositions.delete(query));
    this.pendingPositions.set(query, loading);
    return loading.then((positions) => ({ ...positions }));
  }

  public async prepareMove(
    query:QueryResource,
    order:readonly string[],
    wpId:string,
    toIndex:number,
    isCurrent:() => boolean,
  ):Promise<PreparedQueryOrder> {
    const fromIndex = this.validateMove(order, wpId, toIndex);
    const reordered = [...order];
    reordered.splice(fromIndex, 1);
    reordered.splice(toIndex, 0, wpId);
    return this.preparePosition(query, reordered, wpId, toIndex, isCurrent, fromIndex);
  }

  private validateMove(order:readonly string[], wpId:string, toIndex:number):number {
    const fromIndex = order.findIndex((id) => id === wpId);
    if (fromIndex === -1) {
      throw new Error(`Cannot move work package ${wpId}: not in the current order.`);
    }
    if (!Number.isInteger(toIndex) || toIndex < 0 || toIndex >= order.length) {
      throw new Error(`Cannot move work package ${wpId} to index ${toIndex}: out of bounds.`);
    }
    return fromIndex;
  }

  public async prepareAdd(
    query:QueryResource,
    order:readonly string[],
    wpId:string,
    isCurrent:() => boolean,
    toIndex = -1,
  ):Promise<PreparedQueryOrder> {
    const index = toIndex === -1 ? order.length : toIndex;
    if (!Number.isInteger(index) || index < 0 || index > order.length) {
      throw new Error(`Cannot add work package ${wpId} to index ${index}: out of bounds.`);
    }
    const reordered = [...order];
    reordered.splice(index, 0, wpId);
    return this.preparePosition(query, reordered, wpId, index, isCurrent);
  }

  private async preparePosition(
    query:QueryResource,
    reordered:string[],
    wpId:string,
    toIndex:number,
    isCurrent:() => boolean,
    fromIndex:number|null = null,
  ):Promise<PreparedQueryOrder> {
    const savedEndpoint = isPersistedResource(query) ? this.apiV3Service.queries.id(query) : undefined;
    const causedUpdates = this.causedUpdates;
    const querySpace = this.querySpace;
    const positionsState = this.positions;
    const positions = await this.positionsFor(query);
    const delta = buildDelta(reordered, positions, wpId, toIndex, fromIndex);
    const updatedPositions = { ...positions, ...delta };
    return {
      order: reordered,
      persist: async () => {
        if (savedEndpoint) {
          query.updatedAt = await savedEndpoint.order.update(delta);
          causedUpdates.add(query);
        }
        query.orderedWorkPackages = updatedPositions;
        if (isCurrent() && querySpace.query.value === query) {
          positionsState.putValue(updatedPositions);
          querySpace.query.putValue(query);
        }
      },
    };
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
    return sortBy(upstreamOrder, (wp) => {
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

  /**
   * Filter a work package from the order array
   */
  private filterOrder(order:string[], wpId:string):string[] {
    return order.filter((id) => id !== wpId);
  }
}
