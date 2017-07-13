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

import {
  opApiModule, opServicesModule, openprojectModule,
  wpControllersModule, wpServicesModule
} from "../../../angular-modules";

describe('WorkPackageDetailsController', () => {
  var scope:any;
  var promise:any;
  var buildController:any;
  var ctrl:any;
  var I18n:any = {t: angular.identity};

  var workPackage:any = {
      props: {},
      embedded: {
        author: {
          props: {
            id: 1,
            status: 'active'
          }
        },
        id: 99,
        project: {
          props: {
            id: 1
          }
        },
        activities: {
          links: {
            self: {href: "/api/v3/work_packages/820/activities"}
          },
          _type: "Collection",
          total: 0,
          count: 0,
          embedded: {
            elements: []
          }
        },
        watchers: [],
        attachments: {
          links: {
            self: {href: "/api/v3/work_packages/820/attachments"}
          },
          _type: "Collection",
          total: 0,
          count: 0,
          embedded: {
            elements: []
          }
        },
        type: {
          props: {
            name: 'Milestone'
          }
        },
        relations: [
          {
            props: {
              _type: "Relation::Relates"
            },
            links: {
              relatedFrom: {
                fetch: sinon.spy()
              },
              relatedTo: {
                fetch: sinon.spy()
              }
            }
          }
        ]
      },
      links: {
        self: {href: "it's a me, it's... you know..."},
        availableWatchers: {
          fetch: () => {
            return {then: angular.noop};
          }
        },
        schema: {
          fetch: () => {
            return {then: angular.noop};
          }
        }
      },
      link: {
        addWatcher: {
          fetch: () => {
            return {then: angular.noop};
          }
        }
      }
    };

  beforeEach(angular.mock.module(openprojectModule.name, opApiModule.name, 'openproject.layout',
    wpControllersModule.name, wpServicesModule.name, opServicesModule.name));

  beforeEach(angular.mock.module('openproject.templates', function ($provide:any) {
    $provide.constant('ConfigurationService', {
      isTimezoneSet: sinon.stub().returns(false),
      warnOnLeavingUnsaved: sinon.stub().returns(false)
    });
  }));

  beforeEach(angular.mock.inject(($rootScope:any,
                                  $controller:any,
                                  $injector:ng.auto.IInjectorService,
                                  $state:any,
                                  $q:any,
                                  $httpBackend:any,
                                  WorkPackageService:any) => {
    $httpBackend.when('GET', '/api/v3/work_packages/99').respond(workPackage);

    (window as any).ngInjector = $injector;

    WorkPackageService.getWorkPackage = () => {
      return $q.when(workPackage)
    };

    buildController = () => {
      var testState = {
        params: {workPackageId: 99},
        includes: sinon.stub().returns(true),
        go: sinon.stub(),
        current: {url: '/activity'}
      };
      scope = $rootScope.$new();

      ctrl = $controller("WorkPackageDetailsController", {
        $scope: scope,
        $state: testState,
        I18n: I18n,
        ConfigurationService: {
          commentsSortedInDescendingOrder: () => {
            return false;
          }
        },
        workPackage: workPackage,
      });

      promise = ctrl.initialized.promise;
    };
  }));

  describe('initialisation', () => {
    it('should initialise', () => {
      return buildController();
    });
  });

  describe('#scope.canViewWorkPackageWatchers', () => {
    describe('when the work package does not contain the embedded watchers property', () => {
      beforeEach(() => {
        workPackage.embedded.watchers = undefined;
        buildController();
      });

      it('returns false', () => {
        expect(promise).to.eventually.be.fulfilled.then(() => {
          expect(scope.canViewWorkPackageWatchers()).to.be.false;
        });
      });
    });

    describe('when the work package contains the embedded watchers property', () => {
      beforeEach(() => {
        workPackage.embedded.watchers = [];
        return buildController();
      });

      it('returns true', () => {
        expect(promise).to.eventually.be.fulfilled.then(() => {
          expect(scope.canViewWorkPackageWatchers()).to.be.true;
        });
      });
    });
  });

  describe('work package properties', () => {
    describe('relations', () => {
      beforeEach(() => {
        return buildController();
      });

      it('Relation::Relates', () => {
        expect(promise).to.eventually.be.fulfilled.then(() => {
          expect(scope.relatedTo).to.be.ok;
        });
      });

      it('is the embedded type', () => {
        expect(promise).to.eventually.be.fulfilled.then(() => {
          expect(scope.type.props.name).to.eql('Milestone');
        });
      });
    });
  });

  describe('showStaticPagePath', () => {
    it('points to old show page', () => {
      expect(promise).to.eventually.be.fulfilled.then(() => {
        expect(scope.showStaticPagePath).to.eql('/work_packages/99');
      });
    });
  });
});
