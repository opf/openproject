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

import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {Injectable} from '@angular/core';
import {WorkPackageQueryStateService} from './wp-table-base.service';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {States} from "core-components/states.service";
import {QuerySchemaResource} from "core-app/modules/hal/resources/query-schema-resource";
import {WorkPackageCollectionResource} from "core-app/modules/hal/resources/wp-collection-resource";

@Injectable()
export class WorkPackageTableOrderService extends WorkPackageQueryStateService<string[]> {

  constructor(protected readonly querySpace:IsolatedQuerySpace,
              protected readonly states:States,
              protected readonly pathHelper:PathHelperService) {
    super(querySpace);
  }

  public initialize(query:QueryResource, results:WorkPackageCollectionResource, schema?:QuerySchemaResource) {
    if (query.persisted || !this.current) {
      this.update(this.valueFromQuery(query));
    }

    // Ensure orderedWorkPackages is always written to the query
    this.applyToQuery(query);
  }

  public valueFromQuery(query:QueryResource) {
    return query.results.elements.map(el => el.id!);
  }

  /**
   * Return ordered work packages
   */
  orderedWorkPackages():WorkPackageResource[] {
    const current:string[] = this.lastUpdatedState.getValueOr([]);
    return current.map((id:string) => this.states.workPackages.get(id).value!);
  }

  applyToQuery(query:QueryResource):boolean {
    const current = this.current;

    if (current) {
      query.orderedWorkPackages = current.map(id =>
        this.pathHelper.api.v3.work_packages.id(id).toString()
      );
    }

    return false;
  }

  hasChanged(query:QueryResource):boolean {
    return false;
  }

  setNewOrder(query:QueryResource, order:string[]) {
    this.update(order);
    this.applyToQuery(query);
    this.querySpace.query.putValue(query);
  }
}
