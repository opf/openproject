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

describe('TimelineSelectionController', function() {
  var ctrl, scope, win;

  beforeEach(module('openproject.timelines.controllers'));

  beforeEach(inject(function($rootScope, $controller) {
    scope = $rootScope.$new();

    win = { location: { href: '/projects/easy_project/timelines/4' } };

    /*jshint camelcase: false */
    window.gon = {
      timelines: [
        { id: 1, name: 'simple',  path: '/projects/easy_project/timelines/1' },
        { id: 2, name: 'complex', path: '/projects/easy_project/timelines/2' }
      ],
      current_timeline_id: 2
    };
    /*jshint camelcase: true */

    ctrl = $controller('TimelineSelectionController', {
      $window: win,
      $scope: scope
    });
  }));

  afterEach(function() {
    window.gon = {};
  });

  describe('initialisation', function() {
    it('sets timelines', function() {
      expect(scope.vm.timelines.length).to.eql(2);
      expect(scope.vm.timelines).to.eql(window.gon.timelines);
    });

    it('sets currentTimeline', function() {
      expect(scope.vm.currentTimeline.id).to.equal(2);
      expect(scope.vm.currentTimeline.name).to.equal('complex');
    });

    it('forwards to the currentTimeline path', function() {
      expect(win.location.href).to.equal('/projects/easy_project/timelines/4');
      scope.vm.switchTimeline();
      expect(win.location.href).to.equal('/projects/easy_project/timelines/2');
    });
  });
});
