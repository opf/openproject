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

describe('transformDateValue Directive', function() {
  var compile, element, rootScope, scope;

  var shouldBehaveLikeAParser = function (value, expected) {
    it('these should parse as expected', function () {
      compile();
      element.val(value);
      element.trigger('input');
      expect(scope.dateValue).to.eql(expected);
    });
  };

  var shouldBehaveLikeAFormatter = function (value, expected) {
    it('should format the value as expected', function () {
      scope.dateValue = value;
      compile();
      expect(element.val()).to.eql(expected);
    });
  }

  beforeEach(angular.mock.module('openproject'));

  beforeEach(inject(function($rootScope, $compile) {
    var html =
      '<input type="text" ng-model="dateValue" transform-date-value/>';

    element = angular.element(html);
    rootScope = $rootScope;
    scope = $rootScope.$new();
    scope.dateValue = null;

    compile = function() {
      $compile(element)(scope);
      scope.$digest();
    };
  }));

  describe('when given valid date values', function() {
    var dateValue = '2016-12-01';
    shouldBehaveLikeAParser(dateValue, dateValue);
    shouldBehaveLikeAFormatter(dateValue, dateValue);
  });

  describe('when given invalid date values', function () {
    shouldBehaveLikeAParser('', null);
    shouldBehaveLikeAParser('invalid', null);
    shouldBehaveLikeAParser('2016-12', null);
    shouldBehaveLikeAFormatter(undefined, '');
    shouldBehaveLikeAFormatter(null, '');
    shouldBehaveLikeAFormatter('2016-12', '');
  });
});
