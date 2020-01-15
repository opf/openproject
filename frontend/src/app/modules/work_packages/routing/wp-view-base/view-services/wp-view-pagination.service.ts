//-- copyright
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
//++

import {Injectable} from '@angular/core';
import {PaginationObject} from 'core-app/modules/hal/dm-services/query-dm.service';
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {WorkPackageCollectionResource} from 'core-app/modules/hal/resources/wp-collection-resource';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {PaginationService} from 'core-components/table-pagination/pagination-service';
import {WorkPackageViewPagination} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-table-pagination";
import {WorkPackageViewBaseService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-base.service";

export interface PaginationUpdateObject {
  page?:number;
  perPage?:number;
  total?:number;
  count?:number;
}

@Injectable()
export class WorkPackageViewPaginationService extends WorkPackageViewBaseService<WorkPackageViewPagination> {
  public constructor(querySpace:IsolatedQuerySpace,
                     readonly paginationService:PaginationService) {
    super(querySpace);
  }

  public get paginationObject():PaginationObject {
    if (this.current) {
      return {
        pageSize: this.current.perPage,
        offset: this.current.page
      };
    } else {
      return {
        pageSize: this.paginationService.getCachedPerPage([]),
        offset: 1
      };
    }

  }

  public valueFromQuery(query:QueryResource, results:WorkPackageCollectionResource) {
    return new WorkPackageViewPagination(results);
  }

  public updateFromObject(object:PaginationUpdateObject) {
    let currentState = this.current;

    if (object.page) {
      currentState.page = object.page;
    }
    if (object.perPage) {
      currentState.perPage = object.perPage;
    }
    if (object.total) {
      currentState.total = object.total;
    }

    this.updatesState.putValue(currentState);
  }

  public updateFromResults(results:WorkPackageCollectionResource) {
    let update = {
      page: results.offset,
      perPage: results.pageSize,
      total: results.total,
      count: results.count
    };

    this.updateFromObject(update);
  }

  public get current():WorkPackageViewPagination {
    return this.lastUpdatedState.value!;
  }
}
