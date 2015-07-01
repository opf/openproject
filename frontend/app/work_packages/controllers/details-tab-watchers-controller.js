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

module.exports = function($scope, $filter, $timeout, I18n, ADD_WATCHER_SELECT_INDEX) {
  $scope.I18n = I18n;
  $scope.focusElementIndex;

  $scope.watcher = { selected: null };
  $scope.watcher.selected =  $scope.watchers;

  fetchAvailableWatchers();
  $scope.watcherListString = function() {
    return _.map($scope.watcher.selected, function(item) {
      return item.props.name;
    }).join(', ');
  };

  /**
   * @name getResourceIdentifier
   * @function
   *
   * @description
   * Returns the resource identifier of an API resource retrieved via hyperagent
   *
   * @param {Object} resource The resource object
   *
   * @returns {String} identifier
   */
  function getResourceIdentifier(resource) {
    // TODO move to helper
    return resource.links.self.href;
  }

  /**
   * @name getFilteredCollection
   * @function
   *
   * @description
   * Filters collection of HAL resources by entries listed in resourcesToBeFilteredOut
   *
   * @param {Array} collection Array of resources retrieved via hyperagent
   * @param {Array} resourcesToBeFilteredOut Entries to be filtered out
   *
   * @returns {Array} filtered collection
   */
  function getFilteredCollection(collection, resourcesToBeFilteredOut) {
    return collection.filter(function(resource) {
      return resourcesToBeFilteredOut.map(getResourceIdentifier).indexOf(getResourceIdentifier(resource)) === -1;
    });
  }

  function fetchAvailableWatchers() {
    if ($scope.workPackage.links.availableWatchers === undefined) {
      $scope.availableWatchers = [];
      return;
    }

    $scope.workPackage.links.availableWatchers
      .fetch()
      .then(function(data) {
        // Temporarily filter out watchers already assigned to the work package on the client-side
        $scope.availableWatchers = getFilteredCollection(data.embedded.elements, $scope.watchers);
        // TODO do filtering on the API side and replace the update of the
        // available watchers with the code provided in the following line
        // $scope.availableWatchers = data.embedded.elements;
      });
  }

  function addWatcher(newValue, oldValue) {
    if (newValue && newValue !== oldValue) {
      var user = newValue[newValue.length - 1],
          href = user ? user.links.self.href : null;

      if (href) {
        var data = JSON.stringify({ user: { href: href } });
        $scope.workPackage.link('addWatcher', {})
          .fetch({ajax: {
              method: 'POST',
              contentType: 'application/json; charset=utf-8',
              data: data
            }})
          .then(addWatcherSuccess, $scope.outputError);
      }
    }
  }

  function addWatcherSuccess() {
    $scope.outputMessage(I18n.t("js.label_watcher_added_successfully"));
    $scope.refreshWorkPackage();

    $scope.watcher.selected = null;

    $scope.focusElementIndex = ADD_WATCHER_SELECT_INDEX;
  }

  $scope.deleteWatcher = function(watcher) {
    watcher.links.removeWatcher
      .fetch({ ajax: watcher.links.removeWatcher.props })
      .then(deleteWatcherSuccess(watcher), $scope.outputError);
  };

  function deleteWatcherSuccess(watcher) {
    $scope.outputMessage(I18n.t("js.label_watcher_deleted_successfully"));
    removeWatcherFromList(watcher);
  }

  function removeWatcherFromList(watcher) {
    var index = $scope.watchers.indexOf(watcher);

    if (index >= 0) {
      $scope.watchers.splice(index, 1);

      updateWatcherFocus(index);
      $scope.$emit('workPackageRefreshRequired');
    }
  }

  function updateWatcherFocus(index) {
    if ($scope.watchers.length == 0) {
      $scope.focusElementIndex = ADD_WATCHER_SELECT_INDEX;
    } else {
      $scope.focusElementIndex = (index < $scope.watchers.length) ? index : $scope.watchers.length - 1;
    }

    $timeout(function() {
      $scope.$broadcast('updateFocus');
    });
  }

  $scope.$watch('watchers.length', fetchAvailableWatchers);
  $scope.$watch('watcher.selected', addWatcher);
};
