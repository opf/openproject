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

describe('transformDateUtc Directive', function() {
  var compile, element, rootScope, scope, ConfigurationService, isTimezoneSetStub, timezoneStub;

  var prepare = function () {

    angular.mock.module('openproject');

    inject(function($rootScope, $compile, _ConfigurationService_) {
      var html =
        '<input type="text" ng-model="dateValue" transform-date-utc />';

      ConfigurationService = _ConfigurationService_;
      isTimezoneSetStub = sinon.stub(ConfigurationService, 'isTimezoneSet');
      isTimezoneSetStub.returns(true);
      timezoneStub = sinon.stub(ConfigurationService, 'timezone');

      element = angular.element(html);
      rootScope = $rootScope;
      scope = $rootScope.$new();
      scope.dateValue = null;

      compile = function () {
        $compile(element)(scope);
        scope.$digest();
      };
    });
  };

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

  var shouldBehaveCorrectlyWhenGivenInvalidDateValues = function () {
    describe('when given invalid date values', function () {
      shouldBehaveLikeAParser(null, null);
      shouldBehaveLikeAParser('invalid', '');
      shouldBehaveLikeAParser('2016-12', '');
      shouldBehaveLikeAFormatter('', '');
      shouldBehaveLikeAFormatter('invalid', '');
      shouldBehaveLikeAFormatter('2016-12', '');
    });
  };

  context('when having UTC configured', function () {
    beforeEach(function () {
      prepare();
      timezoneStub.returns('UTC');
    });

    describe('when given valid date values', function() {
      var value = '2016-12-01';
      var expectedValue = value + 'T00:00:00Z';
      shouldBehaveLikeAParser(value, expectedValue);
      shouldBehaveLikeAFormatter(expectedValue, value);
    });

    shouldBehaveCorrectlyWhenGivenInvalidDateValues();
  });

  context('when having GMT+1 zone configured', function () {
    beforeEach(function () {
      prepare();
      // moment-timezone: GMT+1 is actually GMT-1
      timezoneStub.returns('Etc/GMT+1');
    });

    describe('it has the time adjusted', function () {
      var value = '2016-12-03T00:00:00Z';
      var expectedValue = '2016-12-02';
      shouldBehaveLikeAFormatter(value, expectedValue);
    });
  });

  context('when having GMT-1 zone configured', function () {
    beforeEach(function () {
      prepare();
      // moment-timezone: GMT-1 is actually GMT+1
      timezoneStub.returns('Etc/GMT-1');
    });

    describe('it has the time adjusted', function () {
      var value = '2016-12-01';
      var expectedValue = '2016-11-30T23:00:00Z';
      shouldBehaveLikeAParser(value, expectedValue);
    });
  });
});
