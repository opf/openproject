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

describe('Routing', function () {
  var $rootScope, $state, mockState = { go: function () {} };

  beforeEach(module('openproject', function ($provide) {
    $provide.value('$state', mockState);
  }));

  beforeEach(inject(function (_$rootScope_) {
    $rootScope = _$rootScope_;
  }));

  describe('when the project id is set', function () {
    var toState, toParams,
        spy = sinon.spy(mockState, 'go'),
        broadcast = function () {
          $rootScope.$broadcast('$stateChangeStart', toState, toParams);
        };

    beforeEach(function () {
      toState = { name: 'work-packages.list' };
      toParams = { projectPath: 'my_project', projects: '' };
    });

    it('sets the projects path segment to "projects" ', function () {
      broadcast();
      expect(toParams.projects).to.equal('projects');
    });

    it('routes to the given state', function () {
      broadcast();
      expect(spy.withArgs(toState, toParams).called).to.be.true;
    });
  });
});
