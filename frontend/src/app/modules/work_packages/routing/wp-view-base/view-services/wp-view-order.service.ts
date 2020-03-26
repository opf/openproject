// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// ++

import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {Injectable} from '@angular/core';
import {WorkPackageQueryStateService} from './wp-view-base.service';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {States} from "core-components/states.service";
import {QuerySchemaResource} from "core-app/modules/hal/resources/query-schema-resource";
import {WorkPackageCollectionResource} from "core-app/modules/hal/resources/wp-collection-resource";
import {MAX_ORDER, ReorderDeltaBuilder} from "core-app/modules/common/drag-and-drop/reorder-delta-builder";
import {QueryOrder, QueryOrderDmService} from "core-app/modules/hal/dm-services/query-order-dm.service";
import {take} from "rxjs/operators";
import {InputState} from "reactivestates";
import {WorkPackageViewSortByService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-sort-by.service";
import {CausedUpdatesService} from "core-app/modules/boards/board/caused-updates/caused-updates.service";


@Injectable()
export class WorkPackageViewOrderService extends WorkPackageQueryStateService<QueryOrder> {

  constructor(protected readonly querySpace:IsolatedQuerySpace,
              protected readonly queryOrderDm:QueryOrderDmService,
              protected readonly states:States,
              protected readonly causedUpdates:CausedUpdatesService,
              protected readonly wpTableSortBy:WorkPackageViewSortByService,
              protected readonly pathHelper:PathHelperService) {
    super(querySpace);
  }

  public initialize(query:QueryResource, results:WorkPackageCollectionResource, schema?:QuerySchemaResource):Promise<unknown> {
    // Take over our current value if the query is not saved
    if (!query.persisted && this.positions.hasValue()) {
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
    let fromIndex:number = order.findIndex((id) => id === wpId);

    order.splice(fromIndex, 1);
    order.splice(toIndex, 0, wpId);

    await this.assignPosition(order, wpId, toIndex, fromIndex);

    return order;
  }

  /**
   * Pull an item from the rendered list
   */
  public remove(order:string[], wpId:string):string[] {
    _.remove(order, id => id === wpId);
    this.update({ [wpId]: -1 });
    return order;
  }

  /**
   * Add an item to the list
   */
  public async add(order:string[], wpId:string, toIndex:number = -1):Promise<string[]> {
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
    return this.currentQuery.persisted;
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
    const delta = new ReorderDeltaBuilder(order, positions, wpId, toIndex, fromIndex).buildDelta();

    await this.update(delta);
  }

  protected get positions():InputState<QueryOrder> {
    return this.updatesState;
  }

  /**
   * Update the order state
   */
  public async update(delta:QueryOrder) {
    let current = this.positions.getValueOr({});
    this.positions.putValue({ ...current, ...delta });

    // Push the update if the query is saved
    if (this.currentQuery.persisted) {
      const updatedAt = await this.queryOrderDm.update(this.currentQuery.id!, delta);
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
    if (this.currentQuery.persisted) {
      const value = this.positions.value;

      // Remove empty or stale values given we can reload them
      if ((value === {} || this.positions.isValueOlderThan(60000))) {
        this.positions.clear("Clearing old positions value");
      }

      // Load the current order from backend
      this.positions.putFromPromiseIfPristine(
        () => this.queryOrderDm.get(this.currentQuery.id!)
      );
    } else if (this.positions.isPristine()) {
      // Insert an empty fallback in case we have no data yet
      this.positions.putValue({});
    }

    return this.positions
      .values$()
      .pipe(take(1))
      .toPromise();
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
      .map(wp => this.states.workPackages.get(wp.id!).getValueOr(wp));

    if (this.currentQuery.persisted || this.positions.isPristine()) {
      return upstreamOrder;
    } else {
      const positions = this.positions.value!;
      return _.sortBy(upstreamOrder, (wp) => {
        const pos = positions[wp.id!];
        return pos !== undefined ? pos : MAX_ORDER;
      });
    }
  }

  applyToQuery(query:QueryResource):boolean {
    query.orderedWorkPackages = this.positions.getValueOr({});
    return false;
  }

  hasChanged(query:QueryResource):boolean {
    return false;
  }
}
