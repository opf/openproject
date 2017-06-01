//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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

/*jshint expr: true*/

describe('MainMenuController', function() {
  var rootScope, sessionStorage, ctrl;

  beforeEach(angular.mock.module('openproject.layout.controllers'));

  beforeEach(inject(function($rootScope, $controller) {
    rootScope = $rootScope.$new();

    var fakeSession = {};
    sessionStorage = {
      setItem: function(k, v) { fakeSession[k] = v; },
      getItem: function(k)    { return fakeSession[k]; }
    };

    ctrl = $controller("MainMenuController", {
      $rootScope: rootScope,
      $window:    { sessionStorage: sessionStorage }
    });
  }));

  describe('toggleNavigation', function() {
    it('should toggle navigation off', function() {
      rootScope.showNavigation = true;
      ctrl.toggleNavigation();
      expect(rootScope.showNavigation).to.be.false;
    });

    it('should toggle navigation on', function() {
      rootScope.showNavigation = false;
      ctrl.toggleNavigation();
      expect(rootScope.showNavigation).to.be.true;
    });

    it('should fire an event when toggled', function() {
      var callback = sinon.spy();
      rootScope.$on('openproject.layout.navigationToggled', callback);
      ctrl.toggleNavigation();
      expect(callback).to.have.been.calledWithMatch(sinon.match.any, sinon.match.truthy);
    });

    it('should persist choice to sessionStorage', function() {
      expect(sessionStorage.getItem('openproject:navigation-toggle')).to.be.undefined;

      ctrl.toggleNavigation();
      expect(sessionStorage.getItem('openproject:navigation-toggle')).to.equal('expanded');

      ctrl.toggleNavigation();
      expect(sessionStorage.getItem('openproject:navigation-toggle')).to.equal('collapsed');
    });
  });

});
