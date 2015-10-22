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
  .module('openproject.inplace-edit')
  .directive('workPackageField', workPackageField);

function workPackageField() {
  return {
    restrict: 'E',
    replace: true,
    templateUrl: '/components/inplace-edit/directives/work-package-field/' +
      'work-package-field.directive.html',
    scope: {
      fieldName: '='
    },

    bindToController: true,
    controller: WorkPackageFieldController,
    controllerAs: 'fieldController'
  };
}

function WorkPackageFieldController($scope, EditableFieldsState, inplaceEditField) {
  this.state = EditableFieldsState;
  $scope.field = new inplaceEditField(EditableFieldsState.workPackage, this.fieldName);
  var field = $scope.field;

  if (field.isEditable()) {
    this.state.isBusy = false;
    this.isEditing = this.state.forcedEditState;
    this.editTitle = I18n.t('js.inplace.button_edit', { attribute: field.getLabel() });
  }
}
WorkPackageFieldController.$inject = ['$scope', 'EditableFieldsState', 'inplaceEditField'];

