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

module.exports = function($scope, $http, PathHelper, SortService, PaginationService) {
  $scope.PathHelper = PathHelper;
  $scope.timeEntries = gon.timeEntries;
  $scope.totalEntryCount = gon.total_count;
  $scope.isLoading = false;

  SortService.setColumn(gon.sort_column);
  SortService.setDirection(gon.sort_direction);

  $scope.loadTimeEntries = function() {
    $scope.isLoading = true;

    $http.get(PathHelper.timeEntriesPath(gon.project_id, gon.work_package_id),
              {
                params: {
                          sort: SortService.getSortParam(),
                          page: PaginationService.getPage()
                        }
              })
         .success(function(data, status, headers, config) {
           $scope.timeEntries = data.timeEntries;
           $scope.isLoading = false;
         })
         .error(function(data, status, headers, config) {
           $scope.isLoading = false;
         });
  };

  $scope.deleteTimeEntry = function(id) {
    if (window.confirm(I18n.t('js.text_are_you_sure'))) {
      $http['delete'](PathHelper.timeEntryPath(id))
           .success(function(data, status, headers, config) {
             var index = 0;

             for (var i = 0; i < $scope.timeEntries.length; i++) {
               if ($scope.timeEntries[i].id == id) {
                 index = i;
                 break;
               }
             }

             $scope.timeEntries.splice(index, 1);

             $scope.$emit('flashMessage', data);
           })
           .error(function(data, status, headers, config) {
             $scope.$emit('flashMessage', data);
           });
    }
  };
};
