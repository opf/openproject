//-- copyright
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
//++

import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {ViewChild} from "@angular/core";
import {WorkPackageEmbeddedTableComponent} from "core-components/wp-table/embedded/wp-embedded-table.component";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {UrlParamsHelperService} from "core-components/wp-query/url-params-helper";

export abstract class WorkPackageRelationQueryBase {
  public workPackage:WorkPackageResource;

  /** Input is either a query resource, or directly query props */
  public query:Object;

  /** Query props are derived from the query resource, if any */
  public queryProps:Object;

  /** Reference to the embedded table instance */
  @ViewChild('embeddedTable') protected embeddedTable:WorkPackageEmbeddedTableComponent;

  constructor(protected queryUrlParamsHelper:UrlParamsHelperService) {
  }

  /**
   * Request to refresh the results of the embedded table
   */
  public refreshTable() {
    this.embeddedTable.isInitialized && this.embeddedTable.refresh();
  }

  /**
   * Create a contextualized copy of the query where all
   * references to the templated value are replaced with the actual work package ID.
   */
  protected contextualizedQuery(query:QueryResource) {
    let duppedQuery = _.cloneDeep(query);

    _.each(duppedQuery.filters, (filter) => {
      if (filter._links.values[0] && filter._links.values[0].templated) {
        filter._links.values[0].href = filter._links.values[0].href.replace('{id}', this.workPackage.id);
      }
    });

    return duppedQuery;
  }

  /**
   * Set up the query props from input
   */
  protected buildQueryProps() {
    if (this.query && (this.query as any)._type === 'Query') {
      let query = this.contextualizedQuery(this.query as QueryResource);
      this.queryProps = this.queryUrlParamsHelper.buildV3GetQueryFromQueryResource(query, {});
    } else {
      this.queryProps = this.query;
    }
  }
}
