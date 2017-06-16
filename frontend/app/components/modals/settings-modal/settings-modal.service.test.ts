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

import {wpControllersModule} from "../../../angular-modules";
import {input} from "reactivestates";

describe('SettingsModalController', () => {
  var scope:any;
  var settingsModal:any;
  var ctrl:any;
  var buildController:any;
  var wpListService:any;
  var states:any;
  var query:any;

  beforeEach(angular.mock.module(wpControllersModule.name, ($provide:ng.auto.IProvideService) => {
    wpListService = {
      save: (q:any) => {
        return {
          then: (callback:Function) => callback()
        }
      }
    };
    states = {
      query: {
        resource: input<{name: string}>()
      }
    };
    settingsModal = {
      deactivate: () => {}
    };

    $provide.constant('wpListService', wpListService);
    $provide.constant('states', states);
    $provide.constant('settingsModal', settingsModal);
  }));

  beforeEach(angular.mock.inject(function ($rootScope:any, $controller:any) {
    scope = $rootScope.$new();

    query = {
      name: 'bogus'
    };
    states.query.resource.putValue(query);

    buildController = () => {
      ctrl = $controller('SettingsModalController', {
        $scope: scope,
        states,
        settingsModal,
        wpListService
      });
    };
  }));

  describe('scope variables', () => {
    beforeEach(() => {
      buildController();
    });

    it("sets queryName to the query's name", () => {
      expect(scope.queryName).to.eq(query.name);
    })
  });

  describe('when using updateQuery', () => {
    beforeEach(() => {
      scope.queryName = 'bogus2';
      buildController();

      sinon.spy(settingsModal, 'deactivate');
      scope.updateQuery();
      scope.$digest();
    });

    it('should deactivate the open modal', () => {
      expect(settingsModal.deactivate).to.have.been.called;
    });
  });
});
