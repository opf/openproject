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

module.exports = function(WorkPackageFieldService, $window, $timeout) {

  // specifies unhideable (during creation)
  var unhideableFields = [
    'subject',
    'type',
    'status',
    'description',
    'priority',
    'assignee',
    'percentageDone'
  ];
  var firstTimeFocused = false;
  var isGroupHideable = function (groupedFields, groupName, workPackage, cb) {
        if (!workPackage) {
          return true;
        }
        var group = _.find(groupedFields, {groupName: groupName});
        var isHideable = typeof cb === 'undefined' ? isFieldHideable : cb;
        return _.every(group.attributes, function(field) {
          return isHideable(workPackage, field);
        });
      },
      isFieldHideable = function (workPackage, field) {
        if (!workPackage) {
          return true;
        }
        return WorkPackageFieldService.isHideable(workPackage, field);
      },
      isFieldHideableOnCreate = function(workPackage, field) {
        if (!workPackage) {
          return true;
        }
        if (!isSpecified(workPackage, field)) {
          return true;
        }

        if (!isEditable(workPackage, field)) {
          return true;
        }

        if (_.contains(unhideableFields, field)) {
          return !WorkPackageFieldService.isEditable(workPackage, field);
        }

        if (WorkPackageFieldService.isRequired(workPackage, field)) {
          return false;
        }

        return WorkPackageFieldService.isHideable(workPackage, field);
      },
      isSpecified = function (workPackage, field) {
        if (!workPackage) {
          return false;
        }
        return WorkPackageFieldService.isSpecified(workPackage, field);
      },
      isEditable = function(workPackage, field) {
        return WorkPackageFieldService.isEditable(workPackage, field);
      },
      hasNiceStar = function (workPackage, field) {
        if (!workPackage) {
          return false;
        }
        return WorkPackageFieldService.isRequired(workPackage, field) &&
          WorkPackageFieldService.isEditable(workPackage, field);
      },
      getLabel = function (workPackage, field) {
        if (!(workPackage && typeof field === 'string')) {
          return '';
        }
        return WorkPackageFieldService.getLabel(workPackage, field);
      },
      setFocus = function() {
        if (!firstTimeFocused) {
          firstTimeFocused = true;
          $timeout(function() {
            // TODO: figure out a better way to fix the wp table columns bug
            // where arrows are misplaced when not resizing the window
            angular.element($window).trigger('resize');
            angular.element('.work-packages--details--subject .focus-input').focus();
          });
        }
      },
      showToggleButton = function () {
        return true;
      };

  return {
    isGroupHideable: isGroupHideable,
    isFieldHideable: isFieldHideable,
    isFieldHideableOnCreate: isFieldHideableOnCreate,
    isSpecified: isSpecified,
    isEditable: isEditable,
    hasNiceStar: hasNiceStar,
    getLabel: getLabel,
    setFocus: setFocus,
    showToggleButton: showToggleButton
  };
};
