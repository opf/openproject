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

module.exports = function(TextileService, EditableFieldsState, $sce, AutoCompleteHelper, $timeout) {
  return {
    restrict: 'E',
    transclude: true,
    replace: true,
    scope: {},
    require: '^workPackageField',
    templateUrl: '/templates/work_packages/inplace_editor/custom/editable/wiki_textarea.html',
    controller: function($scope) {
      this.isPreview = false;
      this.previewHtml = '';
      this.autocompletePath = '/work_packages/auto_complete.json?project_id=' +
        EditableFieldsState.workPackage.embedded.project.props.id;

      this.togglePreview = function() {
        this.isPreview = !this.isPreview;
        this.previewHtml = '';
        // $scope.error = null;
        if (!this.isPreview) {
          return;
        }
        $scope.fieldController.state.isBusy = true;
        TextileService
          .renderWithWorkPackageContext(
          EditableFieldsState.workPackage.form,
          $scope.fieldController.writeValue.raw)
          .then(angular.bind(this, function(r) {
            this.previewHtml = $sce.trustAsHtml(r.data);
            $scope.fieldController.state.isBusy = false;
          }), angular.bind(this, function() {
            this.isPreview = false;
            $scope.fieldController.state.isBusy = false;
          }));
      };
    },
    controllerAs: 'customEditorController',
    link: function(scope, element, attrs, fieldController) {
      scope.fieldController = fieldController;
      $timeout(function() {
        AutoCompleteHelper.enableTextareaAutoCompletion(element.find('textarea'));
        // set as dirty for the script to show a confirm on leaving the page
        element.find('textarea').data('changed', true);
      });
    }
  };
};
