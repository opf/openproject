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

describe('MessagesController', function() {
  var scope, buildController, ctrl, testPaginationService;

  beforeEach(angular.mock.module('openproject.messages.controllers', 'openproject.api', 'openproject.services'));

  beforeEach(inject(function($rootScope, $controller) {
    scope = $rootScope.$new();
    window.gon = {
      sort_direction: 'asc',
      settings: {
        pagination: {
          per_page_options: [4, 8, 15, 16, 23, 42]
        }
      }
    };

    testPaginationService = {
      per_page_options: [],
      setPerPageOptions: function(ppo) { testPaginationService.per_page_options = ppo; },
      getPerPageOptions: function(ppo) { return testPaginationService.per_page_options; }
    };

    buildController = function() {
      ctrl = $controller('MessagesController', {
        $scope:  scope,
        $state: {},
        $stateParams: {},
        PaginationService: testPaginationService
      });
    };
  }));

  afterEach(function() {
    window.gon = {};
  });

  describe('pagination settings', function() {
    it('should set the per_page_options', function() {
      buildController();
      expect(testPaginationService.getPerPageOptions()).to.eql([4, 8, 15, 16, 23, 42]);
    });
  });

});
