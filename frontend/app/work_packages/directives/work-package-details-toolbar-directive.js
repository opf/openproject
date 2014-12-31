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

module.exports = function(PERMITTED_MORE_MENU_ACTIONS,
           $state,
           $window,
           $location,
           I18n,
           HookService,
           WorkPackageService,
           WorkPackageAuthorization,
           PathHelper) {

  function getPermittedActions(authorization, permittedMoreMenuActions) {
    var permittedActions = authorization.permittedActions(permittedMoreMenuActions);
    var augmentedActions = { };

    angular.forEach(permittedActions, function(value, key) {
      var css = ["icon-" + key];

      this[key] = { link: value, css: css };
    }, augmentedActions);

    return augmentedActions;
  }

  function getPermittedPluginActions(authorization) {
    var pluginActions = HookService.call('workPackageDetailsMoreMenu').reduce(function(previousValue, currentValue) {
                          return angular.extend(previousValue, currentValue);
                        }, { });

    var permittedPluginActions = authorization.permittedActions(Object.keys(pluginActions));
    var augmentedPluginActions = { };

    angular.forEach(permittedPluginActions, function(value, key) {
      var css = [].concat(pluginActions[key]);

      if (css.length == 0) {
        css = ["icon-" + key];
      }

      this[key] = { link: value, css: css };
    }, augmentedPluginActions);

    return augmentedPluginActions;
  }

  return {
    restrict: 'E',
    templateUrl: '/templates/work_packages/work_package_details_toolbar.html',
    scope: {
      workPackage: '='
    },
    link: function(scope, element, attributes) {
      var authorization = new WorkPackageAuthorization(scope.workPackage);

      scope.I18n = I18n;
      scope.permittedActions = angular.extend(getPermittedActions(authorization, PERMITTED_MORE_MENU_ACTIONS),
                                              getPermittedPluginActions(authorization));
      scope.actionsAvailable = Object.keys(scope.permittedActions).length > 0;

      scope.editWorkPackage = function() {
        var editWorkPackagePath = PathHelper.staticEditWorkPackagePath(scope.workPackage.props.id);
        var backUrl = '?back_url=' + encodeURIComponent($location.url());

        // TODO: Temporarily going to the old edit dialog until we get in-place editing done
        window.location = editWorkPackagePath + backUrl;
      };

      scope.triggerMoreMenuAction = function(action, link) {
        switch (action) {
          case 'delete':
            deleteSelectedWorkPackage();
            break;
          default:
            $window.location.href = link;
            break;
        }
      };

      function deleteSelectedWorkPackage() {
        var promise = WorkPackageService.performBulkDelete([scope.workPackage.props.id], true);

        promise.success(function(data, status) {
          $state.go('work-packages.list');
        });
      }
    }
  };
};
