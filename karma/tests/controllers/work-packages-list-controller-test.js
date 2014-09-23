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

describe('WorkPackagesListController', function() {
  var scope, ctrl, win, testParams,
     testProjectService, testWorkPackageService, testQueryService, testPaginationService;
  var testQueries;
  var buildController;

  beforeEach(module('openproject.api', 'openproject.workPackages.controllers', 'openproject.workPackages.services', 'ng-context-menu', 'btford.modal', 'openproject.services'));
  beforeEach(module('templates', function($provide) {
    configurationService = new Object();

    configurationService.isTimezoneSet = sinon.stub().returns(false);

    $provide.constant('ConfigurationService', configurationService);
  }));
  beforeEach(inject(function($rootScope, $controller, $timeout) {
    scope = $rootScope.$new();
    win   = {
     location: { pathname: "" }
    };

    var defaultWorkPackagesData = {
      meta: {
        query: {
          _links: []
        },
        sums: [null]
      },
      work_packages: []
    };
    var workPackagesDataByQueryId = {
      meta: {
        query: {
          props: { id: 1 },
          _links: []
        },
        sums: [null]
      },
      work_packages: []
    };
    var columnData = {
    };
    var availableQueryiesData = {
    };

    var projectData  = { embedded: { types: [] } };
    var projectsData = [ projectData ];
    testQueries = {
      '1': {
        id: 1,
        columns: ['type'],
        getSortation: function() { return null; },
        isNew: function() { return false; }
      },
      '2': {
        id: 2,
        columns: ['type'],
        getSortation: function() { return null; },
        isNew: function() { return false; }
      },
    };

    testProjectService = {
      getProject: function(identifier) {
        return $timeout(function() {
          return projectData;
        }, 10);
      },
      getProjects: function(identifier) {
        return $timeout(function() {
          return projectsData;
        }, 10);
      }
    };

    testWorkPackageService = {
      getWorkPackages: function () {
        return $timeout(function () {
          return defaultWorkPackagesData;
        }, 10);
      },
      getWorkPackagesByQueryId: function (params) {
        return $timeout(function () {
          return workPackagesDataByQueryId;
        }, 10);
      },
      getWorkPackagesFromUrlQueryParams: function () {
        return $timeout(function () {
          return defaultWorkPackagesData;
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
      initQuery: function (id) {
        var queryId = id || 1;
        return testQueries[queryId];
      },
      clearQuery: function() {},
      getAvailableOptions: function() {
        return {};
      },
      loadAvailableColumns: function () {
        return $timeout(function () {
          return columnData;
        }, 10);
      },
      loadAvailableGroupedQueries: function () {
        return $timeout(function () {
          return availableQueryiesData;
        }, 10);
      },

      loadAvailableUnusedColumns: function() {
        return $timeout(function () {
          return columnData;
        }, 10);
      },

      getTotalEntries: function() {
      },

      setTotalEntries: function() {
        return 10;
      },
    };
    testPaginationService = {
      setPerPageOptions: function () {
      },
      setPerPage: function () {
      },
      setPage: function () {
      }
    };
    testAuthorisationService = {
      initModelAuth: function(model, links) {
      }
    }

    buildController = function(params, state, location) {
      scope.projectIdentifier = 'test';

      ctrl = $controller("WorkPackagesListController", {
        $scope:  scope,
        $window: win,
        QueryService:       testQueryService,
        PaginationService:  testPaginationService,
        ProjectService:     testProjectService,
        WorkPackageService: testWorkPackageService,
        $stateParams:       params,
        $state:             state,
        $location:          location,
        latestTab: {}
      });

      $timeout.flush();
    };

  }));

  describe('initialisation of default query', function() {
    beforeEach(function(){
      testParams = {};
      testState = {
        params: {},
        href: function() { return '' }
      };
      testLocation = {
        search: function() {
          return {};
        }
      }

      buildController(testParams, testState, testLocation);
    });

    it('should initialise', function() {
      expect(scope.settingUpPage).to.be.defined;
      expect(scope.operatorsAndLabelsByFilterType).to.be.defined;
      expect(scope.disableFilters).to.eq(false);
      expect(scope.disableNewWorkPackage).to.eq(true);
      expect(scope.query.id).to.eq(testQueries['1'].id);
      expect(scope.showFiltersOptions).to.eq(false);
    });
  });

  describe('initialisation of query by id', function() {
    beforeEach(function(){
      testParams = { };
      testState = {
        params: {
          query_id: testQueries['2'].id
        },
        href: function() { return '' }
      };
      testLocation = {
        search: function() {
          return {};
        }
      }

      buildController(testParams, testState, testLocation);
    });

    it('should initialise', function() {
      expect(scope.query.id).to.eq(testQueries['2'].id);
    });
  });
});
