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

describe('progressBar Directive', function() {
    var compile, element, rootScope, scope;

    beforeEach(angular.mock.module('openproject.uiComponents'));
    beforeEach(module('openproject.templates'));

    beforeEach(inject(function($rootScope, $compile) {
      var html;
      html = '<progress-bar progress="progress" width="10" legend="State of things"></progress-bar>';

      element = angular.element(html);
      rootScope = $rootScope;
      scope = $rootScope.$new();
      scope.progress = 50;

      compile = function() {
        $compile(element)(scope);
        scope.$digest();
      };
    }));

    describe('element', function() {
      beforeEach(function() {
        compile();
      });

      it('should render a span', function() {
        expect(element.prop('tagName')).to.equal('SPAN');
      });

      it('should have a legend attribute', function() {
        expect(element.attr('legend').trim()).to.equal('State of things');
      });

      it('should have an inner span with appropriate width', function() {
        var span = element.find('.inner-progress.closed');
        expect(span.css('width')).to.equal('50%');
      });

      describe('when the progress is updated within the scope', function() {
        beforeEach(function() {
          scope.progress = '20';
          scope.$apply();
        });

        it('should update the progress bar', function() {
          var cell = element.find('.inner-progress.closed');
          expect(cell.css('width')).to.equal('20%');
        });
      });
    });
});
