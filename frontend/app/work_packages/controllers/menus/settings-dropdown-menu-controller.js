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
  $scope, I18n, columnsModal,
  exportModal, saveModal, settingsModal,
  shareModal, sortingModal, groupingModal,
  QueryService, AuthorisationService,
  $window, $state, $timeout) {
  $scope.$watch('query.displaySums', function(newValue) {
    $timeout(function() {
      $scope.displaySumsLabel = (newValue) ? I18n.t('js.toolbar.settings.hide_sums')
                                          : I18n.t('js.toolbar.settings.display_sums');
    });
  });

  $scope.saveQuery = function(event){
    event.stopPropagation();
    if (!$scope.query.isDirty()) {
      return;
    }
    if($scope.query.isNew()) {
      if( allowQueryAction(event, 'create') ){
        emitClosingEvents($scope);
        saveModal.activate();
      }
    } else {
      if( allowQueryAction(event, 'update') ) {
        QueryService.saveQuery()
          .then(function(data){
            $scope.$emit('flashMessage', data.status);
            $state.go('work-packages.list',
                      { 'query_id': $scope.query.id, 'query_props': null },
                      { notify: false });
          });
      }
    }
  };

  $scope.deleteQuery = function(event){
    event.stopPropagation();
    if( allowQueryAction(event, 'delete') && preventNewQueryAction(event) && deleteConfirmed() ){
      QueryService.deleteQuery()
        .then(function(data){
          settingsModal.deactivate();
          $scope.$emit('flashMessage', data.status);
          $state.go('work-packages.list',
                    { 'query_id': null, 'query_props': null },
                    { reload: true });
        });
    }
  };

  // Modals
  $scope.showSaveAsModal = function(event){
    event.stopPropagation();
    if( allowQueryAction(event, 'create') ) {
      showExistingQueryModal.call(saveModal, event);
    }
  };

  $scope.showShareModal = function(event){
    event.stopPropagation();
    if (allowQueryAction(event, 'publicize') || allowQueryAction(event, 'star')) {
      showExistingQueryModal.call(shareModal, event);
    }
  };

  $scope.showSettingsModal = function(event){
    event.stopPropagation();
    if( allowQueryAction(event, 'update') ) {
      showExistingQueryModal.call(settingsModal, event);
    }
  };

  $scope.showExportModal = function(event){
    event.stopPropagation();
    if( allowWorkPackageAction(event, 'export') ) {
      showModal.call(exportModal);
    }
  };

  $scope.showColumnsModal = function(event){
    event.stopPropagation();
    showModal.call(columnsModal);
  };

  $scope.showGroupingModal = function(event){
    event.stopPropagation();
    showModal.call(groupingModal);
  };

  $scope.showSortingModal = function(event){
    event.stopPropagation();
    showModal.call(sortingModal);
  };

  $scope.toggleDisplaySums = function(){
    emitClosingEvents($scope);
    $scope.query.displaySums = !$scope.query.displaySums;

    // This eventually calls the resize event handler defined in the
    // WorkPackagesTable directive and ensures that the sum row at the
    // table footer is properly displayed.
    angular.element($window).trigger('resize');
  };

  $scope.showSettingsModalInvalid = function() {
    return AuthorisationService.cannot('query', 'update');
  };

  $scope.showShareModalInvalid = function() {
    return (AuthorisationService.cannot('query', 'publicize') &&
            AuthorisationService.cannot('query', 'star'));
  };

  $scope.showExportModalInvalid = function() {
    return AuthorisationService.cannot('work_package', 'export');
  };

  $scope.deleteQueryInvalid = function() {
    return AuthorisationService.cannot('query', 'delete');
  };

  $scope.showSaveModalInvalid = function() {
    return $scope.query.isNew() || AuthorisationService.cannot('query', 'create');
  };

  $scope.saveQueryInvalid = function() {
    return (!$scope.query.isDirty()) ||
      (
        $scope.query.isDirty() &&
        !$scope.query.isNew() &&
        AuthorisationService.cannot('query', 'update')
      ) ||
      ($scope.query.isNew() && AuthorisationService.cannot('query', 'create'));
  };

  function preventNewQueryAction(event){
    if (event && $scope.query.isNew()) {
      event.stopPropagation();
      return false;
    }
    return true;
  }

  function showModal() {
    emitClosingEvents($scope);
    this.activate();
  }

  function showExistingQueryModal(event) {
    if( preventNewQueryAction(event) ){
      emitClosingEvents($scope);
      this.activate();
    }
  }

  function allowQueryAction(event, action) {
    return allowAction(event, 'query', action);
  }

  function allowWorkPackageAction(event, action) {
    return allowAction(event, 'work_package', action);
  }

  function allowAction(event, modelName, action) {
    if(AuthorisationService.can(modelName, action)){
      return true;
    } else {
      event.stopPropagation();
      return false;
    }
  }

  function emitClosingEvents($scope) {
    $scope.$emit('hideAllDropdowns');
    $scope.$root.$broadcast('openproject.dropdown.closeDropdowns', true);
  }

  function deleteConfirmed() {
    return $window.confirm(I18n.t('js.text_query_destroy_confirmation'));
  }
};
