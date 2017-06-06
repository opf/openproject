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
import {QueryFilterInstanceResource} from '../../api/api-v3/hal-resources/query-filter-instance-resource.service';
import {CollectionResource} from '../../api/api-v3/hal-resources/collection-resource.service';
import {opServicesModule} from '../../../angular-modules';
import {States} from '../../states.service';
import {WorkPackageTableFilters} from '../wp-table-filters';
import {HalResource} from '../../api/api-v3/hal-resources/hal-resource.service';

export class WorkPackageTableFiltersService extends WorkPackageTableBaseService implements WorkPackageQueryStateService {
  protected stateName = 'filters' as TableStateStates;

  constructor(public states: States,
              private $q: ng.IQService) {
    super(states);
  }

  public initialize(query:QueryResource, schema:QuerySchemaResourceInterface) {
    let filters = _.map(query.filters, filter => filter.$copy());

    this.loadCurrentFiltersSchemas(filters).then(() => {
      let newState = new WorkPackageTableFilters(filters, schema);

      this.state.putValue(newState);
    });
  }

  public hasChanged(query:QueryResource) {
    const comparer = (filter:HalResource[]) => filter.map(el => el.$plain());

    return !_.isEqual(
      comparer(query.filters),
      comparer(this.current)
    );
  }

  public applyToQuery(query:QueryResource) {
    query.filters = _.cloneDeep(this.current);
    return true;
  }

  public get currentState():WorkPackageTableFilters {
    return this.state.value as WorkPackageTableFilters;
  }

  public get current():QueryFilterInstanceResource[]{
    if (this.currentState) {
      return _.map(this.currentState.current, filter => filter.$copy());
    } else {
      return [];
    }
  }

  public replace(newState:WorkPackageTableFilters) {
    this.state.putValue(newState);
  }

  public replaceIfComplete(newState:WorkPackageTableFilters) {
    if (newState.isComplete()) {
      this.state.putValue(newState);
    }
  }

  public remove(removedFilter:QueryFilterInstanceResource) {
    this.currentState.remove(removedFilter);

    this.state.putValue(this.currentState);
  }

  private loadCurrentFiltersSchemas(filters:QueryFilterInstanceResource[]):ng.IPromise<{}> {
    return this.$q.all(_.map(filters,
                       (filter:QueryFilterInstanceResource) => this.loadFilterSchema(filter)));
  }

  private loadFilterSchema(filter:QueryFilterInstanceResource):ng.IPromise<{}> {
    let deferred = this.$q.defer();

    filter.schema.$load().then(() => {
      if (_.has(filter, ['values.length', 'currentSchema.values.allowedValues.$load'])) {
        (filter.currentSchema!.values!.allowedValues as CollectionResource).$load()
          .then((options:CollectionResource) => {
            this.setLoadedValues(filter, options);

            deferred.resolve();
          });
      } else {
        deferred.resolve();
      }
    });

    return deferred.promise;
  }

  private setLoadedValues(filter:QueryFilterInstanceResource, options:CollectionResource) {
    _.each(filter.values, (value:any, index:number) => {
      let loadedHalResource = _.find(options.elements,
                                     option => option.$href === value.$href);

      if (loadedHalResource) {
        filter.values[index] = loadedHalResource;
      } else {
        throw "HalResource not in list of allowed values.";
      }
    });
  }
}

opServicesModule.service('wpTableFilters', WorkPackageTableFiltersService);
