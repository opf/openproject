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

angular.module('openproject.workPackages.directives')

.directive('optionsDropdown', ['I18n',
  'columnsModal',
  'exportModal',
  'saveModal',
  'settingsModal',
  'shareModal',
  'sortingModal',
  'groupingModal',
  'QueryService',
  '$window',
  '$state',
  function(I18n, columnsModal, exportModal, saveModal, settingsModal, shareModal, sortingModal, groupingModal, QueryService, $window, $state){

  return {
    restrict: 'AE',
    scope: true,
    link: function(scope, element, attributes) {
      angular.element($window).bind('click', function() {
        scope.$emit('hideAllDropdowns');
      });

      scope.saveQuery = function(){
        if(scope.query.isNew()){
          scope.$emit('hideAllDropdowns');
          saveModal.activate();
        } else {
          QueryService.saveQuery()
            .then(function(data){
              scope.$emit('flashMessage', data.status);
            });
        }
      };

      scope.deleteQuery = function(event){
        if( preventDisabledAction(event) && deleteConfirmed() ){
          QueryService.deleteQuery()
            .then(function(data){
              settingsModal.deactivate();
              scope.$emit('flashMessage', data.status);
              $state.go('work-packages.list', { query_id: null }, { reload: true });
            });
        }
      };

      // Modals
      scope.showSaveAsModal = function(event){
        showExistingQueryModal.call(saveModal, event);
      };

      scope.showShareModal = function(event){
        showExistingQueryModal.call(shareModal, event);
      }

      scope.showSettingsModal = function(event){
        showExistingQueryModal.call(settingsModal, event);
      };

      scope.showExportModal = function(){
        showModal.call(exportModal);
      };

      scope.showColumnsModal = function(){
        showModal.call(columnsModal);
      };

      scope.showGroupingModal = function(){
        showModal.call(groupingModal);
      };

      scope.showSortingModal = function(){
        showModal.call(sortingModal);
      };

      scope.toggleDisplaySums = function(){
        scope.$emit('hideAllDropdowns');
        scope.query.displaySums = !scope.query.displaySums;
      };

      function preventDisabledAction(event){
        if (event && scope.query.isNew()) {
          event.preventDefault();
          event.stopPropagation();
          return false;
        }
        return true;
      }

      function showModal() {
        scope.$emit('hideAllDropdowns');
        this.activate();
      }

      function showExistingQueryModal(event) {
        if( preventDisabledAction(event) ){
          scope.$emit('hideAllDropdowns');
          this.activate();
        }
      }

      function deleteConfirmed() {
        return $window.confirm(I18n.t('js.text_query_destroy_confirmation'));
      }
    }
  };
}]);
