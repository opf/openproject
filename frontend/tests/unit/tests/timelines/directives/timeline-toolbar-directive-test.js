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

describe('timelineToolbar Directive', function() {
  var compile, element, scope;

  beforeEach(angular.mock.module('openproject.timelines.directives'));
  beforeEach(module('openproject.templates'));

  beforeEach(inject(function($rootScope, $compile) {
    var html = '<timeline-toolbar timeline="timeline"></timeline-toolbar>';

    element = angular.element(html);
    scope = $rootScope.$new();
    scope.timeline = {
      ZOOM_SCALES:    ['monthly', 'weekly', 'daily'],
      ZOOM_CONFIGURATIONS: { 'monthly': {}, 'weekly': {}, 'daily': {} },
      OUTLINE_LEVELS: ['level1', 'level2', 'level3'],
      expansionIndex: 1,
      zoomIndex:      0,
      zoom:           sinon.spy()
    };

    compile = function() {
      $compile(element)(scope);
      scope.$digest();
    };
  }));

  describe('increase and decrease zoom buttons', function() {
    var zoomInBtn, zoomOutBtn, zoomSelect;

    beforeEach(function() {
      compile();

      zoomInBtn  = element.find('a.icon-zoom-in');
      zoomOutBtn = element.find('a.icon-zoom-out');
      zoomSelect = element.find('select#tl-toolbar-zooms');
    });

    it('tells the timeline to zoom in to its maximum extent', function() {
      zoomInBtn.click();
      zoomInBtn.click();
      zoomInBtn.click();

      expect(scope.timeline.zoom).to.have.been.calledTwice;
      expect(scope.timeline.zoom).to.have.been.calledWith(1);
      expect(scope.timeline.zoom).to.have.been.calledWith(2);
    });

    it('tells the timeline to zoom out to its minimum extent', function() {
      zoomInBtn.click();
      zoomOutBtn.click();
      zoomOutBtn.click();

      expect(scope.timeline.zoom).to.have.been.calledTwice;
      expect(scope.timeline.zoom).to.have.been.calledWith(1);
      expect(scope.timeline.zoom).to.have.been.calledWith(0);
    });

    it('updates the zoom select element on zooming in', function() {
      zoomInBtn.click();
      expect(zoomSelect.val()).to.eq('1');

      zoomInBtn.click();
      expect(zoomSelect.val()).to.eq('2');

      zoomInBtn.click();
      expect(zoomSelect.val()).to.eq('2');
    });

    it('updates the zoom select element on zooming out', function() {
      zoomInBtn.click();
      zoomOutBtn.click();
      expect(zoomSelect.val()).to.eq('0');

      zoomOutBtn.click();
      expect(zoomSelect.val()).to.eq('0');
    });
  });
});
