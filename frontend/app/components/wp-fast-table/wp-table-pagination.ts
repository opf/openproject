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

import {WorkPackageCollectionResource} from '../api/api-v3/hal-resources/wp-collection-resource.service'
import {WorkPackageTableBaseState} from "./wp-table-base";
import {QueryResource} from "../api/api-v3/hal-resources/query-resource.service";

export class WorkPackageTablePaginationObject extends WorkPackageTableBaseState<WorkPackageTablePagination> {
  constructor(public page:number,
              public perPage:number,
              public total:number,
              public count:number) {
    super();
  }
}

export class WorkPackageTablePagination {
  public current:WorkPackageTablePaginationObject;

  constructor(results:WorkPackageCollectionResource) {
    this.current = new WorkPackageTablePaginationObject(results.offset,
                                                        results.pageSize,
                                                        results.total,
                                                        results.count)
  }

  public get page() {
    return this.current.page;
  }

  public set page(val) {
    this.current.page = val;
  }

  public get perPage() {
    return this.current.perPage;
  }

  public set perPage(val) {
    this.current.perPage = val;
  }

  public get total() {
    return this.current.total;
  }

  public set total(val) {
    this.current.total = val;
  }

  public get count() {
    return this.current.count;
  }

  public set count(val) {
    this.current.count = val;
  }
}
