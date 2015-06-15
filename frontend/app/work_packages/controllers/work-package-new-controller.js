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
           $stateParams,
           PathHelper,
           WorkPackagesOverviewService,
           WorkPackageFieldService,
           WorkPackageService,
           EditableFieldsState
           ) {

  var vm = this,
      unhideableFields = [
        'subject',
        'type',
        'status',
        'description',
        'priority',
        'assignee',
        'percentageDone'
      ];

  vm.groupedFields = [];
  vm.hideEmptyFields = true;


  vm.isGroupHideable = isGroupHideable;
  vm.isFieldHideable = isFieldHideable;
  vm.getLabel = getLabel;
  vm.isSpecified = isSpecified;
  vm.isEditable = isEditable;
  vm.hasNiceStar = hasNiceStar;
  vm.showToggleButton = showToggleButton;

  activate();

  function activate() {
    EditableFieldsState.forcedEditState = true;
    WorkPackageService.initializeWorkPackage($scope.projectIdentifier, {
      type: PathHelper.apiV3TypePath($stateParams.type)
    }).then(function(wp) {
      vm.workPackage = wp;
      $scope.workPackage = wp;
      vm.groupedFields = WorkPackagesOverviewService.getGroupedWorkPackageOverviewAttributes();
      var schema = WorkPackageFieldService.getSchema(vm.workPackage);
      var otherGroup = _.find(vm.groupedFields, {groupName: 'other'});
      otherGroup.attributes = [];
      _.forEach(schema.props, function(prop, propName) {
        if (propName.match(/^customField/)) {
          otherGroup.attributes.push(propName);
        }
      });
      otherGroup.attributes.sort(function(a, b) {
        return getLabel(a).toLowerCase().localeCompare(getLabel(b).toLowerCase());
      });
    });

  }

  function isGroupHideable(groupName) {
    var group = _.find(vm.groupedFields, {groupName: groupName});
    return _.every(group.attributes, isFieldHideable);
  }

  function isFieldHideable(field) {
    if (!isSpecified(field)) {
      return true;
    }

    if (!isEditable(field)) {
      return true;
    }

    if (_.contains(unhideableFields, field)) {
      return !WorkPackageFieldService.isEditable(vm.workPackage, field);
    }

    if (WorkPackageFieldService.isRequired(vm.workPackage, field)) {
      return false;
    }
    return WorkPackageFieldService.isHideable(vm.workPackage, field);
  }

  function isSpecified(field) {
    return WorkPackageFieldService.isSpecified(vm.workPackage, field);
  }

  function isEditable(field) {
    return WorkPackageFieldService.isEditable(vm.workPackage, field);
  }

  function hasNiceStar(field) {
    return WorkPackageFieldService.isRequired(vm.workPackage, field) &&
      WorkPackageFieldService.isEditable(vm.workPackage, field);
  }

  function getLabel(field) {
    return WorkPackageFieldService.getLabel(vm.workPackage, field);
  }

  function showToggleButton() {
    return true;
  }
};
