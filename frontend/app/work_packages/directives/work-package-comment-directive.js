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
  AutoCompleteHelper,
  NotificationsService) {

  function commentFieldDirectiveController($scope, $element) {
    var ctrl = this;
    ctrl.state = EditableFieldsState;
    ctrl.field = 'activity-comment';

    ctrl.editTitle = I18n.t('js.inplace.button_edit', { attribute: I18n.t('js.label_comment') });
    ctrl.placeholder = I18n.t('js.label_add_comment_title');
    ctrl.title = I18n.t('js.label_add_comment_title');

    ctrl.state.isBusy = false;
    ctrl.isEditing = ctrl.state.forcedEditState;
    ctrl.canAddComment = !!ctrl.workPackage.links.addComment;

    ctrl.isEmpty = function() {
      return ctrl.writeValue === undefined || !ctrl.writeValue.raw;
    };

    ctrl.isEditable = function() {
      return true;
    };

    ctrl.submit = function(notify) {
      if (ctrl.isEmpty()) {
        return;
      }

      ctrl.state.isBusy = true;
      ActivityService.createComment(
        ctrl.workPackage,
        ctrl.writeValue,
        notify
      ).then(function(response) {
        $scope.$emit('workPackageRefreshRequired', '');
        ctrl.discardEditing();
        return response;
      }, function() {
        NotificationsService.addError(I18n.t('js.comment_send_failed'));
        ctrl.state.isBusy = false;
      });
    };

    ctrl.startEditing = function(writeValue) {
      ctrl.isEditing = true;
      ctrl.writeValue = writeValue || { raw: '' };
      ctrl.markActive();

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
      delete ctrl.writeValue;
      ctrl.isEditing = false;
      ctrl.state.isBusy = false;
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
      workPackage: '='
    },
    controller: commentFieldDirectiveController,
    link: function(scope, element, attrs, exclusiveEditController) {
      exclusiveEditController.setCreator(scope.fieldController);

      $timeout(function() {
        AutoCompleteHelper.enableTextareaAutoCompletion(
          angular.element.find('textarea.add-comment-text')
        );
      });
    }
  };
};
