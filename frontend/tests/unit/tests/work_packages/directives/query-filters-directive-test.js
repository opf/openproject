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

describe('queryFilters', function() {
  var doc, $httpBackend, $timeout, compile, scope, element;
  var html = "<query-filters></query-filters>";

  beforeEach(module('ui.router',
                    'openproject.api',
                    'openproject.models',
                    'openproject.layout',
                    'openproject.workPackages.directives',
                    'openproject.workPackages.filters'));

  beforeEach(module('openproject.templates', function($provide) {
    $provide.constant('ConfigurationService', new Object());
  }));

  beforeEach(inject(function($rootScope, $compile, $document, _$httpBackend_, _$timeout_, PathHelper) {
    $httpBackend = _$httpBackend_;
    $timeout = _$timeout_;

    doc = $document[0];
    scope = $rootScope.$new();

    compile = function() {
      element = $compile(html)(scope);
      scope.$digest();

      var body = angular.element(doc.body);
      body.append(element);

      $timeout.flush();
    };

    var path = PathHelper.apiCustomFieldsPath();
    var customFieldFilters = { custom_field_filters: {} };
    $httpBackend.when('GET', path).respond(200, customFieldFilters);
  }));

  afterEach(function() {
    var body = angular.element(doc.body);

    body.find('#filters').remove();
  });


  describe('accessibility', function() {
    describe('focus', function() {
      // I used filters that are not of type 'list_model' or 'list_optional' to
      // prevent additional mocking of WorkPackageLoadingHelper.
      var filter1 = Factory.build('Filter', { name: 'subject' });
      var filter2 = Factory.build('Filter', { name: 'start_date' });
      var filter3 = Factory.build('Filter', { name: 'done_ratio' });

      var enterEvent = jQuery.Event('keydown', { which: 13 });

      var removeFilter = function(filterName) {
        var removeLinkElement = angular.element(element).find('#tr_' + filterName + ' td:last-of-type a');

        angular.element(removeLinkElement[0]).trigger(enterEvent);

        $timeout.flush();
      };

      beforeEach(function() {
        scope.query = Factory.build('Query', { filters: [] });

        scope.query.setFilters([filter1, filter2, filter3]);

        compile();
      });

      describe('Remove first filter', function() {
        beforeEach(function() {
          removeFilter(filter1.name);
        });

        it('focus is set to second filter', function() {
          var el = angular.element(element).find('td select#operators-' + filter2.name);

          expect(doc.activeElement).to.equal(el[0]);
        });
      });

      describe('Remove second filter', function() {
        beforeEach(function() {
          removeFilter(filter2.name);
        });

        it('focus is set to third filter', function() {
          var el = angular.element(element).find('td select#operators-' + filter3.name);

          expect(doc.activeElement).to.equal(el[0]);
        });
      });

      describe('Remove last filter', function() {
        beforeEach(function() {
          removeFilter(filter3.name);
        });

        it('focus is set to filter next to last', function() {
          var el = angular.element(element).find('td select#operators-' + filter2.name);

          expect(doc.activeElement).to.equal(el[0]);
        });
      });

      describe('Remove all filter', function() {
        beforeEach(function() {
          removeFilter(filter1.name);
          removeFilter(filter2.name);
          removeFilter(filter3.name);
        });

        it('focus is set to filter next to last', function() {
          var el = angular.element(element).find('td.add-filter select#add_filter_select');

          expect(doc.activeElement).to.equal(el[0]);
        });
      });
    });
  });
});
