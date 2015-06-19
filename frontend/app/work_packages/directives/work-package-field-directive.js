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

module.exports = function(WorkPackageFieldService, EditableFieldsState) {

  function workPackageFieldDirectiveController($scope) {
    this.state = EditableFieldsState;

    this.isEditable = function() {
      return WorkPackageFieldService.isEditable(EditableFieldsState.workPackage, this.field);
    };

    this.isEmpty = function() {
      return WorkPackageFieldService.isEmpty(EditableFieldsState.workPackage, this.field);
    };

    this.getLabel = function() {
      return WorkPackageFieldService.getLabel(EditableFieldsState.workPackage, this.field);
    };

    this.updateWriteValue = function() {
      this.writeValue = _.cloneDeep(WorkPackageFieldService.getValue(
        EditableFieldsState.workPackage,
        this.field
      ));
    };

    if (this.isEditable()) {
      this.state.isBusy = false;
      this.isEditing = false;
      this.updateWriteValue();
      this.editTitle = I18n.t('js.inplace.button_edit', { attribute: this.getLabel() });
    }
  }

  return {
    restrict: 'E',
    replace: true,
    controllerAs: 'fieldController',
    bindToController: true,
    templateUrl: '/templates/work_packages/field.html',
    scope: {
      field: '='
    },
    controller: workPackageFieldDirectiveController
  };
};
