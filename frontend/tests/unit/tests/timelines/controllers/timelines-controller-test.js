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

var gon = { timeline_options: { } };

describe('TimelinesController', function() {
  var ctrl, scope;
  var timelineOptions = {
    1: { id: 1 },
    2: { id: 2 }
  };

  beforeEach(module('openproject.timelines.controllers'));

  beforeEach(inject(function($rootScope, $controller) {
    scope = $rootScope.$new();

    gon = { timeline_options: timelineOptions };

    ctrl = $controller("TimelinesController", {
      $scope: scope
    });
  }));

  describe('initialisation', function() {
    beforeEach(function() {
      scope.init(2);
    });

    it('sets correct timeline', function() {
      expect(scope.timeline.id).to.eql(2);
    });
  });
});
