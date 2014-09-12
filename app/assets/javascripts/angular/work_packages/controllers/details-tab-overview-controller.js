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

.constant('TEXT_TYPE', 'text')
.constant('VERSION_TYPE', 'version')
.constant('CATEGORY_TYPE', 'category')
.constant('USER_TYPE', 'user')
.constant('USER_FIELDS', ['assignee', 'author', 'responsible'])

.controller('DetailsTabOverviewController', [
  '$scope',
  'I18n',
  'ConfigurationService',
  'TEXT_TYPE',
  'VERSION_TYPE',
  'CATEGORY_TYPE',
  'USER_TYPE',
  'USER_FIELDS',
  'CustomFieldHelper',
  'WorkPackagesHelper',
  'PathHelper',
  'UserService',
  'HookService',
  '$q',
  function($scope,
           I18n,
           ConfigurationService,
           TEXT_TYPE,
           VERSION_TYPE,
           CATEGORY_TYPE,
           USER_TYPE,
           USER_FIELDS,
           CustomFieldHelper,
           WorkPackagesHelper,
           PathHelper,
           UserService,
           HookService,
           $q) {

  // work package properties

  $scope.presentWorkPackageProperties = [];
  $scope.emptyWorkPackageProperties = [];
  $scope.userPath = PathHelper.staticUserPath;

  var workPackageProperties = ConfigurationService.workPackageAttributes();

    function getPropertyValue(property, format) {
        switch(format) {
            case VERSION_TYPE:
                if ($scope.workPackage.props.versionId == undefined) {
                    return;
                }
                var versionId = $scope.workPackage.props.versionId;
                return {href: PathHelper.versionPath(versionId), title: $scope.workPackage.props.versionName};
                break;
            case USER_TYPE:
                return $scope.workPackage.embedded[property];
                break;
            case CATEGORY_TYPE:
                return $scope.workPackage.embedded[property];
                break;
            default:
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

  function getWorkPackagePropertiesInSpecifiedOrder(workPackageProperties) {
    // The work package property oder is specified as follows:
    // 1. The first 6 properties are:
    //    'Status', 'Assigned To', 'Responsible'
    //    'Date' '% Done', 'Priority'
    // 2. All remaining properties are sorted in their alphabetical order
    var propertiesForFirstTwoRows = workPackageProperties.slice(0, 6);
    var remainingProperties = workPackageProperties.slice(6);
    var remainingPropertiesByLabels = { };
    var propertyLabels;
    var workPackagePropertiesInSpecificOrder = propertiesForFirstTwoRows;

    for (var x = 0; x < remainingProperties.length; x++) {
      var property = remainingProperties[x];
      var label = (typeof property == 'string') ? I18n.t('js.work_packages.properties.' + property) : property.name;

      remainingPropertiesByLabels[label] = property;
    }

    propertyLabels = Object.keys(remainingPropertiesByLabels).sort(function(a, b) {
      return a.toLowerCase().localeCompare(b.toLowerCase());
    });

    for (var x = 0; x < propertyLabels.length; x++) {
      workPackagePropertiesInSpecificOrder.push(remainingPropertiesByLabels[propertyLabels[x]]);
    }

    return workPackagePropertiesInSpecificOrder;
  }

  (function setupWorkPackageProperties() {
    var properties = workPackageProperties.concat($scope.workPackage.props.customProperties);
    var sortedProperties = getWorkPackagePropertiesInSpecifiedOrder(properties);

    angular.forEach(sortedProperties, function(property, index) {
      if (typeof property == 'string') {
        addWorkPackageProperty(property, index);
      } else {
        addWorkPackageCustomProperty(property);
      }
    });
  })();

  function getPropertyFormat(property) {
    var format = USER_FIELDS.indexOf(property) === -1 ? TEXT_TYPE : USER_TYPE;
    format = (property === 'versionName') ? VERSION_TYPE : format;
    format = (property === 'category') ? CATEGORY_TYPE : format;

    return format;
  }

  function addWorkPackageProperty(property, index) {
    var label  = I18n.t('js.work_packages.properties.' + property),
        format = getPropertyFormat(property);
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
  }

  function addWorkPackageCustomProperty(property) {
    var label = property.name,
        value = getCustomPropertyValue(property),
        format = property.format;

    if (property.value) {
      addFormattedValueToPresentProperties(property.name, label, value, format);
    } else {
      $scope.emptyWorkPackageProperties.push(label);
    }
  }

  function getCustomPropertyValue(customProperty) {
    if (!!customProperty.value && customProperty.format === USER_TYPE) {
      return UserService.getUser(customProperty.value);
    } else {
      return CustomFieldHelper.formatCustomFieldValue(customProperty.value, customProperty.format);
    }
  }

  // toggles

  $scope.toggleStates = {
    hideFullDescription: true,
    hideAllAttributes: true
  };


}]);
