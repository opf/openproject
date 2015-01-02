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

/*jshint expr: true*/

describe('WorkPackagesController', function() {
  var scope, win, ctrl, testParams, buildController, stateParams = {};

  beforeEach(module('openproject.workPackages.controllers', 'openproject.api', 'openproject.layout','openproject.services'));
  beforeEach(module('openproject.templates', function($provide) {
    var configurationService = {};

    configurationService.isTimezoneSet = sinon.stub().returns(false);

    $provide.constant('$stateParams', stateParams);
    $provide.constant('ConfigurationService', configurationService);
  }));
  beforeEach(inject(function($rootScope, $controller, $timeout) {
    scope = $rootScope.$new();
  }));

  beforeEach(inject(function($rootScope, $controller) {
    scope = $rootScope.$new();
    win   = {
     location: { pathname: "" }
    };
    testParams = { projectIdentifier: 'anything' };

    buildController = function() {
      ctrl = $controller("WorkPackagesController", {
        $scope:  scope,
        $window: win,
        $state: {},
        $stateParams: testParams,
        project: {},
        availableTypes: {}
      });
    };
  }));

  describe('setting projectIdentifier', function() {
    beforeEach(function() {
      testParams = { projectPath: '/projects/my-project' };
    });

    it('should set the projectIdentifier', function() {
      buildController();
      expect(scope.projectIdentifier).to.eq('my-project');
    });
  });

});
