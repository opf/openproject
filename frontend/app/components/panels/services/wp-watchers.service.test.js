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


describe('wpWatchers', function() {
  var wpWatchers;

  beforeEach(angular.mock.module('openproject.services'));

  beforeEach(inject(['wpWatchers', function(_wpWatchers_) {
      wpWatchers = _wpWatchers_;
    }]
  ));

  context('for workPackage', function() {

    var availableWatchersPath = '/work_packages/123/available_watchers',
        watchersPath = '/work_packages/123/watchers',
        workPackage = {
          links: {
            watchers: {
              url: function() {
                return watchersPath;
              }
            },
            availableWatchers: {
              url: function() {
                return availableWatchersPath;
              }
            },
            addWatcher: {
              props: {
                href: watchersPath,
                method: 'post'
              }
            },
            removeWatcher: {
              props: {
                href: '/work_packages/123/watchers/{user_id}',
                method: 'delete'
              }
            }
          }
        },
        $httpBackend = null,
        watchers = {
          _embedded: {
            elements: [
              {
                id: 1,
                name: 'Florian'
              },
              {
                id: 2,
                name: 'Breanne'
              }
            ]
          }
        },
        availableWatchers = {
          _embedded: {
            elements: [
              {
                id: 1,
                name: 'Florian'
              },
              {
                id: 2,
                name: 'Breanne'
              },
              {
                id: 3,
                name: 'Supreme OP Overlord'
              },
              {
                id: 4,
                name: 'Ford Prefect'
              }
            ]
          }
        };

    afterEach(function() {
      $httpBackend.verifyNoOutstandingRequest();
      $httpBackend.verifyNoOutstandingExpectation();
    });

    describe('load watchers', function () {

      beforeEach(inject(['$httpBackend', function(_$httpBackend_) {
        $httpBackend = _$httpBackend_;
      }]));


      it('should load both available and watching users', function() {

        $httpBackend.expectGET(watchersPath).respond(watchers);
        $httpBackend.expectGET(availableWatchersPath).respond(availableWatchers);

        wpWatchers.forWorkPackage(workPackage).then(function(users) {
          expect(users).to.have.keys(['available', 'watching']);
          expect(users.watching.length).to.eql(2);
          expect(users.available.length).to.eql(2);

          expect(users.available).to.eql([
            {
              id: 3,
              name: 'Supreme OP Overlord'
            },
            {
              id: 4,
              name: 'Ford Prefect'
            }
          ]);
        });

        $httpBackend.flush();
      });
    });

    describe('adding watchers', function() {

      beforeEach(inject(['$httpBackend', function(_$httpBackend_) {
        $httpBackend = _$httpBackend_;
      }]));

      it('should be possible to add watchers', function() {
        $httpBackend.expectPOST(watchersPath).respond({});

        var watcher = {
          id: 3,
          _links: {
            self: '/users/123'
          }
        };

        wpWatchers.addForWorkPackage(workPackage, watcher);
        $httpBackend.flush();
      });
    });

    describe('removing watchers', function() {

      beforeEach(inject(['$httpBackend', function(_$httpBackend_) {
        $httpBackend = _$httpBackend_;
      }]));

      it('should be possible to delete watchers', function() {
        $httpBackend.expectDELETE('/work_packages/123/watchers/9').respond({});

        var watcher = {
          id: 9
        };

        wpWatchers.removeFromWorkPackage(workPackage, watcher);
        $httpBackend.flush();
      });
    });
  });
});
