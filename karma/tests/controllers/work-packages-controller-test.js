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

/*jshint expr: true*/

describe('WorkPackagesController', function() {
  var scope, ctrl, win, testWorkPackageService, testQueryService, testPaginationService;
  var buildController;

  beforeEach(module('openproject.workPackages.controllers', 'openproject.workPackages.services', 'ng-context-menu', 'btford.modal'));
  beforeEach(inject(function($rootScope, $controller, $timeout) {
    scope = $rootScope.$new();
    win   = {
     location: { pathname: "" },
     gon: { project_types: [] }
    };

    var workPackageData = {
      meta: {
      }
    };
    var columnData = {
    };
    var availableQueryiesData = {
    };

    testWorkPackageService = {
      getWorkPackages: function () {
      },
      getWorkPackagesByQueryId: function (params) {
        return $timeout(function () {
          return workPackageData;
        }, 10);
      },
      getWorkPackagesFromUrlQueryParams: function () {
        return $timeout(function () {
          return workPackageData;
        }, 10);
      }
    };
    testQueryService = {
      getQuery: function () {
        return {
          getQueryString: function () {
          }
        };
      },
      initQuery: function () {
      },
      getAvailableColumns: function () {
        return $timeout(function () {
          return columnData;
        }, 10);
      },
      getAvailableGroupedQueries: function () {
        return $timeout(function () {
          return availableQueryiesData;
        }, 10);
      },

      getAvailableUnusedColumns: function() {
        return $timeout(function () {
          return columnData;
        }, 10);
      },

      getTotalEntries: function() {
      },

      setTotalEntries: function() {
        return 10;
      }
    };
    testPaginationService = {
      setPerPageOptions: function () {
      },
      setPerPage: function () {
      },
      setPage: function () {
      }
    };

    buildController = function() {
      ctrl = $controller("WorkPackagesController", {
        $scope:  scope,
        $window: win,
        columnsModal:       {},
        exportModal:        {},
        saveModal:          {},
        settingsModal:      {},
        shareModal:         {},
        sortingModal:       {},
        QueryService:       testQueryService,
        PaginationService:  testPaginationService,
        WorkPackageService: testWorkPackageService
      });

      $timeout.flush();
    };

  }));

  describe('initialisation', function() {
    it('should initialise', function() {
      buildController();
      expect(scope.loading).to.be.false;
    });
  });

  describe('setting projectIdentifier', function() {
    it('should set the projectIdentifier', function() {
      win.location.pathname = '/projects/my-project/something-else';
      buildController();
      expect(scope.projectIdentifier).to.eq('my-project');
    });

    it('should set the projectIdentifier with a custom appBasePath', function() {
      win.appBasePath = '/my-instanz';
      win.location.pathname = '/my-instanz/projects/my-project/something-else';
      buildController();
      expect(scope.projectIdentifier).to.eq('my-project');
    });
  });

});
