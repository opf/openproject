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

describe('timelineColumnData Directive', function() {
  var compile, element, rootScope, scope;

  beforeEach(angular.mock.module('openproject.timelines.directives'));
  beforeEach(module('templates', 'openproject.uiComponents', 'openproject.helpers'));

  beforeEach(inject(function($rootScope, $compile) {
    var html;
    html = '<span timeline-column-data row-object="rowObject" column-name="columnName" timeline="timeline" custom-fields="timeline.custom_fields"></span>';

    element = angular.element(html);
    rootScope = $rootScope;
    scope = $rootScope.$new();

    compile = function() {
      $compile(element)(scope);
      scope.$digest();
    };
  }));

  describe('element', function() {
    beforeEach(function() {
      type = Factory.build('PlanningElementType');

      scope.timeline = Factory.build('Timeline');
      scope.rowObject = Factory.build("PlanningElement", {
        timeline: scope.timeline,
        planning_element_type: type,
        sheep: 10,
        start_date: '2014-04-29',
        due_date: '2014-04-28'
      });
    });

    describe('rendering an object field', function() {
      beforeEach(function(){
        scope.columnName = 'type';
        compile();
      });

      it('should render object data', function() {
        expect(element.find('.tl-column').text()).to.equal(type.name);
      });
    });

    describe('rendering historical data', function() {
      beforeEach(function() {
        historicalStartDate = '2014-04-20';

        scope.rowObject.historical_element =  Factory.build("PlanningElement", {
          start_date: historicalStartDate
        });

        scope.columnName = 'start_date';
        compile();
      })

      it('should render the historical data', function() {
        var historicalContent = element.find('.tl-historical a').text();
        expect(historicalContent).to.equal(historicalStartDate);
      })

      it('should assign a historical date kind class to the data container', function() {
        var container = element.find('.tl-column');
        expect(container.hasClass('tl-preponed')).to.be.true;
      });
    });
  });
});
