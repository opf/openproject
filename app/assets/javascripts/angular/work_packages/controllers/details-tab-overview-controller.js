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

.constant('USER_TYPE', 'user')

.controller('DetailsTabOverviewController', [
  '$scope',
  'I18n',
  'ConfigurationService',
  'USER_TYPE',
  'CustomFieldHelper',
  'WorkPackagesHelper',
  'UserService',
  'HookService',
  '$q',
  function($scope,
           I18n,
           ConfigurationService,
           USER_TYPE,
           CustomFieldHelper,
           WorkPackagesHelper,
           UserService,
           HookService,
           $q) {

  // work package properties

  $scope.presentWorkPackageProperties = [];
  $scope.emptyWorkPackageProperties = [];
  $scope.userPath = PathHelper.staticUserPath;

  var workPackageProperties = ConfigurationService.workPackageAttributes();

  function getPropertyValue(property, format) {
    if (format === USER_TYPE) {
      return $scope.workPackage.embedded[property];
    } else {
      return getFormattedPropertyValue(property);
    }
  }

  function getFormattedPropertyValue(property) {
    if (property === 'date') {
      return getDateProperty();
    } else {
      return WorkPackagesHelper.formatWorkPackageProperty($scope.workPackage.props[property], property);
    }
  }

  function getDateProperty() {
    if ($scope.workPackage.props.startDate || $scope.workPackage.props.dueDate) {
      var displayedStartDate = WorkPackagesHelper.formatWorkPackageProperty($scope.workPackage.props.startDate, 'startDate') || I18n.t('js.label_no_start_date'),
          displayedEndDate   = WorkPackagesHelper.formatWorkPackageProperty($scope.workPackage.props.dueDate, 'dueDate') || I18n.t('js.label_no_due_date');

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
        return $scope.workPackage.props[property];
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

      if (!(value === null || value === undefined) ||
          index < 3 ||
          index < 6 && secondRowToBeDisplayed()) {
        addFormattedValueToPresentProperties(property, label, value, format);
      } else {
        var plugInValues = HookService.call('workPackageOverviewAttributes',
                                            { type: property,
                                              workPackage: $scope.workPackage });

        if (plugInValues.length == 0) {
          $scope.emptyWorkPackageProperties.push(label);
        } else {
          for (var x = 0; x < plugInValues.length; x++) {
            addFormattedValueToPresentProperties(property, label, plugInValues[x], 'dynamic');
          }
        }
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
    angular.forEach($scope.workPackage.props.customProperties, function(customProperty) {
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


}]);
