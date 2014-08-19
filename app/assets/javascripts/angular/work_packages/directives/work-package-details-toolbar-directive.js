//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

angular.module('openproject.workPackages.directives')

.constant('PERMITTED_MORE_MENU_ACTIONS', ['log_time', 'duplicate', 'move', 'delete'])

.directive('workPackageDetailsToolbar', [
  'PERMITTED_MORE_MENU_ACTIONS',
  '$state',
  '$window',
  'I18n',
  'flags',
  'PathHelper',
  'WorkPackagesTableService',
  'WorkPackageService',
  'WorkPackageContextMenuHelper',
  function(PERMITTED_MORE_MENU_ACTIONS,
           $state,
           $window,
           I18n,
           flags,
           PathHelper,
           WorkPackagesTableService,
           WorkPackageService,
           WorkPackageContextMenuHelper){

  return {
    restrict: 'E',
    replace: true,
    templateUrl: '/templates/work_packages/work_package_details_toolbar.html',
    scope: {
      workPackage: '=',
      rows: '='
    },
    link: function(scope, element, attributes) {
      scope.I18n = I18n;

      scope.$watch('rows', function(newVal, oldVal) {
        if (!scope.workPackage) { return; }

        // More Menu
        var workPackageRows = WorkPackagesTableService.getRowsByWorkPackageIds([scope.workPackage.props.id]);

        if (workPackageRows && workPackageRows.length == 1) {
          var rowObject = workPackageRows[0].object;

          scope.permittedActions = WorkPackageContextMenuHelper.getPermittedActions([rowObject], PERMITTED_MORE_MENU_ACTIONS);
        }
      });


      scope.editWorkPackage = function() {
        // TODO: Temporarily going to the old edit dialog until we get in-place editing done
        window.location = "/work_packages/" + scope.workPackage.props.id;
      };

      scope.triggerMoreMenuAction = function(action, link) {
        var actionLink;

        switch (action) {
          case 'delete':
            deleteSelectedWorkPackage();
            break;
          case 'log_time':
            actionLink = PathHelper.timeEntryNewPath(scope.workPackage.props.id);
            break;
          case 'duplicate':
            actionLink = PathHelper.workPackageDuplicatePath(scope.workPackage.props.projectId, scope.workPackage.props.id);
            break;
          case 'move':
            actionLink = PathHelper.workPackageMovePath(scope.workPackage.props.id)
            break;
        }

        if (actionLink) {
          $window.location.href = actionLink;
        }
      };

      function deleteSelectedWorkPackage() {
        var promis = WorkPackageService.performBulkDelete([scope.workPackage.props.id], true);

        promis.success(function(data, status) {
          $state.go('work-packages.list');
        });
      }
    }
  };
}]);
