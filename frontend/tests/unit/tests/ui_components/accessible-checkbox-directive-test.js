//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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

describe('accessibleCheckbox Directive', function() {
    var compile, element, rootScope, scope;

    beforeEach(angular.mock.module('openproject.uiComponents'));
    beforeEach(angular.mock.module('openproject.templates'));

    beforeEach(inject(function($rootScope, $compile) {
      var html;
      html = '<accessible-checkbox name="check-it-out" checkbox-id="check-it-out" checkbox-title="{{ title }}" ' +
        'checkbox-value="simpleValue" model="carModel"></accessible-checkbox>';

      element = angular.element(html);
      rootScope = $rootScope;
      scope = $rootScope.$new();
      scope.simpleValue = 'BAR';
      scope.carModel = {
        nice: 'people'
      };

      compile = function() {
        $compile(element)(scope);
        scope.$digest();
      };
    }));

    describe('element', function() {
      beforeEach(function() {
        compile();
      });

      it('should render a surrounding span', function() {
        expect(element.prop('tagName')).to.equal('SPAN');
      });

      it('should render a label', function() {
        var label = element.find('label');

        expect(label.length).to.equal(1);
        expect(label.text()).to.equal('');

        scope.title = 'New Label';
        scope.$apply();
        expect(label.text()).to.equal('New Label');
      });

      it('should render a checkbox', function() {
        var input = element.find('input');

        expect(input.length).to.equal(1);
        expect(input.attr('name')).to.equal('check-it-out');
        expect(input.val()).to.equal('BAR');
      });
    });
});
