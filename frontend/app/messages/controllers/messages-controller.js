//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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

module.exports = function($scope, $http, PathHelper, SortService, PaginationService) {
  $scope.PathHelper = PathHelper;
  $scope.messages = gon.messages;
  $scope.totalMessageCount = gon.total_count;
  $scope.isLoading = false;
  $scope.projectId = gon.project_id;
  $scope.activityModuleEnabled = gon.activity_modul_enabled;

  PaginationService.setPerPageOptions(gon.settings.pagination.per_page_options);
  SortService.setColumn(gon.sort_column);
  SortService.setDirection(gon.sort_direction);

  $scope.loadMessages = function() {
    $scope.isLoading = true;

    $http.get(PathHelper.boardPath(gon.project_id, gon.board_id),
              {
                params: {
                          sort: SortService.getSortParam(),
                          page: PaginationService.getPage(),
                          per_page: PaginationService.getPerPage()
                        }
              })
         .success(function(data, status, headers, config) {
           $scope.messages = data.messages;
           $scope.isLoading = false;
         })
         .error(function(data, status, headers, config) {
           $scope.isLoading = false;
         });
  };
};
