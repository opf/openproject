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

angular
  .module('openproject.workPackages.helpers')
  .factory('WorkPackageContextMenuHelper', WorkPackageContextMenuHelper);

function WorkPackageContextMenuHelper(PERMITTED_BULK_ACTIONS, WorkPackagesTableService, HookService, UrlParamsHelper) {

  function getPermittedActionLinks(workPackage, permittedActionConstants) {
    var singularPermittedActions = [];

    var allowedActions = getAllowedActions(workPackage, permittedActionConstants);

    angular.forEach(allowedActions, function(allowedAction) {
      singularPermittedActions.push({
        icon: allowedAction.icon,
        text: allowedAction.text,
        link: workPackage[allowedAction.link].href
      });
    });

    return singularPermittedActions;
  }

  function getIntersectOfPermittedActions(workPackages) {
    var bulkPermittedActions = [];

    var permittedActions = _.filter(PERMITTED_BULK_ACTIONS, function(action) {
      return _.every(workPackages, function(workPackage) {
        return getAllowedActions(workPackage, [action]).length >= 1;
      });
    });
    angular.forEach(permittedActions, function(permittedAction) {
      bulkPermittedActions.push({
        icon: permittedAction.icon,
        text: permittedAction.text,
        link: getBulkActionLink(permittedAction,
          workPackages)
      });
    });

    return bulkPermittedActions;
  }

  function getBulkActionLink(action, workPackages) {
    var bulkLinks = WorkPackagesTableService.getBulkLinks();

    var workPackageIdParams = {
      'ids[]': workPackages.map(function(wp){
        return wp.id;
      })
    };
    var serializedIdParams = UrlParamsHelper.buildQueryString(workPackageIdParams);

    var linkAndQueryString = bulkLinks[action.link].split('?');
    var link = linkAndQueryString.shift();
    var queryParts = linkAndQueryString.concat(new Array(serializedIdParams));

    return link + '?' + queryParts.join('&');
  }

  function getAllowedActions(workPackage, actions) {
    var allowedActions = [];

    angular.forEach(actions, function(action) {
      if (workPackage.hasOwnProperty(action.link)) {
        action.text = I18n.t('js.button_' + action.icon);
        allowedActions.push(action);
      }
    });

    angular.forEach(HookService.call('workPackageTableContextMenu'), function(action) {
      if (workPackage.hasOwnProperty(action.link)) {
        var index = action.indexBy ? action.indexBy(allowedActions) : allowedActions.length;
        allowedActions.splice(index, 0, action)
      }
    });

    return allowedActions;
  }

  var WorkPackageContextMenuHelper = {
    getPermittedActions: function (workPackages, permittedActionConstants) {
      if (workPackages.length === 1) {
        return getPermittedActionLinks(workPackages[0], permittedActionConstants);
      } else if (workPackages.length > 1) {
        return getIntersectOfPermittedActions(workPackages);
      }
    }
  };

  return WorkPackageContextMenuHelper;
}
