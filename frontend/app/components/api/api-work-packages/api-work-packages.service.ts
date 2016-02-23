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

import {ApiMetaDataService} from "../api-meta-data/api-meta-data.service";

export class ApiWorkPackagesService {
  protected WorkPackages;

  //TODO: Add missing properties.
  protected propertyMap = {
    assigned_to: 'assignee',
    updated_at: 'updatedAt'
  };

  constructor (protected DEFAULT_PAGINATION_OPTIONS,
               protected $stateParams,
               protected $q:ng.IQService,
               protected apiV3:restangular.IService,
               protected apiMetaData:ApiMetaDataService) {

    this.WorkPackages = apiV3.service('work_packages');
  }

  public list(offset:number, pageSize:number, query:api.ex.Query, columns:api.ex.Column[]) {
    const columns = this.mapColumns(columns);
    const columnNames = columns.map(column => column.name);
    const params = {
      offset: offset,
      pageSize: pageSize,
      filters: [query.filters],
      groupBy: query.group_by,
      sortBy: query.sort_criteria,
      showSums: query.display_sums
    };

    return this.WorkPackages.getList(params).then(wpCollection => {
      wpCollection.forEach(workPackage => {
        workPackage.setProperties(columnNames);
      });

      return wpCollection;
    });
  }

  protected mapColumns(columns:api.ex.Column[] = []) {
    columns.forEach(column => column.name = this.propertyMap[column.name] || column.name);
    return columns;
  }
}


angular
  .module('openproject.api')
  .service('apiWorkPackages', ApiWorkPackagesService);
