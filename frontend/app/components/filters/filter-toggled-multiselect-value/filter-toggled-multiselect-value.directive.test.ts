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

import {ToggledMultiselectController} from './filter-toggled-multiselect-value.directive'
import {HalResource} from '../../api/api-v3/hal-resources/hal-resource.service';

describe('toggledMultiselect Directive', function() {
    var compile:any, element:any, rootScope:any, scope:any, I18n:any;
    var controller:ToggledMultiselectController;
    var allowedValues:any;

    beforeEach(angular.mock.module('openproject.filters',
                                   'openproject.templates',
                                   'openproject.services'));

    beforeEach(inject(function($rootScope:any, $compile:any) {
      var html = '<filter-toggled-multiselect-value icon-name="cool-icon.png" filter="filter"></filter-toggled-multiselect-value>';

      element = angular.element(html);
      rootScope = $rootScope;
      scope = $rootScope.$new();

      allowedValues = [
        {
          name: 'New York',
          $href: 'api/new_york'
        },
        {
          name: 'California',
          $href: 'api/california'
        }
      ]

      compile = function() {
        $compile(element)(scope);
        scope.$apply();

        controller = element.controller('filterToggledMultiselectValue');
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
          values: allowedValues,
          currentSchema: {
            values: {
              allowedValues: allowedValues
            }
          }
        };

        compile();
      });

      describe('controller.isValueMulti()', function() {
        it('is true', () => {
          expect(controller.isValueMulti()).to.be.true;
        });
      });

      describe('controller.value', function() {
        it('is no array', function() {
          expect(Array.isArray(controller.value)).to.be.true;
        });

        it('is the filter value', function() {
          let value = controller.value as HalResource[];

          expect(value.length).to.eq(2);
          expect(value[0]).to.eq(allowedValues[0]);
          expect(value[1]).to.eq(allowedValues[1]);
        });
      });

      describe('element', function() {
        it('should render a div', function() {
          expect(element.prop('tagName')).to.equal('DIV');
        });

        it('should render only one select', function() {
          expect(element.find('select').length).to.equal(1);
          expect(element.find('select.ng-hide').length).to.equal(0);
        });

        it('should render two OPTIONs SELECT', function() {
          var select = element.find('select:not(.ng-hide)').first();
          var options = select.find('option');

          expect(options.length).to.equal(2);

          expect(options[0].value).to.equal(allowedValues[0].$href);
          expect(options[0].innerText).to.equal(allowedValues[0].name);

          expect(options[1].value).to.equal(allowedValues[1].$href);
          expect(options[1].innerText).to.equal(allowedValues[1].name);
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

    describe('w/o values and options', function() {
      beforeEach(function() {
        scope.filter = {
          name: "BO' SELECTA",
          values: [],
          currentSchema: {
            values: {
              allowedValues: []
            }
          }
        }

        compile();
      });

      describe('controller.isValueMulti()', function() {
        it('is false', () => {
          expect(controller.isValueMulti()).to.be.false;
        });
      });

      describe('controller.value', function() {
        it('is no array', function() {
          expect(Array.isArray(controller.value)).to.be.false;
        });

        it('is undefined', function() {
          expect(controller.value).to.be.undefined;
        });
      });
    });

    describe('w/o value', function() {
      beforeEach(function() {
        scope.filter = {
          name: "BO' SELECTA",
          values: [],
          currentSchema: {
            values: {
              allowedValues: allowedValues
            }
          }
        }

        compile();
      });

      describe('controller.isValueMulti()', function() {
        it('is false', () => {
          expect(controller.isValueMulti()).to.be.false;
        });
      });

      describe('controller.value', function() {
        it('is no array', function() {
          expect(Array.isArray(controller.value)).to.be.false;
        });

        it('is undefined', function() {
          expect(controller.value).to.be.undefined;
        });
      });

      describe('element', function() {
        it('should render two OPTIONs SELECT + Placeholder', function() {
          var select = element.find('select:not(.ng-hide)').first();
          var options = select.find('option');

          expect(options.length).to.equal(3);
          expect(options[0].innerText).to.equal('PLACEHOLDER');

          expect(options[1].value).to.equal(allowedValues[0].$href);
          expect(options[1].innerText).to.equal(allowedValues[0].name);

          expect(options[2].value).to.equal(allowedValues[1].$href);
          expect(options[2].innerText).to.equal(allowedValues[1].name);
        });
      });
    });
});
