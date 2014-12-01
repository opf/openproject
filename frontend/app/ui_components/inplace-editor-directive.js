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

module.exports = function($timeout, InplaceEditorDispatcher) {
  return {
    restrict: 'A',
    transclude: false,
    templateUrl: '/templates/components/inplace_editor.html',
    scope: {
      type: '@inedType',
      entity: '=inedEntity',
      attribute: '@inedAttribute',
      placeholder: '@',
      autocompletePath: '@'
    },
    link: link,
    controller: Controller
  };

  function link(scope, element, attrs) {
    element.on('click', '.ined-read-value', function(e) {
      if (angular.element(e.target).is('a')) {
        return;
      }
      scope.$apply(function() {
        scope.startEditing();
      });
    });
    element.bind('keydown keypress', function(e) {
      if (e.keyCode == 27) {
        scope.$apply(function() {
          scope.discardEditing();
        });
      }
    });
    scope.$on('startEditing', function() {
      $timeout(function() {
        element.find('.ined-input-wrapper-inner .focus-input').focus().triggerHandler('keyup');
        InplaceEditorDispatcher.dispatchHook(scope, 'link', element);
      });
    });

    scope.$on('finishEditing', function() {
      $timeout(function() {
        element.find('.ined-read-value a').focus();
      });
    });
  }

  Controller.$inject = ['$scope', 'WorkPackageService', 'ApiHelper'];
  function Controller($scope, WorkPackageService, ApiHelper) {
    $scope.isEditing = false;
    $scope.isEditable = !!$scope.entity.links.updateImmediately;
    $scope.isBusy = false;
    $scope.readValue = '';
    $scope.editTitle = I18n.t('js.inplace.button_edit');
    $scope.saveTitle = I18n.t('js.inplace.button_save');
    $scope.saveAndSendTitle = I18n.t('js.inplace.button_save_and_send');
    $scope.cancelTitle = I18n.t('js.inplace.button_cancel');
    $scope.error = null;
    $scope.options = [];

    $scope.startEditing = startEditing;
    $scope.discardEditing = discardEditing;
    $scope.submit = submit;
    $scope.onSuccess = onSuccess;
    $scope.onFail = onFail;
    $scope.onFinally = onFinally;

    activate();

    function activate() {
      InplaceEditorDispatcher.dispatchHook($scope, 'activate');
      setWriteValue();
      setReadValue();
    }

    function setWriteValue() {
      InplaceEditorDispatcher.dispatchHook($scope, 'setWriteValue');
    }

    function startEditing() {
      setWriteValue();
      $scope.isEditing = true;
      $scope.error = null;
      $scope.isBusy = false;
      InplaceEditorDispatcher.dispatchHook($scope, 'startEditing');
      $scope.$broadcast('startEditing');
    }

    function submit(withEmail) {
      // angular.copy here to make a new object instead of a reference
      var data = angular.copy($scope.entity.form.embedded.payload.props);
      InplaceEditorDispatcher.dispatchHook($scope, 'submit', data);
      $scope.isBusy = true;
      var result = WorkPackageService.updateWorkPackage($scope.entity, data);
      result.then(function(workPackage) {
        $scope.onSuccess(workPackage);
      });
      result.catch(function(e) {
        $scope.onFail(e);
      });
      result.finally(function() {
        $scope.onFinally();
      });
    }

    function onSuccess(entity) {
      // is it copying the other way around in documentation?
      // https://docs.angularjs.org/api/ng/function/angular.copy
      angular.extend($scope.entity, entity);
      $scope.error = null;
      setReadValue();
      finishEditing();
      $scope.$emit('workPackageRefreshRequired');
    }

    function onFail(e) {
      $scope.error = ApiHelper.getErrorMessage(e);
      InplaceEditorDispatcher.dispatchHook($scope, 'onFail');
    }

    function onFinally() {
      $scope.isBusy = false;
    }

    function discardEditing() {
      finishEditing();
    }

    function finishEditing() {
      $scope.isEditing = false;
      $scope.$broadcast('finishEditing');
    }

    function setReadValue() {
      InplaceEditorDispatcher.dispatchHook($scope, 'setReadValue');
      if ((!$scope.readValue || $scope.readValue.length === 0) && $scope.placeholder) {
        $scope.readValue = $scope.placeholder;
        $scope.placeholderSet = true;
      } else {
        $scope.placeholderSet = false;
      }
    }

  }
};