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

describe('toggledMultiselect Directive', function() {
    var compile:any, element:any, rootScope:any, scope:any, I18n:any;

    beforeEach(angular.mock.module('openproject.uiComponents',
                                   'openproject.workPackages.helpers',
                                   'openproject.services'));
    beforeEach(angular.mock.module('openproject.templates', function($provide:any) {
      var configurationService = {
        isTimezoneSet: sinon.stub().returns(false)
      };

      $provide.constant('ConfigurationService', configurationService);
    }));

    beforeEach(inject(function($rootScope:any, $compile:any) {
      var html = '<toggled-multiselect icon-name="cool-icon.png" filter="filter" available-options="options"></toggled-multiselect>';

      element = angular.element(html);
      rootScope = $rootScope;
      scope = $rootScope.$new();

      compile = function() {
        $compile(element)(scope);
        scope.$digest();
      };
    }));

    beforeEach(angular.mock.inject((_I18n_:any) => {
      I18n = _I18n_;
      sinon.stub(I18n, 't').withArgs('js.placeholders.selection').returns('PLACEHOLDER');
    }));
    afterEach(angular.mock.inject(() => {
      I18n.t.restore();
    }));

    describe('with values', function() {
      beforeEach(function() {
        scope.filter = {
          name: "BO' SELECTA",
          values: ['a', 'b', 'c']
        };
        scope.options = [
          ['New York', 'NY'],
          ['California', 'CA']
        ];

        compile();
      });

      describe('element', function() {
        it('should render a span', function() {
          expect(element.prop('tagName')).to.equal('SPAN');
        });

        it('should render only one select', function() {
          expect(element.find('select').length).to.equal(1);
          expect(element.find('select.ng-hide').length).to.equal(0);
        });

        it('should render two OPTIONs + Please select for displayed SELECT', function() {
          var select = element.find('select:not(.ng-hide)').first();
          var options = select.find('option');

          expect(options.length).to.equal(3);
          expect(options[0].innerText).to.equal('PLACEHOLDER');

          expect(options[1].value).to.equal('string:NY');
          expect(options[1].innerText).to.equal('New York');
        });

        xit('should render a link that toggles multi-select', function() {
          var a = element.find('a');
          expect(element.find('select.ng-hide').length).to.equal(1);
          a.click();
          scope.$apply();
          expect(element.find('select.ng-hide').length).to.equal(1);
        });
      });
    });

    describe('w/o values', function() {
      beforeEach(function() {
        scope.filter    = {
          name: "BO' SELECTA"
        }
        scope.options = [
          ['New York', 'NY'],
          ['California', 'CA']
        ];

        compile();

        var multiselectToggleElement = element.find('a');
        multiselectToggleElement.trigger('click');
      });

      describe('scope.values', function() {
        it('should not become an array', function() {
          expect(Array.isArray(scope.values)).to.be.false;
        });

        it('should leave scope.values as undefined', function() {
          expect(scope.values).to.be.undefined;
        });
      });
    });
});
