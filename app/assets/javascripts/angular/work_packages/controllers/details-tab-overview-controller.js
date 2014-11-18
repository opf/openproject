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

module.exports = function($scope,
           I18n,
           WorkPackagesOverviewService,
           TEXT_TYPE,
           VERSION_TYPE,
           CATEGORY_TYPE,
           USER_TYPE,
           TIME_ENTRY_TYPE,
           USER_FIELDS,
           CustomFieldHelper,
           WorkPackagesHelper,
           PathHelper,
           UserService,
           VersionService,
           HookService,
           $q) {

  // work package properties

  $scope.userPath = PathHelper.staticUserPath;

    function getPropertyValue(property, format) {
        switch(format) {
            case VERSION_TYPE:
                if ($scope.workPackage.props.versionId == undefined) {
                    return;
                }
                var versionId = $scope.workPackage.props.versionId,
                    versionLinkPresent = !!$scope.workPackage.links.version;
                var versionTitle = versionLinkPresent ? $scope.workPackage.links.version.props.title : $scope.workPackage.props.versionName,
                    versionHref  = versionLinkPresent ? $scope.workPackage.links.version.href : null;
                return {href: versionHref, title: versionTitle, viewable: versionLinkPresent};
                break;
            case USER_TYPE:
                return $scope.workPackage.embedded[property];
                break;
            case CATEGORY_TYPE:
                return $scope.workPackage.embedded[property];
                break;
            case TIME_ENTRY_TYPE:
                var spentTime = $scope.workPackage.props.spentTime,
                    timeLinkPresent = !!$scope.workPackage.links.timeEntries,
                    formattedValue = WorkPackagesHelper.formatWorkPackageProperty(spentTime, property),
                    timeHref  = PathHelper.timeEntriesPath(null, $scope.workPackage.props.id);
                return {href: timeHref, title: formattedValue, viewable: timeLinkPresent};
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

  $scope.groupedAttributes = WorkPackagesOverviewService.getGroupedWorkPackageOverviewAttributes();

  (function setupWorkPackageProperties() {
    var otherAttributes = WorkPackagesOverviewService.getGroupAttributesForGroupedAttributes('other', $scope.groupedAttributes);

    angular.forEach($scope.workPackage.props.customProperties, function(customProperty) {
      this.push(customProperty);
    }, otherAttributes);

    angular.forEach($scope.groupedAttributes, function(group) {
      var attributesWithValues = [];

      angular.forEach(group.attributes, function(attribute) {
        if (typeof attribute == 'string') {
          this.push(getWorkPackageProperty(attribute));
        } else {
          this.push(getWorkPackageCustomProperty(attribute));
        }
      }, attributesWithValues);

      group.attributes = attributesWithValues;
    });

    // The loops before overwrite the attributes array of group 'other'. Thus,
    // to get the current values of that array, I need to get that array again.
    otherAttributes = WorkPackagesOverviewService.getGroupAttributesForGroupedAttributes('other', $scope.groupedAttributes);
    // Sorting the 'other' group is an acutal requirement. So, check if the
    // requirement has changed before removing this code!
    otherAttributes.sort(function(a, b) {
      return a.label.toLowerCase().localeCompare(b.label.toLowerCase());
    });
  })();

  function getWorkPackageProperty(property) {
    var label  = I18n.t('js.work_packages.properties.' + property),
        format = getPropertyFormat(property),
        value  = getPropertyValue(property, format);

    if (!(value === null || value === undefined)) {
      return getFormattedValueToPresentProperties(property, label, value, format);
    } else {
      var plugInValues = HookService.call('workPackageOverviewAttributes',
                                          { type: property,
                                            workPackage: $scope.workPackage });

      if (plugInValues.length == 0) {
        return getFormattedValueToPresentProperties(property, label, null, format);
      } else {
        for (var x = 0; x < plugInValues.length; x++) {
          return getFormattedValueToPresentProperties(property, label, plugInValues[x], 'dynamic');
        }
      }
    }
  }

  function getWorkPackageCustomProperty(property) {
    var label = property.name,
        value = (property.value) ? getCustomPropertyValue(property) : null,
        format = property.format;

    return getFormattedValueToPresentProperties(property.name, label, value, format);
  }

  function getPropertyFormat(property) {
    switch(property) {
    case 'versionName':
      return VERSION_TYPE;
    case 'category':
      return CATEGORY_TYPE;
    case 'spentTime':
      return TIME_ENTRY_TYPE;
    default:
      return USER_FIELDS.indexOf(property) === -1 ? TEXT_TYPE : USER_TYPE;
    }
  }

  function getCustomPropertyValue(property) {
    switch(property.format) {
      case VERSION_TYPE:
        return setCustomPropertyVersionValue(property);
      case USER_TYPE:
        return UserService.getUser(property.value);
      default:
        return CustomFieldHelper.formatCustomFieldValue(property.value, property.format);
    }
  }

  function getFormattedValueToPresentProperties(property, label, value, format) {
    var propertyData = {
      property: property,
      label: label,
      format: format,
      value: null
    };

    $q.when(value).then(function(value) {
      propertyData.value = value;
    });

    return propertyData;
  }

  function setCustomPropertyVersionValue(property) {
    var versionHref = PathHelper.staticBase + PathHelper.versionPath(property.value);
    var versionTitle = I18n.t('js.error_could_not_resolve_version_name');
    var projectId = $scope.workPackage.props.projectId;
    var versions = VersionService.getVersions(projectId);

    var promise = $q.when(versions).then(function(value) {

      var version = _.find(value, function(version) {
        return version.id.toString() == property.value;
      });

      if (version) {
        versionTitle = version.name;
      }

      return { href: versionHref, title: versionTitle, viewable: true };
    }, function(reason) {
      return { href: versionHref, title: versionTitle, viewable: true };
    });

    return promise;
  }

  // toggles

  $scope.toggleStates = {
    hideFullDescription: true,
    hideAllAttributes: true
  };

  $scope.isGroupEmpty = function(group) {
    return group.attributes.filter(function(element) {
      return !$scope.isPropertyEmpty(element.value);
    }).length == 0;
  };

  $scope.anyEmptyWorkPackageValue = function() {
    return $scope.groupedAttributes.filter(function(element) {
      return $scope.isGroupEmpty(element);
    }).length > 0;
  };

  $scope.isPropertyEmpty = function(property) {
    return property === undefined || property === null;
  };
};
