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

describe('DetailsTabWatchersController', function() {
  var cont, scope, I18n,
    workPackage = {
      schema: {
        props: {
          customField1: {
            type: 'Formattable',
            name: 'color',
            required: false,
            writable: true
          },
          customField2: {
            type: 'Formattable',
            name: 'aut mollitia',
            required: false,
            writable: true
          }
        }
      },
      props: {
        customField1: {
          format: 'plain',
          raw: 'red',
          html: '<p>red</p>'
        },
        customField2: {
          format: 'plain',
          raw: '',
          html: '<p></p>'
        },
        versionName: null,
        percentageDone: 0,
        estimatedTime: 'PT0S',
        spentTime: 'PT0S',
        id: '0815'
      },
      embedded: {
        status: {
          props: {
            name: 'open'
          }
        },
        priority: {
          props: {
            name: 'high'
          }
        },
        activities: [],
        watchers: [{
          avatar: 'http://gravatar.com/avatar/cb4f282fed12016bd18a879c1f27ff97?secure=false',
          createdAt: '2015-01-29T10:31:38+00:00',
          email: 'admin@example.net',
          firstName: 'OpenProject',
          id: 1,
          lastName: 'Admin',
          login: 'admin',
          name: 'OpenProject Admin',
          status: 'active',
          subtype: 'User',
          updatedAt: '2015-04-01T08:21:34+00:00'
        }],
        attachments: []
      },
      links: {}
    };
  beforeEach(module('openproject.api',
    'openproject.services',
    'openproject.config',
    'openproject.workPackages.controllers'));

  beforeEach(inject(function($injector, $controller, $timeout, $rootScope, $filter) {
    scope = $rootScope.$new();
    scope.workPackage = angular.copy(workPackage);
    scope.watchers = angular.copy(workPackage.embedded.watchers);
    scope.outputMessage = function() {};
    I18n = $injector.get('I18n');

    cont = $controller('DetailsTabWatchersController', {
      $scope: scope,
      $filter: $filter,
      $timeout: $timeout,
      I18n: $injector.get('I18n'),
      ADD_WATCHER_SELECT_INDEX: $injector.get('ADD_WATCHER_SELECT_INDEX')
    });
  }));

  describe('addWatcherSuccess', function() {
    it('is not called on initialization', function() {
      sinon.spy(scope, 'outputMessage');
      expect(scope.outputMessage).to.have.not.been.called;
    });
  });
});

/*jshint expr: false*/
