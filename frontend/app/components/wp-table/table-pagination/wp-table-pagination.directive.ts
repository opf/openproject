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

import {TablePaginationController} from '../../table-pagination/table-pagination.controller';
import {ConfigurationResource} from '../../api/api-v3/hal-resources/configuration-resource.service';
import {ConfigurationDmService} from '../../api/api-v3/hal-resource-dms/configuration-dm.service';
import {WorkPackageTablePaginationService} from '../../wp-fast-table/state/wp-table-pagination.service';
import {WorkPackageTablePagination} from '../../wp-fast-table/wp-table-pagination';
import {wpDirectivesModule} from '../../../angular-modules';

wpDirectivesModule
  .directive('wpTablePagination', wpTablePagination);

export class WorkPackageTablePaginationController extends TablePaginationController {
  constructor(protected $scope:ng.IScope,
              protected PaginationService:any,
              protected I18n:op.I18n,
              protected wpTablePagination:WorkPackageTablePaginationService) {

    super($scope, PaginationService, I18n);

    this.wpTablePagination.observeOnScope($scope).subscribe((wpPagination:WorkPackageTablePagination) => {
      this.$scope.totalEntries = wpPagination.total;

      this.PaginationService.setPerPage(wpPagination.current.perPage);
      this.PaginationService.setPage(wpPagination.current.page);

      this.updateCurrentRangeLabel();
      this.updatePageNumbers();
    });
  }
}

function wpTablePagination(wpTablePagination:WorkPackageTablePaginationService) {
  return {
    restrict: 'EA',
    templateUrl: '/components/table-pagination/table-pagination.directive.html',

    scope: {},

    controller: WorkPackageTablePaginationController,

    link: function(scope:any) {

      scope.selectPerPage = function(perPage:number){
        wpTablePagination.updateFromObject({page: 1, perPage: perPage});
     };

      scope.showPage = function(pageNumber:number){
        wpTablePagination.updateFromObject({page: pageNumber});
      };
    }
  };
}
