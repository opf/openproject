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

import {WorkPackageQueryStateService, WorkPackageTableBaseService} from './wp-table-base.service';
import {Injectable} from '@angular/core';
import {opServicesModule} from 'core-app/angular-modules';
import {downgradeInjectable} from '@angular/upgrade/static';
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {QuerySchemaResource} from 'core-app/modules/hal/resources/query-schema-resource';
import {QueryFilterInstanceResource} from 'core-app/modules/hal/resources/query-filter-instance-resource';
import {CollectionResource} from 'core-app/modules/hal/resources/collection-resource';
import {WorkPackageTableFilters} from '../wp-table-filters';
import {TableState} from 'core-components/wp-table/table-state/table-state';
import {InputState} from 'reactivestates';

@Injectable()
export class WorkPackageTableFiltersService extends WorkPackageTableBaseService<WorkPackageTableFilters> implements WorkPackageQueryStateService {

  constructor(readonly tableState:TableState) {
    super(tableState);
  }

  public get state():InputState<WorkPackageTableFilters> {
    return this.tableState.filters;
  }

  public valueFromQuery(query:QueryResource):WorkPackageTableFilters|undefined {
    return undefined;
  }

  public initializeFilters(query:QueryResource, schema:QuerySchemaResource) {
    let filters = _.map(query.filters, filter => filter.$copy<QueryFilterInstanceResource>());

    this.loadCurrentFiltersSchemas(filters).then(() => {
      let newState = new WorkPackageTableFilters(filters, schema);

      this.state.putValue(newState);
    });
  }

  public hasChanged(query:QueryResource) {
    const comparer = (filter:QueryFilterInstanceResource[]) => filter.map(el => el.$plain());

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

  private async loadCurrentFiltersSchemas(filters:QueryFilterInstanceResource[]):Promise<{}> {
    return Promise.all(_.map(filters,
                       async (filter:QueryFilterInstanceResource) => this.loadFilterSchema(filter)));
  }

  private async loadFilterSchema(filter:QueryFilterInstanceResource):Promise<{}> {
    return new Promise((resolve, reject) => {
      filter.schema.$load()
        .catch(reject)
        .then(() => {
        if (_.has(filter, ['values.length', 'currentSchema.values.allowedValues.$load'])) {
          (filter.currentSchema!.values!.allowedValues as CollectionResource).$load()
            .then((options:CollectionResource) => {
              this.setLoadedValues(filter, options);

              resolve();
            });
        } else {
          resolve();
        }
      });
    });
  }

  private setLoadedValues(filter:QueryFilterInstanceResource, options:CollectionResource) {
    _.each(filter.values, (value:any, index:any) => {
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

opServicesModule.service('wpTableFilters', downgradeInjectable(WorkPackageTableFiltersService));
