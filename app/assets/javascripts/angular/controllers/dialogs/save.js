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

angular.module('openproject.workPackages.controllers')

.factory('saveModal', ['btfModal', function(btfModal) {
  return btfModal({
    controller:   'SaveModalController',
    controllerAs: 'modal',
    templateUrl:  '/templates/work_packages/modals/save.html',
    afterFocusOn: '#work-packages-settings-button'
  });
}])

.controller('SaveModalController', [
  '$scope',
  'saveModal',
  'QueryService',
  'AuthorisationService',
  '$state',
  function($scope, saveModal, QueryService, AuthorisationService, $state) {

  this.name    = 'Save';
  this.closeMe = saveModal.deactivate;

  $scope.saveQueryAs = function(name) {
    QueryService.saveQueryAs(name)
      .then(function(data){
        // push query id to URL without reinitializing work-packages-list-controller
        if (data.query) {
          $state.go('work-packages.list', { query_id: data.query.id, query: null }, { notify: false });
          AuthorisationService.initModelAuth("query", data.query._links);
        }

        saveModal.deactivate();
        $scope.$emit('flashMessage', data.status);
      });
  };
}]);
