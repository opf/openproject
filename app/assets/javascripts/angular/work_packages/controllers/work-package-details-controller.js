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

angular.module('openproject.workPackages.controllers')

.constant('DEFAULT_WORK_PACKAGE_PROPERTIES', [
  'status', 'assignee', 'responsible',
  'date', 'percentageDone', 'priority',
  'estimatedTime', 'versionName'
])
.constant('USER_TYPE', 'user')
.constant('VISIBLE_LATEST')

.controller('WorkPackageDetailsController', [
  '$scope',
  'latestTab',
  'workPackage',
  'I18n',
  'DEFAULT_WORK_PACKAGE_PROPERTIES',
  'USER_TYPE',
  'VISIBLE_LATEST',
  'CustomFieldHelper',
  'WorkPackagesHelper',
  'PathHelper',
  'UserService',
  '$q',
  'ConfigurationService',
  function($scope, latestTab, workPackage, I18n, DEFAULT_WORK_PACKAGE_PROPERTIES, USER_TYPE, VISIBLE_LATEST, CustomFieldHelper, WorkPackagesHelper, PathHelper, UserService, $q, ConfigurationService) {

    $scope.$on('$stateChangeSuccess', function(event, toState){
      latestTab.registerState(toState.name);
    });

    $scope.$on('workPackageRefreshRequired', function(event, toState){
      refreshWorkPackage();
    });

    // initialization
    setWorkPackageScopeProperties(workPackage);

    $scope.I18n = I18n;
    $scope.$parent.preselectedWorkPackageId = $scope.workPackage.props.id;
    $scope.maxDescriptionLength = 800;

    function refreshWorkPackage() {
      workPackage.links.self
        .fetch({force: true})
        .then(setWorkPackageScopeProperties);
    }

    function outputError(error) {
      $scope.$emit('flashMessage', {
        isError: true,
        text: error.message
      });
    }

    $scope.toggleWatch = function() {
      $scope.toggleWatchLink
        .fetch({ ajax: $scope.toggleWatchLink.props })
        .then(refreshWorkPackage, outputError);
    };

    // resources for tabs

    $scope.author = workPackage.embedded.author;

    // available watchers

    $scope.$watch('watchers.length', fetchAvailableWatchers)

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
     * @param {Array} collection Array of resources retrieved via hyperagend
     * @param {Array} resourcesToBeFilteredOut Entries to be filtered out
     *
     * @returns {Array} filtered collection
     */
    function getFilteredCollection(collection, resourcesToBeFilteredOut) {
      return collection.filter(function(resource) {
        return resourcesToBeFilteredOut.map(getResourceIdentifier).indexOf(getResourceIdentifier(resource)) === -1
      });
    }

    function fetchAvailableWatchers() {
      workPackage.links.availableWatchers
        .fetch()
        .then(function(data) {
          // Temporarily filter out watchers already assigned to the work package on the client-side
          $scope.availableWatchers = getFilteredCollection(data.embedded.availableWatchers, $scope.watchers);
          // TODO do filtering on the API side and replace the update of the available watchers with the code provided in the following line
          // $scope.availableWatchers = data.embedded.availableWatchers;
        });
    }

    $scope.addWatcher = function(id) {
      workPackage.link('addWatcher', {user_id: id})
        .fetch({ajax: {method: 'POST'}})
        .then(refreshWorkPackage, outputError)
    };

    $scope.presentWorkPackageProperties = [];
    $scope.emptyWorkPackageProperties = [];
    $scope.userPath = PathHelper.staticUserPath;

    var workPackageProperties = DEFAULT_WORK_PACKAGE_PROPERTIES;

    function setWorkPackageScopeProperties(workPackage){
      $scope.workPackage = workPackage;

      $scope.isWatched = !!workPackage.links.unwatch;
      $scope.toggleWatchLink = workPackage.links.watch === undefined ? workPackage.links.unwatch : workPackage.links.watch;
      $scope.watchers = workPackage.embedded.watchers;

      // activities and latest activities
      $scope.activitiesSortedInDescendingOrder = ConfigurationService.commentsSortedInDescendingOrder();
      $scope.activities = displayedActivities($scope.workPackage);
      // watchers

      $scope.watchers = workPackage.embedded.watchers;
      $scope.author = workPackage.embedded.author;

      // Attachments
      $scope.attachments = workPackage.embedded.attachments;

      // Author
      $scope.author = workPackage.embedded.author;
    }

    $scope.deleteWatcher = function(watcher) {
      watcher.links.removeWatcher
        .fetch({ ajax: watcher.links.removeWatcher.props })
        .then(refreshWorkPackage, outputError);
    };

    function displayedActivities(workPackage) {
      var activities = workPackage.embedded.activities;
      activities.splice(0, 1); // remove first activity (assumes activities are sorted chronologically)
      if ($scope.activitiesSortedInDescendingOrder) {
        activities.reverse();
      }
      return activities;
    }

    function getPropertyValue(property, format) {
      if (format === USER_TYPE) {
        return workPackage.embedded[property];
      } else {
        return getFormattedPropertyValue(property);
      }
    }

    function getFormattedPropertyValue(property) {
      if (property === 'date') {
        return getDateProperty();
      } else {
        return WorkPackagesHelper.formatWorkPackageProperty(workPackage.props[property], property);
      }
    }

    function getDateProperty() {
      if (workPackage.props.startDate || workPackage.props.dueDate) {
        var displayedStartDate = WorkPackagesHelper.formatWorkPackageProperty(workPackage.props.startDate, 'startDate') || I18n.t('js.label_no_start_date'),
            displayedEndDate   = WorkPackagesHelper.formatWorkPackageProperty(workPackage.props.dueDate, 'dueDate') || I18n.t('js.label_no_due_date');

        return  displayedStartDate + ' - ' + displayedEndDate;
      }
    }

    function addFormattedValueToPresentProperties(property, label, value, format) {
      var propertyData = {
        property: property,
        label: label,
        format: format,
        value: null
      };
      $q.when(value).then(function(value) {
        propertyData.value = value;
      });
      $scope.presentWorkPackageProperties.push(propertyData);
    }

    function secondRowToBeDisplayed() {
      return !!workPackageProperties
        .slice(3, 6)
        .map(function(property) {
          return workPackage.props[property];
        })
        .reduce(function(a, b) {
          return a || b;
        });
    }

    var userFields = ['assignee', 'author', 'responsible'];

    (function setupWorkPackageProperties() {
      angular.forEach(workPackageProperties, function(property, index) {
        var label  = I18n.t('js.work_packages.properties.' + property),
            format = userFields.indexOf(property) === -1 ? 'text' : USER_TYPE,
            value  = getPropertyValue(property, format);

        if (!!value ||
            index < 3 ||
            index < 6 && secondRowToBeDisplayed()) {
          addFormattedValueToPresentProperties(property, label, value, format);
        } else {
          $scope.emptyWorkPackageProperties.push(label);
        }
      });
    })();

    function getCustomPropertyValue(customProperty) {
      if (!!customProperty.value && customProperty.format === USER_TYPE) {
        return UserService.getUser(customProperty.value);
      } else {
        return CustomFieldHelper.formatCustomFieldValue(customProperty.value, customProperty.format);
      }
    }

    (function setupCustomProperties() {
      angular.forEach(workPackage.props.customProperties, function(customProperty) {
        var property = customProperty.name,
            label = customProperty.name,
            value = getCustomPropertyValue(customProperty),
            format = customProperty.format;

        if (customProperty.value) {
          addFormattedValueToPresentProperties(property, label, value, format);
        } else {
         $scope.emptyWorkPackageProperties.push(label);
        }
      });
    })();

    // toggles

    $scope.toggleStates = {
      hideFullDescription: true,
      hideAllAttributes: true
    };

    $scope.editWorkPackage = function() {
      // TODO: Temporarily going to the old edit dialog until we get in-place editing done
      window.location = "/work_packages/" + $scope.workPackage.props.id;
    };
  }
]);
