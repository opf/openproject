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

module.exports = function(WorkPackageFieldService, EditableFieldsState, $timeout, HookService) {
  return {
    replace: true,
    transclude: true,
    scope: {},
    require: '^workPackageField',
    templateUrl: '/templates/work_packages/inplace_editor/display_pane.html',
    controller: function($scope) {

      this.placeholder = WorkPackageFieldService.defaultPlaceholder;

      this.startEditing = function() {
        var fieldController = $scope.fieldController;
        fieldController.isEditing = true;
      };

      this.isReadValueEmpty = function() {
        return WorkPackageFieldService.isEmpty(EditableFieldsState.workPackage, $scope.fieldController.field);
      };

      this.getReadValue = function() {
        return WorkPackageFieldService.format(EditableFieldsState.workPackage, $scope.fieldController.field);
      };

      // for dynamic type that is set by plugins
      this.getDynamicDirectiveName = function() {
        return HookService.call('workPackageOverviewAttributes', {
          type: EditableFieldsState.workPackage.schema.props[$scope.fieldController.field].type,
          workPackage: EditableFieldsState.workPackage
        }).pop();
      }

      // expose work package to the dynamic directive
      this.getWorkPackage = function() {
        return EditableFieldsState.workPackage;
      }

    },
    controllerAs: 'displayPaneController',
    link: function(scope, element, attrs, fieldController) {
      scope.fieldController = fieldController;
      scope.displayPaneController.field = scope.fieldController.field;
      scope.templateUrl = '/templates/components/inplace_editor/display/' +
        WorkPackageFieldService.getInplaceDisplayStrategy(
          EditableFieldsState.workPackage,
          fieldController.field
        ) +
        '.html';

      scope.$watch('fieldController.isEditing', function(isEditing) {
        if (!isEditing) {
          $timeout(function() {
            element.find('.inplace-editing--trigger-link').focus();
            element.find('.inplace-edit--read-value a').off('click').on('click', function(e) {
              e.stopPropagation();
            });
          });
        }
      });
    }
  };
}
