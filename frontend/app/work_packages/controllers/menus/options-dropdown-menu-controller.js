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

module.exports = function($scope, I18n, columnsModal, exportModal, saveModal, settingsModal, shareModal, sortingModal, groupingModal, QueryService, AuthorisationService, $window, $state, $timeout){
  // angular.element($window).bind('click', function() {
  // $scope.$emit('hideAllDropdowns');
  // });

  $scope.$watch('query.displaySums', function(newValue, oldValue) {
    $timeout(function() {
      $scope.displaySumsLabel = (newValue) ? I18n.t('js.toolbar.settings.hide_sums')
                                          : I18n.t('js.toolbar.settings.display_sums');
    });
  });

  $scope.saveQuery = function(event){
    if (!$scope.query.dirty) {
      return;
    }
    if($scope.query.isNew()){
      if( allowQueryAction(event, 'create') ){
        // $scope.$emit('hideAllDropdowns');
        saveModal.activate();
      }
    } else {
      if( allowQueryAction(event, 'update') ) {
        QueryService.saveQuery()
          .then(function(data){
            $scope.$emit('flashMessage', data.status);
            $state.go('work-packages.list',
                      { query_id: $scope.query.id, query_props: null },
                      { notify: false });
          });
      }
    }
  };

  $scope.deleteQuery = function(event){
    if( allowQueryAction(event, 'delete') && preventNewQueryAction(event) && deleteConfirmed() ){
      QueryService.deleteQuery()
        .then(function(data){
          settingsModal.deactivate();
          $scope.$emit('flashMessage', data.status);
          $state.go('work-packages.list',
                    { query_id: null, query_props: null },
                    { reload: true });
        });
    }
  };

  // Modals
  $scope.showSaveAsModal = function(event){
    if( allowQueryAction(event, 'create') ) {
      showExistingQueryModal.call(saveModal, event);
    }
  };

  $scope.showShareModal = function(event){
    if (allowQueryAction(event, 'publicize') || allowQueryAction(event, 'star')) {
      showExistingQueryModal.call(shareModal, event);
    }
  };

  $scope.showSettingsModal = function(event){
    if( allowQueryAction(event, 'update') ) {
      showExistingQueryModal.call(settingsModal, event);
    }
  };

  $scope.showExportModal = function(event){
    if( allowWorkPackageAction(event, 'export') ) {
      showModal.call(exportModal);
    }
  };

  $scope.showColumnsModal = function(){
    showModal.call(columnsModal);
  };

  $scope.showGroupingModal = function(){
    showModal.call(groupingModal);
  };

  $scope.showSortingModal = function(){
    showModal.call(sortingModal);
  };

  $scope.toggleDisplaySums = function(){
    // $scope.$emit('hideAllDropdowns');
    $scope.query.displaySums = !$scope.query.displaySums;

    // This eventually calls the resize event handler defined in the
    // WorkPackagesTable directive and ensures that the sum row at the
    // table footer is properly displayed.
    angular.element($window).trigger('resize');
  };

  function preventNewQueryAction(event){
    if (event && $scope.query.isNew()) {
      event.preventDefault();
      event.stopPropagation();
      return false;
    }
    return true;
  }

  function showModal() {
    // $scope.$emit('hideAllDropdowns');
    this.activate();
  }

  function showExistingQueryModal(event) {
    if( preventNewQueryAction(event) ){
      // $scope.$emit('hideAllDropdowns');
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
      event.preventDefault();
      event.stopPropagation();
      return false;
    }
  }

  function deleteConfirmed() {
    return $window.confirm(I18n.t('js.text_query_destroy_confirmation'));
  }
};
