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
  $timeout,
  WorkPackageFieldService,
  EditableFieldsState,
  FocusHelper,
  I18n,
  ActivityService,
  ConfigurationService,
  AutoCompleteHelper) {

  function commentFieldDirectiveController($scope, $element) {
    var ctrl = this;
    ctrl.state = EditableFieldsState;
    ctrl.field = 'activity-comment';
    ctrl.state.isBusy = false;
    ctrl.isEditing = ctrl.state.forcedEditState;
    ctrl.editTitle = I18n.t('js.inplace.button_edit', { attribute: I18n.t('js.label_comment') });
    ctrl.placeholder = I18n.t('js.label_add_comment_title');

    ctrl.isEmpty = function() {
      return WorkPackageFieldService.isEmpty(EditableFieldsState.workPackage, ctrl.field);
    };

    ctrl.isEditable = function() {
      return true;
    };

    ctrl.submit = function(notify) {
      if (ctrl.writeValue === undefined) {
        /** Error handling */
        return;
      }

      ActivityService.createComment(
        $scope.workPackage,
        $scope.activities,
        ConfigurationService.commentsSortedInDescendingOrder(),
        ctrl.writeValue.raw
      ).then(function(response) {
        $scope.$emit('workPackageRefreshRequired', '');
        ctrl.discardEditing();
        return response;
      }, function(error) {
        console.log(error);
      });
    }

    ctrl.startEditing = function() {
      ctrl.isEditing = true;
      $timeout(function() {
        var inputElement = $element.find('.focus-input');
        FocusHelper.focus(inputElement);
        inputElement.triggerHandler('keyup');
        ctrl.markActive();
        inputElement.off('focus.inplace').on('focus.inplace', function() {
          $scope.$apply(function() {
            ctrl.markActive();
          });
        });
      });
    };

    ctrl.discardEditing = function() {
      ctrl.isEditing = false;
      delete ctrl.writeValue;
    };

    ctrl.isActive = function() {
      if (EditableFieldsState.forcedEditState) {
        return false;
      }
      return ctrl.field === EditableFieldsState.activeField;
    };

    ctrl.markActive = function() {
      EditableFieldsState.activeField = ctrl.field;
    };

    if (!EditableFieldsState.forcedEditState) {
      $element.bind('keydown keypress', function(e) {
        if (e.keyCode === 27) {
          $scope.$apply(function() {
            ctrl.discardEditing();
          });
        }
      });
    }
  }

  return {
    restrict: 'E',
    replace: true,
    require: '^?exclusiveEdit',
    controllerAs: 'fieldController',
    bindToController: true,
    templateUrl: '/templates/work_packages/comment_field.html',
    scope: {
      workPackage: '=',
      activities: '='
    },
    controller: commentFieldDirectiveController,
    link: function(scope, element, attrs, exclusiveEditController) {
      exclusiveEditController.setCreator(scope);

      // TODO: WorkPackage is not applied from attribute scope?
      scope.workPackage = scope.$parent.workPackage;
      scope.title = I18n.t('js.label_add_comment_title');
      scope.buttonTitle = I18n.t('js.label_add_comment');
      scope.buttonCancel = I18n.t('js.button_cancel');
      scope.canAddComment = !!scope.workPackage.links.addComment;
      scope.activity = { comment: '' };

      $timeout(function() {
        AutoCompleteHelper.enableTextareaAutoCompletion(
          angular.element.find('textarea.add-comment-text')
        );
      });
    }
  };
};
