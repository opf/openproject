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

module.exports = function(
           $scope,
           WorkPackagesOverviewService,
           WorkPackageFieldService
           ) {

  var vm = this;

  vm.groupedFields = [];
  vm.hideEmptyFields = true;
  vm.workPackage = $scope.workPackage;

  vm.isGroupEmpty = isGroupEmpty;
  vm.getLabel = getLabel;
  vm.showToggleButton = showToggleButton;

  activate();

  function activate() {
    vm.groupedFields = WorkPackagesOverviewService.getGroupedWorkPackageOverviewAttributes();
    //setupFields();
  }

  function isGroupEmpty(groupName) {
    return _.every(vm.groupedFields[groupName].attributes, function(field) {
      return WorkPackageFieldService.isEmpty(field);
    });
  }

  function getLabel(field) {
    return WorkPackageFieldService.getLabel(vm.workPackage, field);
  }

  function showToggleButton() {
    return true;
  }

  //function setupFields() {
  //  var groupedAttributes = WorkPackagesOverviewService.getGroupedWorkPackageOverviewAttributes();
  //  vm.fields = _.flatten(groupedAttributes.map(function(groupDefinitionObject) {
  //    return groupDefinitionObject.attributes.map(function(attributeName) {
  //      return {
  //        group: groupDefinitionObject.groupName,
  //        name: attributeName
  //      };
  //    });
  //  }));
  //}


  //
  //
  //$scope.inplaceProperties = OverviewTabInplaceEditorConfig.getInplaceProperties();
  //
  //$scope.userPath = PathHelper.staticUserPath;
  //AuthorisationService.initModelAuth('work_package' + $scope.workPackage.id,
  //                                   $scope.workPackage.links);
  //
  //function can(action) {
  //  return AuthorisationService.can('work_package' + $scope.workPackage.id, action);
  //}
  //
  //function getPropertyValue(property, format) {
  //  switch(format) {
  //  case STATUS_TYPE:
  //  case VERSION_TYPE:
  //  case USER_TYPE:
  //  case CATEGORY_TYPE:
  //  case PRIORITY_TYPE:
  //    return $scope.workPackage.embedded[property];
  //  case TIME_ENTRY_TYPE:
  //    return getLinkedTimeEntryValue(property);
  //  default:
  //    return getFormattedPropertyValue(property);
  //  }
  //}
  //
  //function getLinkedTimeEntryValue(property) {
  //  var hasLink = !!$scope.workPackage.links.timeEntries,
  //      link = '',
  //      value = 0;
  //
  //  if (hasLink) {
  //    link = $scope.workPackage.links.timeEntries.href;
  //  }
  //
  //  if (hasLink && $scope.workPackage.props.spentTime !== undefined) {
  //    value = $scope.workPackage.props.spentTime;
  //  }
  //
  //  var formattedValue = WorkPackagesHelper.formatWorkPackageProperty(value, property);
  //
  //  return {href: link, title: formattedValue, viewable: link !== ''};
  //}
  //
  //function getFormattedPropertyValue(property) {
  //  if (property === 'date') {
  //    return getDateProperty();
  //  } else {
  //    return WorkPackagesHelper.formatWorkPackageProperty($scope.workPackage.props[property], property);
  //  }
  //}
  //
  //function getDateProperty() {
  //  if ($scope.workPackage.props.startDate || $scope.workPackage.props.dueDate) {
  //    var displayedStartDate = WorkPackagesHelper.formatWorkPackageProperty($scope.workPackage.props.startDate, 'startDate') || I18n.t('js.label_no_start_date'),
  //        displayedEndDate   = WorkPackagesHelper.formatWorkPackageProperty($scope.workPackage.props.dueDate, 'dueDate') || I18n.t('js.label_no_due_date');
  //
  //    return  displayedStartDate + ' - ' + displayedEndDate;
  //  }
  //}
  //

  //$scope.groupedAttributes = WorkPackagesOverviewService.getGroupedWorkPackageOverviewAttributes();
  //
  //(function filterUnallowedAttributes() {
  //  var attributes = $scope.groupedAttributes;
  //
  //  angular.forEach(attributes, function(attributesGroup) {
  //    angular.forEach(attributesGroup.attributes, function(attribute) {
  //      if (!isAllowedProperty(attribute)) {
  //        var index = attributesGroup.attributes.indexOf(attribute);
  //
  //        attributesGroup.attributes.splice(index, 1);
  //      }
  //    });
  //  });
  //
  //  return attributes;
  //})();
  //
  //function isAllowedProperty(property) {
  //  switch (property) {
  //  case 'spentTime':
  //    return can('timeEntries');
  //  default:
  //    return true;
  //  }
  //}
  //
  //(function setupWorkPackageProperties() {
  //  var otherAttributes = WorkPackagesOverviewService.getGroupAttributesForGroupedAttributes('other', $scope.groupedAttributes);
  //
  //
  //  function getValue(workPackage, prop, propName) {
  //    if (workPackage.props[propName]) {
  //      if (!_.isUndefined(workPackage.props[propName].raw)) {
  //        return workPackage.props[propName].raw;
  //      }
  //      return workPackage.props[propName];
  //    }
  //    if (workPackage.embedded[propName]) {
  //      // this is here for compatibility with other code
  //      // TODO: rewrite all this file when custom fields
  //      // are editable
  //      if (prop.type == 'User' || prop.type == 'Version') {
  //        return workPackage.embedded[propName].props.id;
  //      } else {
  //        return workPackage.embedded[propName].props.value;
  //      }
  //    }
  //    return null;
  //  }
  //
  //  function getInplaceConfig(prop) {
  //    var config;
  //    switch(prop.type) {
  //      case 'Formattable':
  //        config = {
  //          type: 'wiki_textarea',
  //          attribute: prop.name,
  //          embedded: true,
  //          placeholder: '-',
  //          displayStrategy: 'wiki_textarea',
  //          attributeTitle: I18n.t('js.work_packages.properties.' + prop.name)
  //        };
  //      case 'User':
  //        config = {
  //          type: 'user',
  //          attribute: prop.name,
  //          embedded: false,
  //          placeholder: '-',
  //          displayStrategy: 'user',
  //          attributeTitle: I18n.t('js.work_packages.properties.' + prop.name)
  //        };
  //      case 'Version':
  //        config = {
  //          type: 'version',
  //          attribute: prop.name,
  //          embedded: true,
  //          placeholder: '-',
  //          displayStrategy: 'version',
  //          attributeTitle: I18n.t('js.work_packages.properties.' + prop.name)
  //        };
  //      case 'StringObject':
  //        config = {
  //          type: 'select2',
  //          attribute: prop.name,
  //          embedded: true,
  //          placeholder: '-',
  //          attributeTitle: I18n.t('js.work_packages.properties.' + prop.name)
  //        };
  //    }
  //
  //    return config;
  //  }
  //
  //  function getCustomProperties(workPackage) {
  //    return _.compact(_.map(
  //        workPackage.schema.props,
  //        function(prop, propName) {
  //          if (propName.match(/^customField/)) {
  //            return {
  //              name: prop.name,
  //              format: prop.type.toLowerCase(),
  //              value: getValue(workPackage, prop, propName),
  //              isCustom: true,
  //              inplaceConfig: getInplaceConfig(prop)
  //            };
  //          }
  //          return false;
  //    }));
  //  }
  //
  //  angular.forEach(
  //    getCustomProperties($scope.workPackage),
  //    function(customProperty) {
  //      this.push(customProperty);
  //    }, otherAttributes);
  //
  //  angular.forEach($scope.groupedAttributes, function(group) {
  //    var attributesWithValues = [];
  //
  //    angular.forEach(group.attributes, function(attribute) {
  //      if (typeof attribute == 'string') {
  //        this.push(getWorkPackageProperty(attribute));
  //      } else {
  //        this.push(getWorkPackageCustomProperty(attribute));
  //      }
  //    }, attributesWithValues);
  //
  //    group.attributes = attributesWithValues;
  //  });
  //
  //  // The loops before overwrite the attributes array of group 'other'. Thus,
  //  // to get the current values of that array, I need to get that array again.
  //  otherAttributes = WorkPackagesOverviewService.getGroupAttributesForGroupedAttributes('other', $scope.groupedAttributes);
  //  // Sorting the 'other' group is an acutal requirement. So, check if the
  //  // requirement has changed before removing this code!
  //  otherAttributes.sort(function(a, b) {
  //    return a.label.toLowerCase().localeCompare(b.label.toLowerCase());
  //  });
  //})();
  //
  //function getWorkPackageProperty(property) {
  //  var label  = I18n.t('js.work_packages.properties.' + property),
  //      format = getPropertyFormat(property),
  //      value  = getPropertyValue(property, format);
  //
  //  if (!(value === null || value === undefined)) {
  //    return getFormattedValueToPresentProperties(property, label, value, format);
  //  } else {
  //    var plugInValues = HookService.call('workPackageOverviewAttributes',
  //                                        { type: property,
  //                                          workPackage: $scope.workPackage });
  //
  //    if (plugInValues.length == 0) {
  //      return getFormattedValueToPresentProperties(property, label, null, format);
  //    } else {
  //      for (var x = 0; x < plugInValues.length; x++) {
  //        return getFormattedValueToPresentProperties(property, label, plugInValues[x], 'dynamic');
  //      }
  //    }
  //  }
  //}
  //
  //function getWorkPackageCustomProperty(property) {
  //  var label = property.name,
  //      value = (property.value) ? getCustomPropertyValue(property) : null,
  //      format = property.format;
  //
  //  return getFormattedValueToPresentProperties(property.name, label, value, format);
  //}
  //
  //function getPropertyFormat(property) {
  //  switch(property) {
  //  case 'status':
  //    return STATUS_TYPE;
  //  case 'version':
  //    return VERSION_TYPE;
  //  case 'category':
  //    return CATEGORY_TYPE;
  //  case 'priority':
  //    return PRIORITY_TYPE;
  //  case 'spentTime':
  //    return TIME_ENTRY_TYPE;
  //  default:
  //    return USER_FIELDS.indexOf(property) === -1 ? TEXT_TYPE : USER_TYPE;
  //  }
  //}
  //
  //function getCustomPropertyValue(property) {
  //  switch(property.format) {
  //    case USER_TYPE:
  //      return getCustomPropertyUserValue(property);
  //    case VERSION_TYPE:
  //      return getCustomPropertyVersionValue(property);
  //    default:
  //      return CustomFieldHelper.formatCustomFieldValue(property.value, property.format);
  //  }
  //}
  //
  //function getFormattedValueToPresentProperties(property, label, value, format) {
  //  var propertyData = {
  //    property: property,
  //    label: label,
  //    format: format,
  //    value: null
  //  };
  //
  //  $q.when(value).then(function(value) {
  //    propertyData.value = value;
  //  });
  //
  //  return propertyData;
  //}
  //
  //function getCustomPropertyVersionValue(property) {
  //  var versionHref = PathHelper.staticBase + PathHelper.versionPath(property.value);
  //  var versionTitle = I18n.t('js.error_could_not_resolve_version_name');
  //  var projectId = $scope.workPackage.embedded.project.props.id;
  //  var versions = VersionService.getVersions(projectId);
  //
  //  var promise = $q.when(versions).then(function(value) {
  //
  //    var version = _.find(value, function(version) {
  //      if (version.id) {
  //        return version.id.toString() == property.value;
  //      }
  //    });
  //
  //    if (version) {
  //      versionTitle = version.name;
  //    }
  //
  //    return { href: versionHref, title: versionTitle, viewable: true };
  //  }, function(reason) {
  //    return { href: versionHref, title: versionTitle, viewable: true };
  //  });
  //
  //  return promise;
  //}
  //
  //
  //function getCustomPropertyUserValue(property) {
  //  var userHref = PathHelper.staticBase + PathHelper.userPath(property.value);
  //  var userTitle = I18n.t('js.error_could_not_resolve_user_name');
  //  var user = UserService.getUser(property.value);
  //
  //  var promise = $q.when(user).then(function(value) {
  //    userTitle = value.props.name;
  //
  //    return { href: userHref, title: userTitle, viewable: true };
  //  }, function() {
  //    return { href: userHref, title: userTitle, viewable: true };
  //  });
  //
  //  return promise;
  //}
  //
  //// toggles
  //
  //$scope.toggleStates = {
  //  hideFullDescription: true,
  //  hideAllAttributes: true
  //};
  //
  //$scope.isGroupEmpty = function(group) {
  //  return _.every(group.attributes, function(element) {
  //    return $scope.isPropertyEmpty(element.value);
  //  });
  //};
  //
  //$scope.anyEmptyWorkPackageValue = function() {
  //  return _.any($scope.groupedAttributes, function(element) {
  //    return $scope.anyEmptyPropertyInGroup(element);
  //  });
  //};
  //
  //$scope.anyEmptyPropertyInGroup = function(group) {
  //  return _.any(group.attributes, function(element) {
  //    return $scope.isPropertyEmpty(element.value);
  //  });
  //};
  //
  //$scope.isPropertyEmpty = function(property) {
  //  return property === undefined || property === null;
  //};
};
