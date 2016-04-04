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

var expect = chai.expect;

describe('WorkPackagesListController', () => {
  var scope;
  var ctrl;
  var win;
  var wpListServiceMock;
  var testProjectService;
  var testWorkPackageService;
  var testQueryService;
  var testPaginationService;
  var testApiWorkPackages;
  var testAuthorisationService;
  var testQueries;
  var buildController;
  var stateParams = {};

  beforeEach(angular.mock.module('openproject.api', 'openproject.workPackages.controllers',
    'openproject.workPackages.services', 'ng-context-menu', 'btford.modal', 'openproject.layout',
    'openproject.services', 'openproject.wpButtons'));
  beforeEach(angular.mock.module('openproject.templates', ($provide) => {
    var configurationService = {
      isTimezoneSet: sinon.stub().returns(false)
    };

    $provide.constant('$stateParams', stateParams);
    $provide.constant('ConfigurationService', configurationService);
  }));
  beforeEach(angular.mock.inject(($rootScope, $controller, $timeout, $q, $cacheFactory) => {
    scope = $rootScope.$new();
    win = {
      location: {pathname: ''}
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
          props: {id: 1},
          _links: []
        },
        sums: [null]
      },
      work_packages: []
    };
    var columnData = {};
    var availableQueryiesData = {};

    var projectData = {embedded: {types: []}};
    var projectsData = [projectData];
    testQueries = {
      '1': {
        id: 1,
        columns: ['type'],
        getSortation: () => null,
        isNew: () => false
      },
      '2': {
        id: 2,
        columns: ['type'],
        getSortation: () => null,
        isNew: () => false
      }
    };

    testProjectService = {
      getProject: () => {
        return $timeout(() => projectData, 10);
      },
      getProjects: () => {
        return $timeout(() => projectsData, 10);
      }
    };

    var wpCache = $cacheFactory('workPackageCache');
    testWorkPackageService = {
      getWorkPackages: () => {
        return $timeout(() => defaultWorkPackagesData, 10);
      },
      getWorkPackagesByQueryId: () => {
        return $timeout(() => workPackagesDataByQueryId, 10);
      },
      cache() {
        return wpCache;
      }
    };

    testApiWorkPackages = {
      list: () => {
        var deferred = $q.defer();
        deferred.resolve({
          "_type": "Collection",
          "elements": [],
        });
        return deferred.promise;
      }
    };

    testQueryService = {
      getQuery: () => {
        return {
          getQueryString: () => {
          }
        };
      },
      initQuery: (id) => {
        var queryId = id || 1;
        return testQueries[queryId];
      },
      clearQuery: () => {
      },
      loadAvailableColumns: () => {
        return $timeout(() => columnData, 10);
      },
      loadAvailableGroupedQueries: () => {
        return $timeout(() => availableQueryiesData, 10);
      },

      loadAvailableUnusedColumns: () => {
        return $timeout(() => columnData, 10);
      },

      getTotalEntries: () => {
      },

      setTotalEntries: () => 10,
    };
    testPaginationService = {
      setPerPageOptions: () => {
      },
      setPerPage: () => {
      },
      setPage: () => {
      }
    };
    testAuthorisationService = {
      initModelAuth: () => {
      }
    };

    wpListServiceMock = {
      fromQueryParams() {
        return $q.when({
          meta: {
            query: {},
            columns: {},
            export_formats: {}
          },
          resource: {
            total: 10
          },
          work_packages: [
            {}
          ]
        });
      }
    };

    buildController = (params, state, location) => {
      scope.projectIdentifier = 'test';
      ctrl = $controller("WorkPackagesListController", {
        $scope: scope,
        $window: win,
        QueryService: testQueryService,
        PaginationService: testPaginationService,
        ProjectService: testProjectService,
        WorkPackageService: testWorkPackageService,
        apiWorkPackages: testApiWorkPackages,
        $stateParams: params,
        $state: state,
        $location: location,
        wpListService: wpListServiceMock
      });

      $timeout.flush();
    };

  }));

  describe('initialisation of default query', () => {
    var testParams;
    var testState;
    var testLocation;

    beforeEach(() => {
      testParams = {projectPath: '/projects/my-project'};
      testState = {
        params: testParams,
        href: () => ''
      };
      testLocation = {
        search: () => ({}),
        url: angular.identity
      };

      buildController(testParams, testState, testLocation);
    });

    it('should initialise', () => {
      expect(scope.operatorsAndLabelsByFilterType).to.exist;
      expect(scope.disableFilters).to.be.false;
      expect(scope.disableNewWorkPackage).to.be.true;
      expect(scope.query.id).to.eq(testQueries['1'].id);
      expect(scope.showFiltersOptions).to.be.false;
    });

    context('second initialisation', () => {
      beforeEach(() => {
        scope.toggleShowFilterOptions();
        buildController(testParams, testState, testLocation);
      });

      it('should persist the showFiltersOptions value', () => {
        expect(scope.showFiltersOptions).to.be.true;
      });
    });
  });

  describe('initialisation of query by id', () => {
    var testParams;
    var testState;
    var testLocation;

    beforeEach(() => {
      testParams = {projectPath: '/projects/my-project'};
      testState = {
        params: {
          query_id: testQueries['2'].id
        },
        href: () => ''
      };
      testLocation = {
        search: () => ({}),
        url: angular.identity
      };

      buildController(testParams, testState, testLocation);
    });

    it('should initialise', () => {
      expect(scope.query.id).to.eq(testQueries['2'].id);
    });
  });

  describe('getFilterCount', () => {
    beforeEach(() => {
      var testState = {
        params: {
          query_id: testQueries['2'].id
        },
        href: () => ''
      };
      var testLocation = {
        search: () => ({}),
        url: angular.identity
      };

      buildController({projectPath: ''}, testState, testLocation);
    });

    it('returns 0 with no filters', () => {
      expect(scope.getFilterCount()).to.eq(0);
    });

    it('returns the filter count with filters', () => {
      scope.query.filters = [{}, {}];
      expect(scope.getFilterCount()).to.eq(2);
    });

    it('returns the filter count with deactivated filters', () => {
      scope.query.filters = [{}, {deactivated: true}, {deactivated: true}];
      expect(scope.getFilterCount()).to.eq(1);
    });
  });

  describe('setting projectIdentifier', () => {
    var testParams;
    var testState;
    var testLocation;

    beforeEach(() => {
      testParams = {projectPath: 'my-project'};
      testState = {
        href: () => '',
        params: testParams
      };
      testLocation = {
        search: () => ({}),
        url: angular.identity
      };
      buildController(testParams, testState, testLocation);
    });

    it('should set the projectIdentifier', () => {
      expect(scope.projectIdentifier).to.eq('my-project');
    });
  });
});
