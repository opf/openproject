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

import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';
import { Directive, ViewChild } from "@angular/core";
import { WorkPackageEmbeddedTableComponent } from "core-components/wp-table/embedded/wp-embedded-table.component";
import { QueryResource } from "core-app/modules/hal/resources/query-resource";
import { UrlParamsHelperService } from "core-components/wp-query/url-params-helper";
import { UntilDestroyedMixin } from "core-app/helpers/angular/until-destroyed.mixin";

@Directive()
export abstract class WorkPackageRelationQueryBase extends UntilDestroyedMixin {
  public workPackage:WorkPackageResource;

  /** Input is either a query resource, or directly query props */
  public query:QueryResource|Object;

  /** Query props are derived from the query resource, if any */
  public queryProps:Object;

  /** Whether this section should be hidden completely (due to missing permissions e.g.) */
  public hidden = false;

  /** Reference to the embedded table instance */
  @ViewChild('embeddedTable') protected embeddedTable:WorkPackageEmbeddedTableComponent;

  constructor(protected queryUrlParamsHelper:UrlParamsHelperService) {
    super();
  }

  /**
   * Request to refresh the results of the embedded table
   */
  public refreshTable() {
    this.embeddedTable.isInitialized && this.embeddedTable.loadQuery(true, false);
  }

  /**
   * Special handling for query loading when a project filter is involved.
   *
   * Ensure that at least one project was visible to the user or otherwise,
   * hide the creation from them.
   * cf. OP#30106
   * @param query
   */
  public handleQueryLoaded(loaded:QueryResource) {
    // We only handle loaded queries
    if (!(this.query instanceof QueryResource)) {
      return;
    }

    const filtersLength = this.projectValuesCount(this.query);
    const loadedFiltersLength = this.projectValuesCount(loaded);

    // Does the default have a project filter, but the other does not?
    if (filtersLength !== null && loadedFiltersLength === null) {
      this.hidden = true;
    }

    // Has a project filter been reduced to zero elements?
    if (filtersLength && loadedFiltersLength && filtersLength > 0 && loadedFiltersLength === 0) {
      this.hidden = true;
    }
  }

  /**
   * Get the filters of the query props
   */
  protected projectValuesCount(query:QueryResource):number|null {
    const project = query.filters.find(f => f.id === 'project');
    return project ? project.values.length : null;
  }

  /**
   * Set up the query props from input
   */
  protected buildQueryProps() {
    if (this.query instanceof QueryResource) {
      return this.queryUrlParamsHelper.buildV3GetQueryFromQueryResource(
        this.query,
        { valid_subset: true },
        { id: this.workPackage.id! }
      );
    } else {
      return this.query;
    }
  }
}
