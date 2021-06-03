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

import { WorkPackageQueryStateService } from './wp-view-base.service';
import { Injectable } from '@angular/core';
import { QueryResource } from 'core-app/modules/hal/resources/query-resource';
import { QuerySchemaResource } from 'core-app/modules/hal/resources/query-schema-resource';
import { QueryFilterInstanceResource } from 'core-app/modules/hal/resources/query-filter-instance-resource';
import { IsolatedQuerySpace } from "core-app/modules/work_packages/query-space/isolated-query-space";
import { combine, input, InputState } from 'reactivestates';
import { cloneHalResourceCollection } from 'core-app/modules/hal/helpers/hal-resource-builder';
import { QueryFilterResource } from "core-app/modules/hal/resources/query-filter-resource";
import { QueryFilterInstanceSchemaResource } from "core-app/modules/hal/resources/query-filter-instance-schema-resource";
import { States } from "core-components/states.service";
import { HalResource } from 'core-app/modules/hal/resources/hal-resource';
import { mapTo, take } from "rxjs/operators";

@Injectable()
export class WorkPackageViewFiltersService extends WorkPackageQueryStateService<QueryFilterInstanceResource[]> {
  public hidden:string[] = [
    'datesInterval',
    'precedes',
    'follows',
    'relates',
    'duplicates',
    'duplicated',
    'blocks',
    'blocked',
    'partof',
    'includes',
    'requires',
    'required',
    'search',
    // The filter should be named subjectOrId but for some reason
    // it is only named subjectOr
    'subjectOrId',
    'subjectOr',
    'manualSort'
  ];

  /** Flag state to determine whether the filters are incomplete */
  private incomplete = input<boolean>(false);

  constructor(protected readonly states:States,
              readonly querySpace:IsolatedQuerySpace) {
    super(querySpace);
  }

  /**
   * Load all schemas for the current filters and fill respective states
   * @param query
   * @param schema
   */
  public initializeFilters(query:QueryResource, schema:QuerySchemaResource) {
    const filters = cloneHalResourceCollection<QueryFilterInstanceResource>(query.filters);

    this.availableState.putValue(schema.filtersSchemas.elements);
    this.pristineState.putValue(filters);
  }

  /**
   * Return whether the filters are empty
   */
  public get isEmpty() {
    const value = this.lastUpdatedState.value;
    return !value || value.length === 0;
  }

  public get availableState():InputState<QueryFilterInstanceSchemaResource[]> {
    return this.states.queries.filters;
  }

  /** Return whether the filters the user is working on are incomplete */
  public get incomplete$() {
    return this.incomplete.values$();
  }


  /**
   * Add a filter instantiation from the set of available filter schemas
   *
   * @param filter
   */
  public add(filter:QueryFilterInstanceResource) {
    this.updatesState.putValue([...this.rawFilters, filter]);
  }

  /**
   * Replace a filter, or add a new one
   */
  public replace(id:string, modifier:(filter:QueryFilterInstanceResource) => void):void {
    const filter:QueryFilterInstanceResource = this.instantiate(id);

    const newFilters = [...this.rawFilters];
    modifier(filter);

    const index = this.findIndex(id);
    if (index === -1) {
      newFilters.push(filter);
    } else {
      newFilters.splice(index, 1, filter);
    }

    this.update(newFilters);
  }

  /**
   * Modify a live filter and push it to the state.
   * Avoids copying the resource.
   *
   * Returns whether the filter was found and modified
   */
  public modify(id:string, modifier:(filter:QueryFilterInstanceResource) => void):boolean {
    const index = this.findIndex(id);

    if (index === -1) {
      return false;
    }

    const filters = [...this.rawFilters];
    modifier(filters[index]!);
    this.update(filters);

    return true;
  }

  /**
   * Get an instantiated filter without adding it to the current state
   * @param filterOrId The query filter or id to instantiate
   */
  public instantiate(filterOrId:QueryFilterResource|string):QueryFilterInstanceResource {
    const id = (filterOrId instanceof QueryFilterResource) ? filterOrId.id : filterOrId;

    const schema = _.find(
      this.availableSchemas,
      schema => (schema.filter.allowedValues as HalResource)[0].id === id
    )!;

    return schema.getFilter();
  }

  /**
   * Remove one or more filters from the live state of filters.
   * @param filters Filters to be removed
   */
  public remove(...filters:(QueryFilterInstanceResource|string)[]) {
    const mapper = (f:QueryFilterInstanceResource|string) => (f instanceof QueryFilterInstanceResource) ? f.id : f;
    const set = new Set<string>(filters.map(mapper));

    this.update(
      this.rawFilters.filter(f => !set.has(mapper(f)))
    );
  }

  /**
   * Return the remaining visible filters from the given filters set.
   * @param filters Array of active filters, defaults to the current live state.
   */
  public remainingVisibleFilters(filters = this.current) {
    return this
      .remainingFilters(filters)
      .filter((filter) => this.hidden.indexOf(filter.id) === -1);
  }

  /**
   * Return all available filter resources.
   * They need to be instantiated before using them in this service.
   */
  public get availableFilters():QueryFilterResource[] {
    return this.availableSchemas.map(schema => schema.allowedFilterValue);
  }

  private get availableSchemas():QueryFilterInstanceSchemaResource[] {
    return this.availableState.getValueOr([]);
  }

  /**
   * Determine whether all given filters are completely defined.
   * @param filters
   */
  public isComplete(filters:QueryFilterInstanceResource[]):boolean {
    return _.every(filters, filter => filter.isCompletelyDefined());
  }

  /**
   * Compare the current set of filters to the given query.
   * @param query
   */
  public hasChanged(query:QueryResource) {
    const comparer = (filter:HalResource[]) => filter.map(el => el.$source);

    return !_.isEqual(
      comparer(query.filters),
      comparer(this.rawFilters)
    );
  }

  public valueFromQuery(query:QueryResource) {
    return undefined;
  }

  update(value:QueryFilterInstanceResource[]) {
    super.update(value);
    this.incomplete.putValue(false);
  }

  /**
   * Returns the live filter instance for the given ID, or undefined
   * if it does not exist.
   *
   * @param id Identifier of the filter
   */
  public find(id:string):QueryFilterInstanceResource|undefined {
    const index = this.findIndex(id);

    if (index === -1) {
      return;
    }

    return this.rawFilters[index];
  }

  /**
   * Returns the index of the filter, or -1 if it does not exist
   * @param id Identifier of the filter
   */
  public findIndex(id:string):number {
    return _.findIndex(this.current, f => f.id === id);
  }

  public applyToQuery(query:QueryResource) {
    query.filters = this.cloneFilters();
    return true;
  }

  /**
   * Returns a shallow copy of the current filters.
   * Modifications to filters themselves will still
   */
  public get current():QueryFilterInstanceResource[] {
    return [...this.rawFilters];
  }

  /**
   * Returns a deep clone of the current filters set, may be used
   * to modify the filters without altering this state.
   */
  public cloneFilters() {
    return cloneHalResourceCollection<QueryFilterInstanceResource>(this.rawFilters);
  }

  /**
   * Returns the live state array, used for inspection of the filters
   * without modification.
   */
  protected get rawFilters():QueryFilterInstanceResource[] {
    return this.lastUpdatedState.value || [];
  }

  public get currentlyVisibleFilters() {
    const invisibleFilters = new Set(this.hidden);
    invisibleFilters.delete('search');

    return _.reject(this.currentFilterResources, (filter) => invisibleFilters.has(filter.id));
  }

  /**
   * Replace this filter state, but only if the given filters are complete
   * @param newState
   */
  public replaceIfComplete(newState:QueryFilterInstanceResource[]) {
    if (this.isComplete(newState)) {
      this.update(newState);
    } else {
      this.incomplete.putValue(true);
    }
  }

  /**
   * Filters service depends on two states
   */
  public onReady() {
    return combine(this.pristineState, this.availableState)
      .values$()
      .pipe(
        take(1),
        mapTo(null)
      )
      .toPromise();
  }

  /**
   * Get all filters that are not in the current active set
   */
  private remainingFilters(filters = this.rawFilters) {
    return _.differenceBy(this.availableFilters, filters, filter => filter.id);
  }

  /**
   * Map current filter instances to their FilterResource
   */
  private get currentFilterResources():QueryFilterResource[] {
    return this.rawFilters.map((filter:QueryFilterInstanceResource) => filter.filter);
  }

  isAvailable(el:QueryFilterInstanceResource):boolean {
    return !!this.availableFilters.find(available => available.id === el.id);
  }
}
