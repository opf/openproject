// -- copyright
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
// ++

import {wpControllersModule} from '../../../angular-modules';

describe('SettingsModalController', () => {
  var scope;
  var settingsModal;
  var QueryService;
  var NotificationsService;
  var ctrl;
  var buildController;

  beforeEach(angular.mock.module(wpControllersModule.name));
  beforeEach(angular.mock.inject(function ($rootScope, $controller, $q) {
    scope = $rootScope.$new();

    QueryService = {
      getQuery: () => ({name: 'Hey'}),
      saveQuery: () => $q.when({status: {text: 'Query updated!'}}),
      updateHighlightName: angular.noop
    };

    settingsModal = {deactivate: angular.noop};
    NotificationsService = {addSuccess: angular.noop};

    buildController = () => {
      ctrl = $controller('SettingsModalController', {
        $scope: scope,
        settingsModal,
        QueryService,
        NotificationsService
      });
    };
  }));

  describe('when using updateQuery', () => {
    beforeEach(() => {
      buildController();

      sinon.spy(scope, '$emit');
      sinon.spy(settingsModal, 'deactivate');
      sinon.spy(QueryService, 'updateHighlightName');
      sinon.spy(NotificationsService, 'addSuccess');

      scope.updateQuery();
      scope.$digest();
    });

    it('should deactivate the open modal', () => {
      expect(settingsModal.deactivate).to.have.been.called;
    });

    it('should notfify success', () => {
      expect(NotificationsService.addSuccess).to.have.been.calledWith('Query updated!');
    });

    it('should update the query menu name', () => {
      expect(QueryService.updateHighlightName).to.have.been.called;
    });
  });
});
