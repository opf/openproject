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

import {QueryFilterResource} from '../api/api-v3/hal-resources/query-filter-resource.service';
import {QueryFilterInstanceResource} from '../api/api-v3/hal-resources/query-filter-instance-resource.service';
import {QuerySchemaResourceInterface} from '../api/api-v3/hal-resources/query-schema-resource.service';
import {QueryFilterInstanceSchemaResource} from '../api/api-v3/hal-resources/query-filter-instance-schema-resource.service';
import {WorkPackageTableBaseState} from './wp-table-base';

export class WorkPackageTableFilters extends WorkPackageTableBaseState<QueryFilterInstanceResource[]> {

  public availableSchemas:QueryFilterInstanceSchemaResource[] = [];
  public current:QueryFilterInstanceResource[] = [];

  constructor(filters:QueryFilterInstanceResource[], schema:QuerySchemaResourceInterface) {
    super();
    this.current = filters;
    this.availableSchemas = schema
                            .filtersSchemas
                            .elements as QueryFilterInstanceSchemaResource[];
  }

  public add(filter:QueryFilterResource) {
    let schema = _.find(this.availableSchemas,
                        schema => (schema.filter.allowedValues as QueryFilterResource[])[0].href === filter.href);

    let newFilter = QueryFilterInstanceResource.fromSchema(schema!);

    this.current.push(newFilter);

    return newFilter;
  }

  public remove(filter:QueryFilterInstanceResource) {
    let index = this.current.indexOf(filter);

    this.current.splice(index, 1);
  }

  public get remainingFilters() {
    var activeFilterHrefs = this.currentFilters.map(filter => filter.href);

    return _.remove(this.availableFilters, filter => activeFilterHrefs.indexOf(filter.href) === -1);
  }

  public isComplete():boolean {
    return _.every(this.current, filter => filter.isCompletelyDefined());
  }

  private get currentFilters() {
    return this.current.map((filter:QueryFilterInstanceResource) => filter.filter);
  }

  private get availableFilters() {
    let availableFilters = this.availableSchemas
                               .map(schema => (schema.filter.allowedValues as QueryFilterResource[])[0]);

    // We do not use the id filter as of now as we do not have adequate
    // means to select the values.
    return _.filter(availableFilters, filter => filter.id !== 'id');
  }
}
